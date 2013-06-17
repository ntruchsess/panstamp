###########################################################
# SWAP server class
###########################################################
package Device::PanStamp::swap::SwapServer;

use strict;
use warnings;

use threads;
use threads::shared;
use Thread::Queue;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Device::PanStamp::swap::modem::SerialModem;
use Device::PanStamp::swap::protocol::SwapRegister;
use Device::PanStamp::swap::protocol::SwapDefs;
use Device::PanStamp::swap::protocol::SwapPacket;
use Device::PanStamp::swap::protocol::SwapMote;
use Device::PanStamp::swap::protocol::SwapNetwork;
use Device::PanStamp::swap::protocol::SwapValue;
use Device::PanStamp::swap::protocol::SmartEncrypt;
use Device::PanStamp::swap::xmltools::XmlSettings;
use Device::PanStamp::swap::xmltools::XmlSerial;
use Device::PanStamp::swap::xmltools::XmlNetwork;

use Time::HiRes qw(time);
use LWP::Simple qw(get);
use Archive::Tar;

use constant {

  # Maximum waiting time (in ms) for ACK's
  _MAX_WAITTIME_ACK => 2000,

  # Max tries for any SWAP command
  _MAX_SWAP_COMMAND_TRIES => 3,

  # Max time to poll regular registers (seconds)
  _MAX_POLL_VALUES_TIME => 20.0
};

###########################################################
# sub _run
#
# Start SWAP server thread
###########################################################

sub _run() {
  my $self = shift;

  # Network configuration settings
  $self->{_xmlnetwork} = Device::PanStamp::swap::xmltools::XmlNetwork->new(
    $self->{_xmlSettings}->{network_file} );
  $self->{devaddress} = $self->{_xmlnetwork}->{devaddress};
  $self->{security}   = $self->{_xmlnetwork}->{security};
  $self->{password}   = Device::PanStamp::swap::protocol::Password->new(
    $self->{_xmlnetwork}->{password} );

  # Serial configuration settings
  $self->{_xmlserial} = Device::PanStamp::swap::xmltools::XmlSerial->new(
    $self->{_xmlSettings}->{serial_file} );

  # Create and start serial modem object
  $self->{modem} = Device::PanStamp::swap::modem::SerialModem->new(
    $self->{_xmlserial}->{port}, $self->{_xmlserial}->{speed},
    $self->{verbose},            $self->{_xmlserial}->{async}
  );

  # Declare receiving callback function
  if ( $self->{async} ) {
    $self->{modem}->setRxCallback( sub { $self->_ccPacketReceived(@_); } );
  } else {
    my $rcvqueue = Thread::Queue->new();
    $self->{_rcvqueue} = $rcvqueue;
    $self->{modem}->setRxCallback( sub { $rcvqueue->enqueue(shift); } );
  }

  $self->{modem}->start();

  # Set modem configuration from _xmlnetwork
  my $param_changed = 0;

  # Device address
  if ( defined $self->{_xmlnetwork}->{devaddress}
    and $self->{modem}->{devaddress} ne $self->{_xmlnetwork}->{devaddress} )
  {
    die "Unable to set modem's device address to "
      . $self->{_xmlnetwork}->{devaddress}
      unless (
      $self->{modem}->setDevAddress( $self->{_xmlnetwork}->{devaddress} ) );
    $param_changed = 1;
  }

  # Device address
  if ( defined $self->{_xmlnetwork}->{network_id}
    and $self->{modem}->{syncword} ne $self->{_xmlnetwork}->{network_id} )
  {
    die "Unable to set modem's network ID to "
      . $self->{_xmlnetwork}->{network_id}
      unless (
      $self->{modem}->setSyncWord( $self->{_xmlnetwork}->{network_id} ) );
    $param_changed = 1;
  }

  # Frequency channel
  if ( defined $self->{_xmlnetwork}->{freq_channel}
    and $self->{modem}->{freq_channel} ne $self->{_xmlnetwork}->{freq_channel} )
  {
    die "Unable to set modem's frequency channel to "
      . $self->{_xmlnetwork}->{freq_channel}
      unless (
      $self->{modem}->setFreqChannel( $self->{_xmlnetwork}->{freq_channel} ) );
    $param_changed = 1;
  }

  # Return to data mode if necessary
  if ($param_changed) {
    $self->{modem}->goToDataMode();
  }

  $self->{is_running} = 1;

  # Notify parent about the start of the server
  $self->{_eventHandler}->swapServerStarted();

  # Discover motes in the current SWAP network
  $self->_discoverMotes();
}

