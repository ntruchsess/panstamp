package Device::PanStamp::swap;

use modem::SerialModem qw(SerialModem);
use protocol::SwapRegister qw(SwapRegister);
use protocol::SwapDefs qw(SwapFunction,SwapRegId);
use protocol::SwapPacket qw(SwapPacket,SwapQueryPacket,SwapStatusPacket);
use protocol::SwapMote qw(SwapMote);
use protocol::SwapNetwork qw(SwapNetwork);
use protocol::SwapValue qw(SwapValue);
use protocol::SmartEncrypt qw(Password);
use xmltools::XmlSettings qw(XmlSettings);
use xmltools::XmlSerial qw(XmlSerial);
use xmltools::XmlNetwork qw(XmlNetwork);

#import threading
#import time
#import urllib2
#import tarfile
#import os

###########################################################
# SWAP server class
###########################################################

use constant {

  # Maximum waiting time (in ms) for ACK's
  _MAX_WAITTIME_ACK => 2000,

  # Max tries for any SWAP command
  _MAX_SWAP_COMMAND_TRIES => 3
};

###########################################################
# sub run
#
# Start SWAP server thread
###########################################################

sub run() {
  my $self = shift;

  # Network configuration settings
  $self->{_xmlnetwork} = XmlNetwork->new( $self->{_xmlSettings}->{network_file} );
  $self->{devaddress}  = $self->{_xmlnetwork}->{devaddress};
  $self->{security}    = $self->{_xmlnetwork}->{security};
  $self->{password}    = Password->new( $self->{_xmlnetwork}->{password} );

  # Serial configuration settings
  $self->{_xmlserial} = XmlSerial-new( $self->{_xmlSettings}->{serial_file} );

  # Create and start serial modem object
  $self->{modem} = SerialModem->new( $self->{_xmlserial}->{port}, $self->{_xmlserial}->{speed}, $self->{verbose} );

  # Declare receiving callback function
  $self->{modem}->setRxCallback( $self->{_ccPacketReceived} );

  # Set modem configuration from _xmlnetwork
  my $param_changed = 0;

  # Device address
  if ( defined $self->{_xmlnetwork}->{devaddress}
    and $self->{modem}->{devaddress} ne $self->{_xmlnetwork}->{devaddress} )
  {
    die "Unable to set modem's device address to " . $self->{_xmlnetwork}->{devaddress}
      unless ( $self->{modem}->setDevAddress( $self->{_xmlnetwork}->{devaddress} ) );
    $param_changed = 1;
  }

  # Device address
  if ( defined $self->{_xmlnetwork}->{network_id}
    and $self->{modem}->{syncword} ne $self->{_xmlnetwork}->{network_id} )
  {
    die "Unable to set modem's network ID to " . $self->{_xmlnetwork}->{network_id}
      unless ( $self->{modem}->setSyncWord( $self->{_xmlnetwork}->{network_id} ) );
    $param_changed = 1;
  }

  # Frequency channel
  if ( defined $self->{_xmlnetwork}->{freq_channel}
    and $self->{modem}->{freq_channel} ne $self->{_xmlnetwork}->{freq_channel} )
  {
    die "Unable to set modem's frequency channel to " . $self->{_xmlnetwork}->{freq_channel}
      unless ( $self->{modem}->setFreqChannel( $self->{_xmlnetwork}->{freq_channel} ) );
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
  $self->discoverMotes();
}

###########################################################
# sub stop
#
# Stop SWAP server
###########################################################

sub stop() {
  my $self = shift;
  print "Stopping SWAP server...";

  # Stop modem
  if ( define $self->{modem} ) {
    $self->{modem}->stop();
  }
  $self->{is_running} = 0;

  # Save network data
  print "Saving network data...";
  $self->{network}->save();
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

  # Convert CcPacket into SwapPacket
  my $swPacket = SwapPacket->new($ccPacket);

  # Notify event
  eval {
    $self->{_eventHandler}->swapPacketReceived(swPacket);
    except SwapException;
  };
  return if ($@);

  # Check function code
  # STATUS packet received
  if ( $swPacket->{function} eq SwapFunction . STATUS ) {    #TODO implement SwapFunction.STATUS
    return unless defined $swPacket - {value};

    # Check status message (ecpected response, nonce, ...)?
    $self->_checkStatus($swPacket);

    # Check type of data received
    # Product code received
    #TODO implement SwapRegId.ID_PRODUCT_CODE
    if ( $swPacket->{regId} eq SwapRegId . ID_PRODUCT_CODE ) {
      my $mote = SwapMote->new( $self, $swPacket->{value}->toAsciiHex(), $swPacket - {srcAddress}, $swPacket - {security}, $swPacket - {nonce} ) $mote->{nonce} = $swPacket->{nonce};
      $self->_checkMote($mote);

    }

    # Device address received
    elsif ( $swPacket->{regId} eq SwapRegId . ID_DEVICE_ADDR ) {

      # Check address in list of motes
      $self->updateMoteAddress( $swPacket->{srcAddress}, $swPacket->{value}->toInteger() );

    }

    # System state received
    elsif ( $swPacket->{regId} eq == SwapRegId . ID_SYSTEM_STATE ) {
      $self->_updateMoteState($swPacket);

    }

    # Periodic Tx interval received
    elsif ( $swPacket->{regId} eq == SwapRegId . ID_TX_INTERVAL ) {

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
  elsif ( $swPacket->{function} eq SwapFunction . QUERY ) {

    # Query addressed to our gateway?
    if ( $swPacket->{destAddress} eq $self->{modem}->{devaddress} ) {

      # Get mote from register address
      my $mote = $self->{network}->get_mote( address = swPacket . regAddress );    #TODO parameter address?
      if ( defined $mote ) {

        # Send status packet
        $self->send_status( $mote, $swPacket->{regId} );
      }
    }

  }

  # COMMAND packet received
  elsif ( $swPacket->{function} eq SwapFunction . COMMAND ) {

    # Command addressed to our gateway?
    if ( $swPacket->{destAddress} eq $self->{modem}->{devaddress} ) {

      # Get mote from register address
      my $mote = $self->{network}->get_mote( address = swPacket . regAddress );    #TODO parameter address?
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
        $self->setMoteRegister( $mote, $swPacket->{regId}, $swPacket->{value}, sendack = True );    #TODO parameter sendack
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
    if ( defined $self->{_eventHandler}->{newMoteDetected} ) {
      $self->{_eventHandler}->newMoteDetected($mote);
    }

    # Notify the event handler about the discovery of new endpoints
    foreach my $reg ( @{ $mote->{regular_registers} } ) {
      foreach my $endp ( @{ $reg->{parameters} } ) {
        if ( defined $self->{_eventHandler}->{newEndpointDetected} ) {
          $self->{_eventHandler}->newEndpointDetected($endp);
        }
      }
    }
  }
  if ( $self->{_poll_regular_regs} ) {

    # Query all individual registers owned by this mote
    foreach my $reg ( @{ $mote->{regular_registers} } ) {
      $reg->sendSwapQuery();
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
  my $mote = $self->{network}->get_mote( address = oldAddr );    #TODO parameter address
  if ( defined $mote ) {
    $mote->{address} = $newAddr;

    # Notify address change to event handler
    if ( defined $self->{_eventHandler}->{moteAddressChanged} ) {
      $self->{_eventHandler}->moteAddressChanged($mote);
    }
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
  my $mote = $self->{network}->get_mote( address = packet . regAddress );    #TODO parameter address
  if ( defined $mote ) {

    # Has the state really changed?
    return
      if ( $mote->{state} eq $state );

    # Update system state in the list
    $mote->{state} = $state;

    # Notify state change to event handler
    if ( defined $self->{_eventHandler}->{moteStateChanged} ) {
      $self->{_eventHandler}->moteStateChanged($mote);
    }
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
  my $interval = $packet->{value} . > toInteger();

  # Get mote from list
  my $mote = $self->{network}->get_mote( address = packet . regAddress );    #TODO parameter address
  if ( defined $mote ) {

    # Has the interval really changed?
    return if ( $mote->{txinterval} eq interval );

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
  my $mote = $self->{network}->get_mote( address = packet . regAddress );    #TODO parameter address
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
            return unless ( $reg->getLength() eq $packet->{value}->getLength() );
          }

          # Save new register value
          $reg->setValue( $packet->{value} );

          # Notify register'svalue change to event handler
          if ( defined $self->{_eventHandler}->{registerValueChanged} ) {
            $self->{_eventHandler}->registerValueChanged($reg);
          }

          # Notify endpoint's value change to event handler
          if ( defined $self->{_eventHandler}->{endpointValueChanged} ) {

            # Has any of the endpoints changed?
            foreach my $endp ( @{ $reg->{parameters} } ) {
              if ( $endp->{valueChanged} ) {
                $self->{_eventHandler}->endpointValueChanged($endp);
              }
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
            if ( defined $self->{_eventHandler}->{registerValueChanged} ) {
              $self->{_eventHandler}->registerValueChanged($reg);
            }

            # Notify parameter's value change to event handler
            if ( defined $self->{_eventHandler}->{parameterValueChanged} ) {

              # Has any of the endpoints changed?
              foreach my $param ( @{ $reg->{parameters} } ) {
                if ( $param->{valueChanged} ) {
                  $self->{_eventHandler}->parameterValueChanged($param);
                }
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
  if ( ( defined $self->{_expectedAck} ) and ( $status->{function} eq SwapFunction . STATUS ) ) {    #TODO SwapFunction.STATUS
    if ( $status->{regAddress} eq $self->{_expectedAck}->{regAddress} ) {
      if ( $status->{regId} eq $self->{_expectedAck}->{regId} ) {
        $self->{_packetAcked} = $self->{_expectedAck}->{value}->isEqual( $status->{value} );
      }
    }
  }

  # Check possible response to a precedent query
  delete $self->{_valueReceived};
  if ( ( defined $self->_expectedRegister ) and ( $status->{function} eq SwapFunction . STATUS ) ) {    #TODO SwapFunction.STATUS
    if ( $status->{regAddress} eq $self->{_expectedRegister}->getAddress() ) {
      if ( $status->{regId} eq $self->{_expectedRegister}->{id} ) {
        $self->{_valueReceived} = $status->{value};
      }
    }
  }

  # Update security option and nonce in list
  my $mote = $self->{network}->get_mote( address = $status->{srcAddress} );                             #TODO parameter address

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

        #TODO str?
        die "Mote " . str( $mote->{address} ) . ": anti-playback nonce missmatch. Possible attack!" unless ( $lower_limit <= $status->{nonce} <= $upper_limit );
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

  $self->{_poll_regular_regs} = 1;
  my $query = SwapQueryPacket->new( SwapRegId . ID_PRODUCT_CODE );    #TODO SwapRegId.ID_PRODUCT_CODE
  $query->send($self);
  my $t = threading . Timer( 20.0, self . _endPollingValues ) t . start();    #TODO threading?
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
    my $status = SwapStatusPacket->new( $mote . $address, $regid, $reg->{value} );
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
  my $value = SwapValue->new( $self->{nonce} );

  # Status packet to be sent
  my $status = SwapStatusPacket->new( $self->{_xmlnetwork}->{devaddress}, SwapRegId . ID_SECU_NONCE, $value );
  $self->{nonce}++;
  if ( $self->{nonce} > 0xFF ) {
    $self->{nonce} = 0;
  }
  $status->{nonce} = $self - {nonce};
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
  for ( my $i = 0 ; $i < SwapServer . _MAX_SWAP_COMMAND_TRIES ; $i++ ) {    #TODO SwapServer._MAX_SWAP_COAMMAND_TRIES

    # Send command
    my $ack = $mote->cmdRegister( $regid->{value} );

    # Wait for aknowledgement from mote
    if ( $self->_waitForAck( $ack, SwapServer . _MAX_WAITTIME_ACK ) ) {
      if ($sendack) {

        # Send status message
        $self->send_status( $mote, $regid );
      }
      return 1;                                                             # ACK received
    }
  }
  return 0;                                                                 # Got no ACK from mote
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
  for ( my $i = 0 ; $i < SwapServer . _MAX_SWAP_COMMAND_TRIES ; $i++ ) {    #TODO SwapServer._MAX_SWAP_COMMAND_TRIES

    # Send command
    my $ack = $endpoint->sendSwapCmd($value);

    # Wait for aknowledgement from mote
    if ( $self->_waitForAck( $ack, SwapServer . _MAX_WAITTIME_ACK ) ) {
      return 1;                                                             # ACK received
    }
  }
  return 0;                                                                 # Got no ACK from mote
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
  my $register = SwapRegister->new( $mote, $regId );

  # Send query multiple times if necessary
  for ( my $i = 0 ; $i < SwapServer . _MAX_SWAP_COMMAND_TRIES ; $i++ ) {    #TODO SwapServer._MAX_SWAP_COMMAND_TRIES

    # Send query
    $register->sendSwapQuery();

    # Wait for aknowledgement from mote
    my $regVal = $self->_waitForReg( $register, SwapServer . _MAX_WAITTIME_ACK );    #TODO SwapServer._MAX_WAITTIME_ACK
    if ( defined $regVal ) {
      return $regVal;                                                                # Got response from mote
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
  my $start = time . time();    #TODO time
  while ( !( $self->{_packetAcked} ) ) {
    time . sleep(0.1);
    if ( time . time() - start ) * 1000 >= wait_time done;
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
  while ( not defined( $self->_valueReceived ) ) {
    time . sleep(0.01) loops -= 1;    #TODO time
    if ( $loops eq 0 ) {
      done;
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

  my $local_tar = XmlSettings->{device_localdir} . ".tar";

  eval {    #TODO retrieve file from URL
    my $remote = urllib2 . urlopen( XmlSettings . device_remote ) local = open( local_tar, 'wb' ) local . write( remote . read() ) local . close();
  };

  my $tar = $tarfile . open(local_tar) direc =
    os . path . dirname( XmlSettings . device_localdir ) tar . extractall( path = direc ) tar . close() os . remove(local_tar) except : print "Unable to update Device Definition Files";
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

sub new($@) { # self, eventHandler, settings = None, start = True ) : """
  my ($class,$eventHandler,$settings,$start) = @_;
  
  $start = 1 unless (defined $start);

  #threading . Thread . __init__(self) self . _stop = threading . Event()

  my $self = {
    # Server's device address
    devaddress => 1,
    # Server's Security nonce
    nonce => 0,
    # Security option
    security => 0,
    # Encryption password
  password => 0,

  # True if last packet was ack'ed
  _packetAcked =>0,

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
  _xmlSettings => XmlSettings->new($settings)
  };

  # Update Device Definition Files from Internet server
  if ($self->{_xmlSettings}->{updatedef} ) {
    $self->update_definition_files();
  }

  ## Verbose SWAP frames
  $self->{verbose} = ($self->{_xmlSettings}->{debug} > 0) ? 1 : 0; 
  
  ## Network data
  $self->{network} = SwapNetwork->new( $self, $self->{_xmlSettings}->{swap_file} );

  ## Tells us if the server is running
  $self->{is_running} = 0;

  ## Poll regular registers whenever a product code packet is received
  $self->{_poll_regular_regs}=0;

  # Start server
  if ($start) {
    $self->start();
  }
  
  return bless $self,$class;
}
