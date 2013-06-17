#########################################################################
# class SwapParam:
#
# Generic SWAP parameter, integrated into a SWAP register
#########################################################################

package Device::PanStamp::swap::protocol::SwapParam;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Time::HiRes qw(time);
use Date::Format qw(strftime);

use Device::PanStamp::swap::protocol::SwapDefs;
use Device::PanStamp::swap::protocol::SwapValue;

#########################################################################
# sub getRegAddress
#
# Return register address of the current parameter
#
# @return Register address
#########################################################################

sub getRegAddress() {
  my $self = shift;

  return $self->{register}->getAddress();
}

#########################################################################
# sub getRegId
#
# Return register ID of the current parameter
#
# @return Register ID
#########################################################################

sub getRegId() {
  my $self = shift;

  return $self->{register}->{id};
}

#########################################################################
# sub update
#
# Update parameter's value, posibly after a change in its parent register
#########################################################################

sub update() {
  my $self = shift;

  $self->{valueChanged} = 0;
  die "Register not specified for current endpoint"
    unless ( defined $self->{register} );

  # Current register value converted to list
  my @lstRegVal = $self->{register}->{value}->toList();

  # Total bits to be copied
  my $indexReg   = $self->{bytePos};
  my $shiftReg   = 7 - $self->{bitPos};
  my $bitsToCopy = $self->{byteSize} * 8 + $self->{bitSize};

  # Current parameter value in list format
  my @lstParamVal = $self->{value}->toList();

  return unless (@lstParamVal);

  # Keep old value
  my $oldParamVal = $self->{value}->clone();
  my $indexParam  = 0;
  my $shiftParam  = $self->{bitSize} - 1;

  if ( $shiftParam < 0 ) {
    $shiftParam = 7;
  }
  foreach my $i ( 0 .. $bitsToCopy ) {
    if ( $indexReg >= scalar(@lstRegVal) ) {
      last;
    }
    if ( ( $lstRegVal[$indexReg] >> $shiftReg ) & 0x01 == 0 ) {
      my $mask = ~( 1 << $shiftParam );
      $lstParamVal[$indexParam] &= $mask;
    } else {
      my $mask = 1 << $shiftParam;
      $lstParamVal[$indexParam] |= $mask;
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

  # Did the value change?
  if ( not $self->{value}->isEqual($oldParamVal) ) {
    $self->{valueChanged} = 1;
  }

  # Update time stamp
  $self->{lastupdate} = time;
}

#########################################################################
# sub setValue
#
# Set parameter value
#
# @param value: New parameter value
#
#########################################################################

sub setValue($) {
  my ( $self, $value ) = @_;

  # Allready a SwapValue?
  if ( ref($value) eq "Device::PanStamp::swap::protocol::SwapValue" ) {

    # Incorrect length?
    return if ( $self->{value}->getLength() != $value->getLength() );

    # Update current value
    $self->{value} = $value;
  } else {

    # Convert to SwapValue
    # Byte length
    my $length = $self->{byteSize};
    if ( $self->{bitSize} > 0 ) {
      $length++;
    }

    my $res;
    if ( ref($value) eq "ARRAY" ) {
      $res = $value;
    } else {

      # if $res is a number
      if (  $self->{type} eq Device::PanStamp::swap::protocol::SwapType::NUMBER
        and $value =~ /^\d+\.?\d*$/ )
      {
        $res = $value;
        if ( defined $self->{unit} ) {
          $res -= $self->{unit}->{offset};
          $res /= $self->{unit}->{factor};

          # Take integer part only
          $res = int($res);
        }
      } elsif (
        $self->{type} eq Device::PanStamp::swap::protocol::SwapType::BINARY )
      {
        my $lower = lc($value);
        $res =
          ( grep { $lower eq $_ } ( "on", "open", "1", "true", "enabled" ) )
          ? 1
          : 0;
      } else {    # SwapType.STRING
        $res = $value;
      }
    }

    # Update current value
    $self->{value} =
      Device::PanStamp::swap::protocol::SwapValue->new( $res, $length );
  }

  # Update time stamp
  $self->{lastupdate} = time;

  # Update register value
  $self->{register}->update();
}

#########################################################################
# sub getValueInAscii
#
# Return value in ASCII string format
#
# @return Value in ASCII format
#########################################################################

sub getValueInAscii() {
  my $self = shift;

  if ( $self->{type} eq Device::PanStamp::swap::protocol::SwapType::NUMBER ) {
    my $val = $self->{value}->toInteger();

    # Add units
    if ( defined $self->{unit} ) {
      if ( defined $self->{unit}->{calc} ) {
        my $oper = $self->{unit}->{calc} =~ s/\$\{val\}/$val/gr;
        $val = eval( "math." . $oper )    #TODO math?
      }
      return $val * $self->{unit}->{factor} + $self->{unit}->{offset};
    } else {
      return $val;
    }
  } elsif (
    $self->{type} eq Device::PanStamp::swap::protocol::SwapType::BINARY )
  {
    my $strVal = $self->{value}->toAscii();
    return "on"  if ( $strVal eq "1" );
    return "off" if ( $strVal eq "0" );
  } else {
    return $self->{value}->toAsciiStr();
  }

  return undef;
}

#########################################################################
# sub setUnit
#
# Set unit for the current parameter
#
# @param strunit: new unit in string format
#########################################################################

sub setUnit($) {
  my ( $self, $strunit ) = @_;

  die "Parameter " . $self->{name} . " does not support units"
    unless ( defined $self->{lstunits} );

  foreach my $unit ( @{ $self->{lstunits} } ) {
    if ( $unit->{name} eq $strunit ) {
      $self->{unit} = $unit;
      return;
    }
  }

  die "Unit " . $strunit . " not found";
}

#########################################################################
# sub new
#
# Class constructor
#
# @param register: Register containing this parameter
# @param pType: Type of SWAP endpoint (see SwapDefs.SwapType)
# @param direction: Input or output (see SwapDefs.SwapType)
# @param name: Short description about the parameter
# @param position: Position in bytes.bits within the parent register
# @param size: Size in bytes.bits
# @param default: Default value in string format
# @param verif: Verification string
# @param units: List of units
#########################################################################

sub new(;$$$$$$$$$) {
  my (
    $class,    $register, $pType,   $direction, $name,
    $position, $size,     $default, $verif,     $units
  ) = @_;

  $pType = Device::PanStamp::swap::protocol::SwapType::NUMBER
    unless defined $pType;
  $direction = Device::PanStamp::swap::protocol::SwapType::INPUT
    unless defined $direction;
  $name     = ""  unless defined $name;
  $position = "0" unless defined $position;
  $size     = "1" unless defined $size;

  # Get true positions
  my $position_dot = index( $position, '.' );

  # Get true sizes
  my $size_dot = index( $size, '.' );

  my $self = bless {

    # Parameter name
    name => $name,

    # Register where the current parameter belongs to
    register => $register,

    # Data type (see SwapDefs.SwapType for more details)
    type => $pType,

    # Direction (see SwapDefs.SwapType for more details)
    direction => $direction,

    # Position (in bits) after bytePos
    bitPos => $position_dot > -1 ? int( substr( $position, $position_dot + 1 ) )
    : 0,

    # Position (in bytes) of the parameter within the register
    bytePos => $position_dot > -1 ? int( substr( $position, 0, $position_dot ) )
    : int($position),

    # Size in bits of the parameter value after byteSize
    bitSize => $size_dot > -1 ? int( substr( $size, $size_dot + 1 ) ) : 0,

    # Size (in bytes) of the parameter value
    byteSize => $size_dot > -1
    ? int( substr( $size, 0, $size_dot ) )
    : int($size),

    # Current value
    value => undef,

    # Time stamp of the last update
    lastupdate => undef,

    # List of units
    lstunits => $units,

    # Selected unit
    unit => ( $units && @{$units} ) ? $units->[0] : undef,

# Flag that tells us whether this parameter changed its value during the last update or not
    valueChanged => 0,

    # Verification string. This can be a macro or a regular expression
    verif => $verif,

    # Display this parameter from master app
    display => 1
  }, $class;

  # Set initial value
  $self->setValue($default) if ( defined $default );
  return $self;
}

#########################################################################
# class SwapCfgParam(SwapParam):
#
# Class representing a configuration parameter for a given mote
#########################################################################

package Device::PanStamp::swap::protocol::SwapCfgParam;

use strict;
use warnings;

use parent qw(Exporter Device::PanStamp::swap::protocol::SwapParam);
our @EXPORT_OK = qw();    # symbols to export on request

#########################################################################
# sub new() {
#
# Class constructor
#
# @param register: Register containing this parameter
# @param pType: Type of SWAP endpoint (see SwapDefs.SwapType)
# @param direction: Input or output (see SwapDefs.SwapType)
# @param name: Short name about the parameter
# @param description: Short description about hte parameter
# @param position: Position in bytes.bits within the parent register
# @param size: Size in bytes.bits
# @param default: Default value in string format
# @param verif: Verification string
#########################################################################

sub new() {
  my ( $class, $register, $pType, $name, $position, $size, $default, $verif ) =
    @_;

  $pType = Device::PanStamp::swap::protocol::SwapType::NUMBER
    unless defined $pType;
  $name     = ""  unless defined $name;
  $position = "0" unless defined $position;
  $size     = "1" unless defined $size;

  my $self = $class->SUPER::new(
    $register, $pType, undef, $name, $position, $size,
    $default,  $verif, undef
  );

  ## Default value
  $self->{default} = $default;

  return bless $self, $class;
}

#########################################################################
# class SwapEndpoint(SwapParam):
#
# SWAP endpoint class
#########################################################################

package Device::PanStamp::swap::protocol::SwapEndpoint;

use strict;
use warnings;

use parent qw(Exporter Device::PanStamp::swap::protocol::SwapParam);
our @EXPORT_OK = qw();    # symbols to export on request
use Time::HiRes qw(time);

#########################################################################
# sub cmdWack
#
# Send SWAP command to remote endpoint and wait for confirmation
#
# @param value: New value
#
# @return 1 if ACK is received from mote. Return 0 otherwise
#########################################################################

sub cmdWack($) {
  my ( $self, $value ) = @_;

  return $self->{register}->{mote}->{server}->setEndpointValue( $self, $value );
}

#########################################################################
# sub sendSwapCmd
#
# Send SWAP command for the current endpoint
#
# @param value: New endpoint value
#
# @return Expected SWAP status response to be received from the mote
#########################################################################

sub sendSwapCmd($) {
  my ( $self, $value ) = @_;

  my $swap_value;

  # Convert to SwapValue
  if ( ref($value) eq "Device::PanStamp::swap::protocol::SwapValue" ) {
    $swap_value = $value;
  } else {

    # Byte length
    my $length = $self->{byteSize};
    if ( $self->{bitSize} > 0 ) {
      $length++;
    }

    my $res;
    if ( ref($value) eq "ARRAY" ) {
      $res = $value;
    } else {

      # if $res is a number
      if (  $self->{type} eq Device::PanStamp::swap::protocol::SwapType::NUMBER
        and $res =~ /^\d+\.?\d*$/ )
      {
        $res = $value;
        if ( defined $self->{unit} ) {
          $res -= $self->{unit}->{offset};
          $res /= $self->{unit}->{factor};

          # Take integer part only
          $res = int($res);
        }
      } elsif (
        $self->{type} eq Device::PanStamp::swap::protocol::SwapType::BINARY )
      {
        my $lower = lc($value);
        $res =
          ( grep { $lower eq $_ } ( "on", "open", "1", "true", "enabled" ) )
          ? 1
          : 0;
      } else {    # SwapType.STRING
        $res = $value;
      }
    }

    $swap_value =
      Device::PanStamp::swap::protocol::SwapValue->new( $res, $length );
  }

  # Register value in list format
  my @lstRegVal = $self->{register}->{value}->toList();

  # Build register value
  my $indexReg = $self->{bytePos};
  my $shiftReg = 7 - $self->{bitPos};

  # Total bits to be copied from this parameter
  my $bitsToCopy = $self->{byteSize} * 8 + $self->{bitSize};

  # Parameter value in list format
  my @lstParamVal = $swap_value->toList();
  my $indexParam  = 0;
  my $shiftParam  = $self->{bitSize} - 1;
  if ( $shiftParam < 0 ) {
    $shiftParam = 7;
  }

  foreach my $i ( 0 .. $bitsToCopy ) {
    if ( ( ( $lstParamVal[$indexParam] >> $shiftParam ) & 0x01 ) == 0 ) {
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

  # Convert to SWapValue
  my $newRegVal =
    Device::PanStamp::swap::protocol::SwapValue->new( \@lstRegVal );

  # Send SWAP command
  return $self->{register}->sendSwapCmd($newRegVal);
}

#########################################################################
# sub sendSwapQuery
#
# Send SWAP query for the current endpoint
#########################################################################

sub sendSwapQuery() {
  my $self = shift;

  $self->{register}->sendSwapQuery();
}

#########################################################################
# sub sendSwapStatus
#
# Send SWAP status packet about this endpoint
#########################################################################

sub sendSwapStatus() {
  my $self = shift;

  $self->{register}->sendSwapStatus();
}

#########################################################################
# sub dumps_units
#
# Serialize list of units available for this endpoint
#########################################################################

sub dumps_units() {
  my $self = shift;

  my @data = ();
  foreach my $unit ( @{ $self->{lstunits} } ) {
    push @data, $unit->{name};
  }

  return \@data;
}

#########################################################################
# sub dumps
#
# Serialize endpoint data to a JSON formatted string
#
# @param include_units: if True, include list of units within the serialized output
#########################################################################

sub dumps(;$) {
  my ( $self, $include_units ) = @_;

  $include_units = 0 unless defined $include_units;

  my $val = $self->getValueInAscii();

  my %data = (
    id       => $self->{id}       =~ s/ /_/gr,
    name     => $self->{name}     =~ s/ /_/gr,
    location => $self->{location} =~ s/ /_/gr,
    type     => $self->{type},
    direction => $self->{direction}
  );

  if ( defined $self->{lastupdate} ) {
    $data{"timestamp"} =
      strftime( "%d %b %Y %H:%M:%S", localtime( $self->{lastupdate} ) );
  }

  $data{"value"} = $val;
  if ( defined $self->{unit} ) {
    $data{unit} = $self->{unit}->{name};
    if ($include_units) {
      $data{units} = $self->dumps_units();
    }
  }

  return \%data;
}

#########################################################################
# sub new
#
# Class constructor
#
# @param register: Register containing this parameter
# @param pType: Type of SWAP endpoint (see SwapDefs.SwapType)
# @param direction: Input or output (see SwapDefs.SwapType)
# @param name: Short description about the parameter
# @param description: Short description about hte parameter
# @param position: Position in bytes.bits within the parent register
# @param size: Size in bytes.bits
# @param default: Default value in string format
# @param verif: Verification string
# @param units: List of units
#########################################################################

sub new (;$$$) {
  my (
    $class,    $register, $pType,   $direction, $name,
    $position, $size,     $default, $verif,     $units
  ) = @_;

  $pType = Device::PanStamp::swap::protocol::SwapType::NUMBER
    unless defined $pType;
  $direction = Device::PanStamp::swap::protocol::SwapType::INPUT
    unless defined $direction;
  $name     = ""  unless defined $name;
  $position = "0" unless defined $position;
  $size     = "1" unless defined $size;

  my $self = bless $class->SUPER::new(
    $register, $pType,   $direction, $name, $position,
    $size,     $default, $verif,     $units
  ), $class;

  ## Endpoint unique id
  my $endp_index = scalar( @{ $self->{register}->{parameters} } );
  $self->{id} =
    $self->getRegAddress() . "." . $self->getRegId() . "." . $endp_index;

  ## Endpoint locationm
  $self->{location} = "SWAP";

  ## Time stamp
  $self->{lastupdate} = undef;
  return $self;
}

1;