###########################################################
# sub start()
#
# Start SWAP server
###########################################################

sub start() {
  my $self = shift;

  unless ( $self->{is_running} ) {

    if ( $self->{async} ) {

      # Worker thread
      my $thr = threads->create(
        sub {
          $self->_run();
        }
      )->detach();
    } else {
      $self->_run();
    }
  }
}

###########################################################
# sub stop
#
# Stop SWAP server
###########################################################

sub stop() {
  my $self = shift;
  print "Stopping SWAP server...\n";

  # Stop modem
  if ( define $self->{modem} ) {
    $self->{modem}->stop();
  }
  $self->{is_running} = 0;

  # Save network data
  print "Saving network data...\n";
  $self->{network}->save();
}

###########################################################
# sub poll
#
# Poll Modem synchronous (if not running async)
###########################################################

sub poll() {
  my $self = shift;

  if ( $self->{modem} and not $self->{modem}->{async} ) {
    $self->{modem}->poll();
  }
  if ( $self->{_rcvqueue}
    and defined( my $ccPacket = $self->{_rcvqueue}->dequeue_nb() ) )
  {
    $self->_ccPacketReceived($ccPacket);
  }
}

###########################################################
# sub resetNetwork
#
# Clear SWAP network adata nd read swapnet file again
###########################################################

sub resetNetwork() {
  my $self = shift;

  # Clear network data
  $self->{network}->read();
}

###########################################################
# sub _ccPacketReceived
#
# CcPacket received
#
# @param ccPacket: CcPacket received
###########################################################

sub _ccPacketReceived($) {

  my ( $self, $ccPacket ) = @_;

  my $swPacket;
  eval {

    # Convert CcPacket into SwapPacket
    $swPacket = Device::PanStamp::swap::protocol::SwapPacket->new($ccPacket);

    # Notify event
    $self->{_eventHandler}->swapPacketReceived($swPacket);
  };
  if ($@) {
    print "Error handling ccPacket. Reason $@\n";
    return;
  }

  # Check function code
  # STATUS packet received
  if ( $swPacket->{function} eq
    Device::PanStamp::swap::protocol::SwapFunction::STATUS )
  {
    return unless defined $swPacket->{value};

    # Check status message (ecpected response, nonce, ...)?
    $self->_checkStatus($swPacket);

    # Check type of data received
    # Product code received
    if ( $swPacket->{regId} eq
      Device::PanStamp::swap::protocol::SwapRegId::ID_PRODUCT_CODE )
    {
      my $mote = Device::PanStamp::swap::protocol::SwapMote->new(
        $self,
        $swPacket->{value}->toAsciiHex(),
        $swPacket->{srcAddress},
        $swPacket->{security}, $swPacket->{nonce}
      );
      $mote->{nonce} = $swPacket->{nonce};
      $self->_checkMote($mote);
    }

    # Device address received
    elsif ( $swPacket->{regId} eq
      Device::PanStamp::swap::protocol::SwapRegId::ID_DEVICE_ADDR )
    {

      # Check address in list of motes
      $self->updateMoteAddress( $swPacket->{srcAddress},
        $swPacket->{value}->toInteger() );

    }

    # System state received
    elsif ( $swPacket->{regId} eq
      Device::PanStamp::swap::protocol::SwapRegId::ID_SYSTEM_STATE )
    {
      $self->_updateMoteState($swPacket);

    }

    # Periodic Tx interval received
    elsif ( $swPacket->{regId} eq
      Device::PanStamp::swap::protocol::SwapRegId::ID_TX_INTERVAL )
    {

      # Update interval in list of motes
      $self->_updateMoteTxInterval($swPacket);

    }

    # For any other register id
    else {

      # Update register in the list of motes
      $self->_updateRegisterValue($swPacket);
    }

  }

  # QUERY packet received
  elsif ( $swPacket->{function} eq
    Device::PanStamp::swap::protocol::SwapFunction::QUERY )
  {

    # Query addressed to our gateway?
    if ( $swPacket->{destAddress} eq $self->{modem}->{devaddress} ) {

      # Get mote from register address
      my $mote = $self->{network}->get_mote( undef, $swPacket->{regAddress} );
      if ( defined $mote ) {

        # Send status packet
        $self->send_status( $mote, $swPacket->{regId} );
      }
    }

  }

  # COMMAND packet received
  elsif ( $swPacket->{function} eq
    Device::PanStamp::swap::protocol::SwapFunction::COMMAND )
  {

    # Command addressed to our gateway?
    if ( $swPacket->{destAddress} eq $self->{modem}->{devaddress} ) {

      # Get mote from register address
      my $mote = $self->{network}->get_mote( undef, $swPacket->{regAddress} );
      if ( defined $mote ) {

        # Anti-playback security enabled?
        if ( $self->{_xmlnetwork}->{security} & 0x01 ) {

          # Check nonces
          if ( $mote->{nonce} ne $swPacket->{nonce} ) {

            # Nonce missmatch. Transmit correct nonce
            $self->send_nonce();
            return;
          }
        }

        # Send command packet to target mote
        $self->setMoteRegister( $mote, $swPacket->{regId}, $swPacket->{value},
          1 );
      }
    }
  }
}
###########################################################
# sub _checkMote
#
# Check SWAP mote from against the current list
#
# @param mote: to be searched in the list
###########################################################

