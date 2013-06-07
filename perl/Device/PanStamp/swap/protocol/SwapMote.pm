package Device::Panstamp::swap::protocol::SwapMote;
use strict;
use warnings;
use SwapPacket qw(SwapStatusPacket SwapCommandPacket SwapQueryPacket);
use SwapDefs qw(SwapRegId SwapState);
use SwapValue qw(SwapValue);
use Device::PanStamp::swap::xmltools::XmlDevice qw(XmlDevice);

#########################################################################
# class SwapMote
#
# SWAP mote class
#########################################################################

#########################################################################
# sub cmdRegister
#
# Send command to register and return expected response
#
# @param regId: Register ID
# @param value: New value
#
# @return Expected SWAP status packet sent from mote after reception of this command
#########################################################################

sub cmdRegister($$) {
  my ( $self, $regId, $value ) = @_;

  # Expected response from mote
  my $infPacket = SwapStatusPacket->new( $self->{address}, $regId, $value );

  # Command to be sent to the mote
  my $cmdPacket =
    SwapCommandPacket->( $self->{address}, $regId, $value, $self->{nonce} );

  # Send command
  $cmdPacket->send( $self->{server} );

  # Return expected response
  return $infPacket;
}

#########################################################################
# sub qryRegister
#
# Send query to register
#
# @param regId: Register ID
#########################################################################

sub qryRegister($) {
  my ( $self, $regId ) = @_;

  # Query packet to be sent
  my $qryPacket = SwapQueryPacket->new( $self->{address}, $regId );

  # Send query
  $qryPacket->send( $self->{server} );
}

#########################################################################
# sub staRegister
#
# Send SWAP status packet about the current value of the register passed as argument
#
# @param regId: Register ID
# @param value: New value
#########################################################################

sub staRegister($) {
  my ( $self, $regId ) = @_;

  # Get register
  my $reg = $self->getRegister($regId);

  # Status packet to be sent
  my $infPacket =
    SwapStatusPacket->new( $self->{address}, $regId, $reg->{value} );

  # Send SWAP status packet
  $infPacket->send( $self->{server} );
}

#########################################################################
# sub cmdRegisterWack
#
# Send SWAP command to remote register and wait for confirmation
#
# @param regId: Register ID
# @param value: New value
#
# @return 1 if ACK is received from mote. Return 0 otherwise
#########################################################################

sub cmdRegisterWack($$) {
  my ( $self, $regId, $value ) = @_;

  return $self->{server}->setMoteRegister( $self, $regId, $value );
}

#########################################################################
# sub setAddress
#
# Set mote address
#
# @param address: New mote address
#
# @return True if this command is confirmed from the mote. Return False otherwise
#########################################################################

sub setAddress($) {
  my ( $self, $address ) = @_;

  my $val = SwapValue->new( $address, 'length' => 1 ); #TODO parameter 'length'?
  return $self->cmdRegisterWack( SwapRegId::ID_DEVICE_ADDR, $val );
}

#########################################################################
# sub setNetworkId
#
# Set mote's network id. Return true if ACK received from mote
#
# @param netId: New Network ID
#
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

sub setNetworkId($) {
  my ( $self, $netId ) = @_;

  my $val = SwapValue->new( $netId, 'length' => 2 );   #TODO parameter 'length'?
  return $self->cmdRegisterWack( SwapRegId::ID_NETWORK_ID, $val );
}

#########################################################################
# sub setFreqChannel
#
# Set mote's frequency channel. Return true if ACK received from mote
#
# @param channel: New frequency channel
#
# @return 1 if this command is confirmed from the mote. Return 1 otherwise
#########################################################################

sub setFreqChannel($) {
  my ( $self, $channel ) = @_;

  my $val = SwapValue->( $channel, 'length' => 1 );    #TODO parameter 'length'?
  return $self->cmdRegisterWack( SwapRegId::ID_FREQ_CHANNEL, $val );
}

#########################################################################
# sub setSecurity
#
# Set mote's security option. Return true if ACK received from mote
#
# @param secu: Security option
#
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

sub setSecurity($) {
  my ( $self, $secu ) = @_;

  my $val = SwapValue->( $secu, 'length' => 1 );    #TODO parameter 'length'?
  return $self->cmdRegisterWack( SwapRegId::ID_SECU_OPTION, $val );
}

#########################################################################
# sub setTxInterval
#
# Set periodic Tx interval. Return true if ACK received from mote
#
# @param interval: New Tx interval
#
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

sub setTxInterval($) {
  my ( $self, $interval ) = @_;

  my $val = SwapValue->( $interval, 'length' => 2 );   #TODO parameter 'length'?
  return $self->cmdRegisterWack( SwapRegId::ID_TX_INTERVAL, $val );
}

#########################################################################
# sub restart
#
# Ask mote to restart
#
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

