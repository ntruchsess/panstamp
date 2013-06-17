#########################################################################
# class SwapMote
#
# SWAP mote class
#########################################################################

package Device::PanStamp::protocol::SwapMote;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Time::HiRes qw(time);
use Device::PanStamp::protocol::SwapPacket;
use Device::PanStamp::protocol::SwapDefs;
use Device::PanStamp::protocol::SwapValue;
use Device::PanStamp::xmltools::XmlDevice;

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
  my $infPacket =
    Device::PanStamp::protocol::SwapStatusPacket->new( $self->{address},
    $regId, $value );

  # Command to be sent to the mote
  my $cmdPacket = Device::PanStamp::protocol::SwapCommandPacket->(
    $self->{address}, $regId, $value, $self->{nonce}
  );

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
  my $qryPacket =
    Device::PanStamp::protocol::SwapQueryPacket->new( $self->{address},
    $regId );

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
    Device::PanStamp::protocol::SwapStatusPacket->new( $self->{address},
    $regId, $reg->{value} );

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
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

sub setAddress($) {
  my ( $self, $address ) = @_;

  my $val = Device::PanStamp::protocol::SwapValue->new( $address, 1 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_DEVICE_ADDR, $val );
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

  my $val = Device::PanStamp::protocol::SwapValue->new( $netId, 2 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_NETWORK_ID, $val );
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

  my $val = Device::PanStamp::protocol::SwapValue->new( $channel, 1 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_FREQ_CHANNEL, $val );
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

  my $val = Device::PanStamp::protocol::SwapValue->new( $secu, 1 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_SECU_OPTION, $val );
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

  my $val = Device::PanStamp::protocol::SwapValue->new( $interval, 2 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_TX_INTERVAL, $val );
}

#########################################################################
# sub restart
#
# Ask mote to restart
#
# @return 1 if this command is confirmed from the mote. Return 0 otherwise
#########################################################################

sub restart() {
  my $self = shift;
  my $val =
    Device::PanStamp::protocol::SwapValue->new( $SwapState::RESTART, 1 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_SYSTEM_STATE, $val );
}

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
    Device::PanStamp::protocol::SwapValue->new( $SwapState::RXOFF, 1 );
  return $self->cmdRegisterWack( Device::PanStamp::protocol::SwapRegId::ID_SYSTEM_STATE, $val );
}

#########################################################################
# sub updateTimeStamp
#
# Update time stamp
#########################################################################

sub updateTimeStamp() {
  my $self = shift;

  $self->{timestamp} = time;
}

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
}

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
}

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
    manufacturer => $self->{ $self->{definition}->{manufacturer} },
    name         => $self->{ $self->{definition}->{product} },
    address      => $self->{address},
    registers    => \@regs
  };
}

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

    # Swap server object
    server => $server,

    # Product code
    product_code => $product_code,

    # Product ID
    product_id => 0,

    # Manufacturer ID
    manufacturer_id => 0,

    # Definition settings
    config => undef,

# Get manufacturer and product id from product code
#        if product_code is not None:
#            for i in range(4):
#                self.manufacturer_id = self.manufacturer_id | (product_code[i] << 8 * (3-i))
#                self.product_id = self.product_id | (product_code[i + 4] << 8 * (3-i))

    manufacturer_id => hex( substr( $product_code, 0, 8 ) ),
    product_id      => hex( substr( $product_code, 8 ) ),

    # Device address
    address => $address,

    # Security option
    security => $security,

    # Current mote's security nonce
    nonce => undef,

    # State of the mote
    state => $SwapState::RXOFF,

    # List of regular registers provided by this mote
    regular_registers => undef,

    # List of config registers provided by this mote
    config_registers => undef,
  }, $class;

  # Definition file
  ## Definition settings
  my $definition = Device::PanStamp::xmltools::XmlDevice->new($self);
  $self->{definition} = $definition;
  if ( defined $definition ) {

    # List of regular registers
    $self->{regular_registers} = $definition->getRegList();

    # List of config registers
    $self->{config_registers} = $definition->getRegList(1);

    # Powerdown mode
    $self->{pwrdownmode} = $definition->{pwrdownmode};

    # Interval between periodic transmissions
    $self->{txinterval} = $definition->{txinterval};
  }
  ## Time stamp of the last update received from mote
  $self->{timestamp} = time;

  return $self;
}

1;