sub _checkMote($) {

  my ( $self, $mote ) = @_;

  # Add mote to the network
  if ( $self->{network}->add_mote($mote) ) {

    # Save mote in SWAP network file
    $self->{network}->save();

    # Notify event handler about the discovery of a new mote
    $self->{_eventHandler}->newMoteDetected($mote);

    # Notify the event handler about the discovery of new endpoints
    foreach my $reg ( @{ $mote->{regular_registers} } ) {
      foreach my $endp ( @{ $reg->{parameters} } ) {
        $self->{_eventHandler}->newEndpointDetected($endp);
      }
    }
  }
  if ( $self->{_poll_regular_regs} ) {
    if ( time - $self->{_poll_regular_regs_until} > 0 ) {

      # Query all individual registers owned by this mote
      foreach my $reg ( @{ $mote->{regular_registers} } ) {
        $reg->sendSwapQuery();
      }
    } else {
      $self->_endPollingValues();
    }
  }
}

###########################################################
# sub _updateMoteAddress
#
# Update new mote address in list
#
# @param oldAddr: Old address
# @param newAddr: New address
###########################################################

sub _updateMoteAddress($$) {
  my ( $self, $oldAddr, $newAddr ) = @_;

  # Has the address really changed?
  return if ( $oldAddr eq $newAddr );

  # Get mote from list
  my $mote = $self->{network}->get_mote( undef, $oldAddr );
  if ( defined $mote ) {
    $mote->{address} = $newAddr;

    # Notify address change to event handler
    $self->{_eventHandler}->moteAddressChanged($mote);
  }
}

###########################################################
# sub _updateMoteState
#
# Update mote state in list
#
# @param packet: SWAP packet to extract the information from
###########################################################

sub _updateMoteState($) {
  my ( $self, $packet ) = @_;

  # New system state
  my $state = $packet->{value}->toInteger();

  # Get mote from list
  my $mote = $self->{network}->get_mote( undef, $packet->{regAddress} );
  if ( defined $mote ) {

    # Has the state really changed?
    return
      if ( defined $mote->{state} and $mote->{state} eq $state );

    # Update system state in the list
    $mote->{state} = $state;

    # Notify state change to event handler
    $self->{_eventHandler}->moteStateChanged($mote);
  }
}

###########################################################
# sub _updateMoteTxInterval
#
# Update mote Tx interval in list
#
# @param packet: SWAP packet to extract the information from
###########################################################

sub _updateMoteTxInterval($) {
  my ( $self, $packet ) = @_;

  # New periodic Tx interval (in seconds)
  my $interval = $packet->{value}->toInteger();

  # Get mote from list
  my $mote = $self->{network}->get_mote( undef, $packet->{regAddress} );
  if ( defined $mote ) {

    # Has the interval really changed?
    return if ( $mote->{txinterval} eq $interval );

    # Update system state in the list
    $mote->{txinterval} = $interval;
  }
}

###########################################################
# sub _updateRegisterValue
#
# Update register value in the list of motes
#
# @param packet: SWAP packet to extract the information from
###########################################################