subf restart() {
  my $self = shift;
    my $val =
    SwapValue->( SwapState::RESTART, 'length' => 1 );  #TODO parameter 'length'?
    return $self->cmdRegisterWack( SwapRegId::ID_SYSTEM_STATE, $val );
};

#########################################################################
# sub leaveSync
#
# Ask mote to leave SYNC mode (RXON state)
#
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

sub leaveSync() {
  my $self = shift;
  my $val =
    SwapValue->new( SwapState::RXOFF, 'length' = 1 );  #TODO parameter 'length'?
  return $self->cmdRegisterWack( SwapRegId::ID_SYSTEM_STATE, $val );
};

#########################################################################
# sub updateTimeStamp
#
# Update time stamp
#########################################################################

sub updateTimeStamp() {
  my $self = shift;

  $self->{timestamp} = time . time();    #TODO time
};

#########################################################################
# sub getRegister
#
# Get register given its ID
#
# @param regId: Register ID
# @return SwapRegister object
#########################################################################

sub getRegister($) {
  my ( $self, $regId ) = @_;

  # Regular registers
  foreach my $reg ( @{ $self->{regular_registers} } ) {
    return $reg if ( $reg->{id} eq $regId );
  }

  # Configuration registers
  foreach my $reg ( @{ $self->{config_registers} } ) {
    return $reg if ( $reg->{id} eq $regId );
  }

  return undef;
};

#########################################################################
# sub getParameter
#
# Get parameter given its name
#
# @param name: name of the parameter belonging to this mote
#
# @return: SwapParam object
#########################################################################

sub getParameter($) {
  my ( $self, $name ) = @_;

  # Regular registers
  foreach my $reg ( @{ $self->{regular_registers} } ) {
    foreach my $param ( @{ $reg->{parameters} } ) {
      return $param if ( $param->{name} eq $name );
    }
  }

  # Configuration registers
  foreach my $reg ( @{ $self->{config_registers} } ) {
    foreach my $param ( @{ $reg->{parameters} } ) {
      return $param if ( $param->{name} eq $name );
    }
  }
  return undef;
};

#########################################################################
#sub dumps
#
# Serialize mote data to a JSON formatted string
#
# @param include_units: if True, include list of units for each endpoint
# within the serialized output
#########################################################################

sub dumps(;$) {
  my ( $self, $include_units ) = @_;

  $include_units = 0 unless ( defined $include_units );

  my @regs = ();
  foreach my $reg ( @{ $self->{regular_registers} } ) {
    push @regs, $reg->dumps($include_units);
  }

  return {
    pcode        => $self->{product_code},
    manufacturer => $self->{ definition . manufacturer },
    name         => $self->{ definition . product },
    address      => $self->{address},
    registers    => \@regs
  };
};

#########################################################################
# sub new
#
# Class constructor
#
# @param server: SWAP server object
# @param product_code: Product Code
# @param address: Mote address
#########################################################################

sub new(;$$$$$) {
  my ( $class, $server, $product_code, $address, $security, $nonce ) = @_;

  $address  = 0xFF unless ( defined $address );
  $security = 0    unless ( defined $security );
  $nonce    = 0    unless ( defined $nonce );

  die "SwapMote constructor needs a valid SwapServer object"
    unless ( defined $server );

  my $self = bless {
    ## Swap server object
    server => $server,
    ## Product code
    product_code => $product_code,
    ## Product ID
    product_id => 0,
    ## Manufacturer ID
    manufacturer_id => 0,
    ## Definition settings
    config => undef,

    # Get manufacturer and product id from product code

#        if product_code is not None:
#            for i in range(4):
#                self.manufacturer_id = self.manufacturer_id | (product_code[i] << 8 * (3-i))
#                self.product_id = self.product_id | (product_code[i + 4] << 8 * (3-i))

    manufacturer_id => hex( substr( $product_code, 0, 8 ) ),
    product_id      => hex( substr( $product_code, 8 ) )
  }, $class;

  # Definition file
  ## Definition settings
  my $self->{definition} = XmlDevice->new($self);

  ## Device address
  $self->{address} = $address,
    ## Security option
    $self->{security} = $security,
    ## Current mote's security nonce
    $self->{nonce} = undef,
    ## State of the mote
    $self->{state} = SwapState::RXOFF,
    ## List of regular registers provided by this mote
    $self->{regular_registers} = undef,
    ## List of config registers provided by this mote
    $self->{config_registers} = undef,
    if ( defined $self->{definition} )
  {

    # List of regular registers
    $self->{regular_registers} = $self->{definition}->getRegList();

    # List of config registers
    $self->{config_registers} =
      $self->{definition}->getRegList( config = True ); #TODO parameter 'config'
  }
  ## Time stamp of the last update received from mote
  $self->{timestamp} = time . time();
  ## Powerdown mode
  $self->{pwrdownmode} = $self->{definition}->{pwrdownmode};
  ## Interval between periodic transmissions
  $self->{txinterval} = $self->{definition}->{txinterval};

  return $self;
}

1;

