#########################################################################
# class SwapRegister(object):
#
# SWAP register class
#########################################################################

package Device::PanStamp::swap::protocol::SwapRegister;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Device::PanStamp::swap::protocol::SwapValue;

#########################################################################
# sub getAddress(self):
#
# Return address of the current register
#
# @return Register address
#########################################################################

sub getAddress() {
  my $self = shift;
  return $self->{mote}->{address};
}

#########################################################################
# sub sendSwapCmd(self, value):
#
# Send SWAP command to the current register
#
# @param value: New register value
#
# @return Expected SWAP status response to be received from the mote
#########################################################################

sub sendSwapCmd($) {
  my ( $self, $value ) = @_;

  return $self->{mote}->cmdRegister( $self->{id}, $value );
}

#########################################################################
# sub sendSwapQuery
#
# Send SWAP query to the current register
#########################################################################

sub sendSwapQuery() {
  my $self = shift;

  $self->{mote}->qryRegister( $self->{id} );
}

#########################################################################
# sub sendSwapStatus
#
# Send SWAP status packet about this register
#########################################################################

sub sendSwapStatus() {
  my $self = shift;

  $self->{mote}->staRegister( $self->{id} );
}

#########################################################################
# sub cmdValueWack
#
# Send command to register value and wait for mote's confirmation
#
# @param value: New register value
#
# @return True if the command is successfully acknowledged
#########################################################################

sub cmdValueWack($) {
  my ( $self, $value ) = @_;

  return $self->{mote}->cmdRegisterWack( $self->{id}, $value );
}

#########################################################################
# sub add
#
# Add item (endpoint or parameter) to the associated list of items
#
# @param item: Item to be added to the list
#########################################################################

sub add($) {
  my ( $self, $item ) = @_;

  push @{ $self->{parameters} }, $item;
}

#########################################################################
# sub getNbOfItems
#
# Return the amount of items belonging to the current register
#
# @return Amount of items (endpoints or parameters) contained into the current register
#########################################################################

sub getNbOfItems() {
  my $self = shift;

  return scalar( @{ $self->{parameters} } );
}

#########################################################################
# sub getLength
#
# Return data length in bytes
#
# @return Length in bytes of the current register
#########################################################################

sub getLength() {
  my $self = shift;

  my $maxByteSize = 0;
  my $maxBytePos  = 0;
  my $maxBitSize  = 0;
  my $maxBitPos   = 0;

  # Iterate along the contained parameters
  foreach my $param ( @{ $self->{parameters} } ) {
    if ( $param->{bytePos} > $maxBytePos ) {
      $maxBytePos  = $param->{bytePos};
      $maxBitPos   = $param->{bitPos};
      $maxByteSize = $param->{byteSize};
      $maxBitSize  = $param->{bitSize};
    } elsif ( $param->{bytePos} eq $maxBytePos
      and $param->{bitPos} >= $maxBitPos )
    {
      $maxBitPos   = $param->{bitPos};
      $maxByteSize = $param->{byteSize};
      $maxBitSize  = $param->{bitSize};
    }
  }

  # Calculate register length
  my $bitLength = $maxBytePos * 8 + $maxByteSize * 8 + $maxBitPos + $maxBitSize;
  my $byteLength = $bitLength / 8;
  if ( ( $bitLength % 8 ) > 0 ) {
    $byteLength++;
  }

  return $byteLength;
}

#########################################################################
# sub update
#
# Update register value according to the values of its contained parameters
#########################################################################

sub update() {
  my $self = shift;

  # Return if value is None?
  return unless ( defined $self->{value} );

  # Current register value converted to list
  my @lstRegVal = $self->{value}->toList();

  # For every parameter contained in this register
  foreach my $param ( @{ $self->{parameters} } ) {
    my $indexReg = $param->{bytePos};
    my $shiftReg = 7 - $param->{bitPos};

    # Total bits to be copied from this parameter
    my $bitsToCopy = $param->{byteSize} * 8 + $param->{bitSize};

    # Parameter value in list format
    my @lstParamVal = $param->{value}->toList();
    my $indexParam  = 0;
    my $shiftParam  = $param->{bitSize} - 1;
    if ( $shiftParam < 0 ) {
      $shiftParam = 7;
    }

    if (@lstParamVal) {
      foreach my $i ( 0 .. $bitsToCopy ) {
        if ( ( $lstParamVal[$indexParam] >> $shiftParam ) & 0x01 eq 0 ) {
          my $mask = ~( 1 << $shiftReg );
          $lstRegVal[$indexReg] &= $mask;
        } else {
          my $mask = 1 << $shiftReg;
          $lstRegVal[$indexReg] |= $mask;
        }

        $shiftReg--;
        $shiftParam--;

        # Register byte over?
        if ( $shiftReg < 0 ) {
          $indexReg++;
          $shiftReg = 7;
        }

        # Parameter byte over?
        if ( $shiftParam < 0 ) {
          $indexParam++;
          $shiftParam = 7;
        }
      }
    }
  }

  # Update mote's time stamp
  if ( defined $self->{mote} ) {
    $self->{mote}->updateTimeStamp();
  }
}

#########################################################################
# sub setValue
#
# Set register value
#
# @param value: New register value
#########################################################################

sub setValue($) {
  my ( $self, $value ) = @_;

  die "setValue only accepts SwapValue objects (" . ref($value) . ")"
    unless ( ref($value) eq "Device::PanStamp::swap::protocol::SwapValue" );

  # Set register value
  $self->{value} = $value;

  # Update mote's time stamp
  $self->{mote}->updateTimeStamp();

# Now update the value in every endpoint or parameter contained in this register
  foreach my $param ( @{ $self->{parameters} } ) {
    $param->update();
  }
}

#########################################################################
# sub isConfig
#
# This method tells us whether the current register contains configuration paramters or not
#
# @return True if this register contains configuration parameters. Return False otherwise
#########################################################################

sub isConfig() {

  my $self = shift;
  return 1
    if ( @{ $self->{parameters} }
    and ref( $self->{parameters}->[0] ) eq "Device::PanStamp::swap::protocol::SwapCfgParam" );
  return 0;
}

#########################################################################
# sub dumps
#
# Serialize register data to a JSON formatted string
#
# @param include_units: if True, include list of units for each endpoint
# within the serialized output
#########################################################################

sub dumps(;$) {
  my ( $self, $include_units ) = @_;

  $include_units = 0 unless $include_units;
  return undef if $self->isConfig();

  my %data = ();
  $data{id}   = $self->{id};
  $data{name} = $self->{name};

  my @endpoints_data = ();

  foreach my $item ( @{ $self->{parameters} } ) {
    push @endpoints_data, $item->dumps($include_units);
  }

  $data{endpoints} = \@endpoints_data;

  return \%data;
}

#########################################################################
# sub new
#
# Class constructor
#
# @param mote: Mote containing the current register
# @param id: Register ID
# @param name: Generic name of the current register
#########################################################################

sub new(;$$$) {
  my ( $class, $mote, $id, $description ) = @_;

  return bless {

    # Mote owner of the current register
    mote => $mote,

    # Register ID
    id => $id,

    # SWAP value contained in the current register
    value => undef,

    # Brief name
    name => $description,

# List of endpoints or configuration parameters belonging to the current register
    parameters => []
    },
    $class;
}

1;