sub _updateRegisterValue($) {
  my ( $self, $packet ) = @_;

  # Get mote from list
  my $mote = $self->{network}->get_mote( undef, $packet->{regAddress} );
  if ( defined $mote ) {

    # Search within its list of regular registers
    if ( defined $mote->{regular_registers} ) {
      foreach my $reg ( @{ $mote->{regular_registers} } ) {

        # Same register ID?
        if ( $reg->{id} eq $packet->{regId} ) {

          # Check if value changed and its length
          if ( defined $reg->{value} ) {
            return if ( $reg->{value}->isEqual( $packet->{value} ) );
            return unless ( defined $packet->{value} );
            return
              unless ( $reg->getLength() eq $packet->{value}->getLength() );
          }

          # Save new register value
          $reg->setValue( $packet->{value} );

          # Notify register'svalue change to event handler
          $self->{_eventHandler}->registerValueChanged($reg);

          # Notify endpoint's value change to event handler
          # Has any of the endpoints changed?
          foreach my $endp ( @{ $reg->{parameters} } ) {
            if ( $endp->{valueChanged} ) {
              $self->{_eventHandler}->endpointValueChanged($endp);
            }
          }
          return;
        }
      }
    }

    # Search within its list of config registers
    if ( defined $mote->{config_registers} ) {
      foreach my $reg ( @{ $mote->{config_registers} } ) {

        # Same register ID?
        if ( $reg->{id} eq $packet->{regId} ) {

          # Did register's value change?
          unless ( $reg->{value}->isEqual( $packet->{value} ) ) {

            # Save new register value
            $reg->setValue( $packet->{value} );

            # Notify register'svalue change to event handler
            $self->{_eventHandler}->registerValueChanged($reg);

            # Notify parameter's value change to event handler
            # Has any of the endpoints changed?
            foreach my $param ( @{ $reg->{parameters} } ) {
              if ( $param->{valueChanged} ) {
                $self->{_eventHandler}->parameterValueChanged($param);
              }
            }
            return;
          }
        }
      }
    }
    return;
  }
}

###########################################################
# sub _checkStatus
#
# Compare expected SWAP status against status packet received
# Update security nonces
#
# @param status: SWAP packet to extract the information from
###########################################################

sub _checkStatus($) {
  my ( $self, $status ) = @_;

  # Check possible command ACK
  if (
    ( defined $self->{_expectedAck} )
    and ( $status->{function} eq
      Device::PanStamp::swap::protocol::SwapFunction::STATUS )
    )
  {
    if ( $status->{regAddress} eq $self->{_expectedAck}->{regAddress} ) {
      if ( $status->{regId} eq $self->{_expectedAck}->{regId} ) {
        $self->{_packetAcked} =
          $self->{_expectedAck}->{value}->isEqual( $status->{value} );
      }
    }
  }

  # Check possible response to a precedent query
  delete $self->{_valueReceived};
  if (
    ( defined $self->{_expectedRegister} )
    and ( $status->{function} eq
      Device::PanStamp::swap::protocol::SwapFunction::STATUS )
    )
  {
    if ( $status->{regAddress} eq $self->{_expectedRegister}->getAddress() ) {
      if ( $status->{regId} eq $self->{_expectedRegister}->{id} ) {
        $self->{_valueReceived} = $status->{value};
      }
    }
  }

  # Update security option and nonce in list
  my $mote = $self->{network}->get_mote( undef, $status->{srcAddress} );

  if ( defined $mote ) {

    # Check nonce?
    if ( $self->{_xmlnetwork}->{security} & 0x01 ) {

      # Discard status packet in case of incorrect nonce
      if ( ( $mote->{nonce} > 0 ) and ( $status->{nonce} != 1 ) ) {
        my $lower_limit = $mote->{nonce};
        my $upper_limit = $mote->{nonce} + 5;
        if ( $lower_limit > 0xFF ) {
          $lower_limit -= 0x100;
        }
        if ( $upper_limit > 0xFF ) {
          $upper_limit -= 0x100;
        }

        die "Mote "
          . $mote->{address}
          . ": anti-playback nonce missmatch. Possible attack!"
          unless ( $lower_limit <= $status->{nonce}
          and $status->{nonce} <= $upper_limit );
      }
    }
    $mote->{security} = $status->{security};
    $mote->{nonce}    = $status->{nonce};
  }
}

###########################################################
# sub _discoverMotes
#
# Send broadcasted query to all available (awaken) motes asking them
# to identify themselves
###########################################################

sub _discoverMotes() {
  my $self = shift;

  $self->{_poll_regular_regs}       = 1;
  $self->{_poll_regular_regs_until} = time + _MAX_POLL_VALUES_TIME;
  my $query =
    Device::PanStamp::swap::protocol::SwapQueryPacket->new(
    Device::PanStamp::swap::protocol::SwapRegId::ID_PRODUCT_CODE);
  $query->send($self);
}

###########################################################
# sub _endPollingValues
#
# End polling regular registers each time a product code is received
###########################################################

sub _endPollingValues() {
  my $self = shift;
  $self->{_poll_regular_regs} = 0;
}

###########################################################
# sub send_status
#
# Send status message informing about a register
#
# @param mote: Mote containing the register
# @param regid: Register ID
###########################################################

sub send_status($$) {
  my ( $self, $mote, $regid ) = @_;

  # Get register
  my $reg = $mote->getRegister($regid);
  if ( defined $reg ) {

    # Status packet to be sent
    my $status =
      Device::PanStamp::swap::protocol::SwapStatusPacket->new( $mote->{address},
      $regid, $reg->{value} );
    $status->{srcAddress} = $self->{_xmlnetwork}->{devaddress};
    $self->{nonce}++;
    if ( $self->{nonce} > 0xFF ) {
      $self->{nonce} = 0;
    }
    $status->{nonce} = $self->{nonce};
    $status->send($self);
  }
}

###########################################################
# sub send_nonce
#
# Transmit server's current nonce
###########################################################

sub send_nonce() {
  my $self = shift;

  # Convert nonce to SWAP value
  my $value =
    Device::PanStamp::swap::protocol::SwapValue->new( $self->{nonce} );

  # Status packet to be sent
  my $status = Device::PanStamp::swap::protocol::SwapStatusPacket->new(
    $self->{_xmlnetwork}->{devaddress},
    Device::PanStamp::swap::protocol::SwapRegId::ID_SECU_NONCE, $value );
  $self->{nonce}++;
  if ( $self->{nonce} > 0xFF ) {
    $self->{nonce} = 0;
  }
  $status->{nonce} = $self->{nonce};
  $status->send($self);
}

###########################################################
# sub setMoteRegister
#
# Set new register value on wireless mote
# Non re-entrant method!!
#
# @param mote: Mote containing the register
# @param regid: Register ID
# @param value: New register value
# @param sendack; Send status message from server
#
# @return 1 if the command is correctly ack'ed. Return 0 otherwise
###########################################################

sub setMoteRegister($$$@) {
  my ( $self, $mote, $regid, $value, $sendack ) = @_;

  # Send command multiple times if necessary
  for ( my $i = 0 ; $i < _MAX_SWAP_COMMAND_TRIES ; $i++ ) {

    # Send command
    my $ack = $mote->cmdRegister( $regid->{value} );

    # Wait for aknowledgement from mote
    if ( $self->_waitForAck( $ack, _MAX_WAITTIME_ACK ) ) {
      if ($sendack) {

        # Send status message
        $self->send_status( $mote, $regid );
      }
      return 1;    # ACK received
    }
  }
  return 0;        # Got no ACK from mote
}

###########################################################
# sub setEndpointValue
#
# Set endpoint value
#
# @param endpoint: Endpoint to be controlled
# @param value: New endpoint value
#
# @return 1 if the command is correctly ack'ed. Return 0 otherwise
###########################################################

sub setEndpointValue($$) {
  my ( $self, $endpoint, $value ) = @_;

  # Send command multiple times if necessary
  for ( my $i = 0 ; $i < _MAX_SWAP_COMMAND_TRIES ; $i++ ) {

    # Send command
    my $ack = $endpoint->sendSwapCmd($value);

    # Wait for aknowledgement from mote
    if ( $self->_waitForAck( $ack, _MAX_WAITTIME_ACK ) ) {
      return 1;    # ACK received
    }
  }
  return 0;        # Got no ACK from mote
}

###########################################################
# sub queryMoteRegister
#
# Query mote register, wait for response and return value
# Non re-entrant method!!
#
# @param mote: Mote containing the register
# @param regId: Register ID
#
# @return register value
###########################################################

sub queryMoteRegister($$) {
  my ( $self, $mote, $regId ) = @_;

  # Queried register
  my $register =
    Device::PanStamp::swap::protocol::SwapRegister->new( $mote, $regId );

  # Send query multiple times if necessary
  for ( my $i = 0 ; $i < _MAX_SWAP_COMMAND_TRIES ; $i++ ) {

    # Send query
    $register->sendSwapQuery();

    # Wait for aknowledgement from mote
    my $regVal = $self->_waitForReg( $register, _MAX_WAITTIME_ACK );
    if ( defined $regVal ) {
      return $regVal;    # Got response from mote
    }
  }
  return undef;
}

###########################################################
# sub _waitForAck
#
# Wait for ACK (SWAP status packet)
# Non re-entrant method!!
#
# @param ackpacket: SWAP status packet to expect as a valid ACK
# @param wait_time: Max waiting time in milliseconds
#
# @return 1 if the ACK is received. 0 otherwise
###########################################################

sub _waitForAck($$) {
  my ( $self, $ackpacket, $wait_time ) = @_;

  $self->{_packetAcked} = 0;

  # Expected ACK packet (SWAP status)
  $self->{_expectedAck} = $ackpacket;

  #loops = wait_time / 10
  my $start = time;
  while ( !( $self->{_packetAcked} ) ) {
    select( undef, undef, undef, 0.1 );
    if ( ( time - $start ) * 1000 >= $wait_time ) {
      last;
    }
  }
  my $res = $self->{_packetAcked};
  delete $self->{_expectedAck};
  $self->{_packetAcked} = 0;
  return $res;
}

###########################################################
# sub _waitForReg
#
# Wait for ACK (SWAP status packet)
# Non re-entrant method!!
#
# @param register: Expected register to be informed about
# @param waitTime: Max waiting time in milliseconds
#
# @return 1 if the ACK is received. 0 otherwise
###########################################################

sub _waitForReg($$) {
  my ( $self, $register, $waitTime ) = @_;

  # Expected ACK packet (SWAP status)
  $self->{_expectedRegister} = $register;

  my $loops = $waitTime / 10;
  while ( not defined( $self->{_valueReceived} ) ) {
    select( undef, undef, undef, 0.01 );
    $loops--;
    if ( $loops eq 0 ) {
      last;
    }
  }

  my $res = $self->{_valueReceived};
  delete $self->{_expectedRegister};
  delete $self->{_valueReceived};
  return $res;
}

###########################################################
# sub getNetId
#
# Get current network ID
#
# @return Network ID
###########################################################

sub getNetId() {
  my $self = shift;

  return $self->{modem}->{syncword};
}

###########################################################
# sub update_definition_files
#
# Update Device Definition Files from remote server
###########################################################

sub update_definition_files() {
  my $self = shift;

  print "Downloading Device Definition Files";

  my $local_tar = $XmlSettings::device_localdir . ".tar";

  my $remote = get($XmlSettings::device_remote)
    || die "Unable to update Device Definition Files";

  open( LOCAL, ">", $local_tar );
  print LOCAL $remote;
  close LOCAL;

  die "Unable to extract files from archive: $local_tar"
    unless extract_archive($local_tar);

  unlink $local_tar;
}

###########################################################
# sub new
#
# Class constructor
#
# @param eventHandler: Parent event handler object
# @param settings: path to the main configuration file
# @param verbose: Verbose SWAP traffic
# @param start: Start server upon creation if this flag is True
###########################################################

sub new($@) {    # self, eventHandler, settings = None, start = True ) : """
  my ( $class, $eventHandler, $settings, $start, $async ) = @_;

  $start = 1 unless ( defined $start );
  $async = 1 unless ( defined $async );

  my $is_running : shared;

  my $self = bless {

    # Server's device address
    devaddress => 1,

    # Server's Security nonce
    nonce => 0,

    # Security option
    security => 0,

    # Encryption password
    password => 0,

    # True if last packet was ack'ed
    _packetAcked => 0,

    # Event handling object. Its class must define the following methods
    # in order to dispatch incoming SWAP events:
    # - newMoteDetected(mote)
    # - newEndpointDetected(endpoint)
    # - newParameterDetected(parameter)
    # - moteStateChanged(mote)
    # - moteAddressChanged(mote)
    # - registerValueChanged(register)
    # - endpointValueChanged(endpoint)
    # - parameterValueChanged(parameter)
    _eventHandler => $eventHandler,

    # General settings
    _xmlSettings =>
      Device::PanStamp::swap::xmltools::XmlSettings->new($settings),

    async => $async,

    is_running => $is_running
  }, $class;

  # Update Device Definition Files from Internet server
  if ( $self->{_xmlSettings}->{updatedef} ) {
    $self->update_definition_files();
  }

  ## Verbose SWAP frames
  $self->{verbose} = ( $self->{_xmlSettings}->{debug} > 0 ) ? 1 : 0;

  ## Network data
  $self->{network} =
    Device::PanStamp::swap::protocol::SwapNetwork->new( $self,
    $self->{_xmlSettings}->{swap_file} );

  ## Tells us if the server is running
  $self->{is_running} = 0;

  ## Poll regular registers whenever a product code packet is received
  $self->{_poll_regular_regs} = 0;

  # Start server
  if ($start) {
    $self->start();
  }

  return $self;
}

1;
