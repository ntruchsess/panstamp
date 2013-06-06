use XmlSettings;
use protocol::SwapParam qw(SwapCfgParam,SwapEndpoint);
use protocol::SwapRegister;
use protocol::SwapValue;
use protocol::SwapDefs qw(SwapType);

use XML::Simple;

#########################################################################
# class DeviceEntry
#
# Class representing a device entry in a device directory
#########################################################################

#########################################################################
# sub new
#
# Class constructor
#
# @param pid: Product ID
# @param option: Command-line alias
# @param label: GUI label
#########################################################################

sub new($$$) {
  my ( $class, $pid, $option, $label ) = @_;

  return bless {
    ## Product ID
    id => $pid,
    ## Command-line alias
    option => $option,
    ## GUI label
    label => $label
  }, $class;
}

#########################################################################
# class DeveloperEntry
#
# Class representing a device directory for a given developer
#########################################################################

#########################################################################
# sub addDevice
# Add device entry to the list for the current developer
#
# @param device: Device or mote to be added to the list
#########################################################################

sub addDevice($) {
  my ( $self, $device ) = @_;
  push @{ $self->{devices} }, $device;
}

#########################################################################
# sub new
#
# Class constructor
#
# @param id: Developer ID
# @param name: Name of the developer or manufacturer
#########################################################################

sub new($$) {
  my ( $class, $did, $name ) = @_;

  return bless {
    ## Developer ID
    id => $did,
    ## Developer or manufacturer name
    name => $name,
    ## List of device entries for the current developer
    devices => []
  };
}

#########################################################################
# class XmlDeviceDir
#
# Class implementing directory files linking device names with
# its corresponding description files
#########################################################################

#########################################################################
# sub read
#
# Read configuration file
#########################################################################

sub read() {
  my $self = shift;

  # Parse XML file
  my $tree = XMLin( $self->{fileName} );

  return unless defined $tree and defined $tree->{developer};

  # List of developers
  foreach my $devel ( @{ $tree->{developer} } ) {

    # Get developer id
    die "Developer section needs a valid ID in " . $self->{fileName}
      unless defined $devel->{id};

    # Get developer name
    die "Developer section needs a name in " . $self->{fileName}
      unless defined $devel->{name};

    # Create developer entry
    my $developer = DeveloperEntry->new( $devel->{id}, $devel->{name} );

    # Parse devices belonging to this developer
    if ( defined $devel->{dev} ) {
      foreach my $dev ( @{ $devel->{dev} } ) {

        # Get product id
        die "Device section needs a valid ID in " . $self->{fileName}
          unless defined $dev->{id};

        # Get folder name / command-line option
        die "Device section needs a comman-line option in " . $self->{fileName}
          unless defined $dev->{name};

        # Get GUI label
        die "Device section needs a label in " . $self->{fileName}
          unless defined $dev->{label};

        # Create device entry
        my $device =
          DeviceEntry->new( $dev->{id}, $dev->{name}, $dev->{label} );

        # Add device to the developer entry
        $developer->addDevice($device);

        # Append developer to the list
        push @{ $self->{developers} }, $developer;
      }
    }
  }
}

#########################################################################
# sub getDeviceDef
#
# Return mote definition data (XmlDevice object) given a
# command-line option passed as argument
#
# @param option: Command-line option string
#
# @return Device definition object
#########################################################################

sub getDeviceDef($) {
  my ( $self, $option ) = @_;

  foreach my $devel ( @{ $self->{developers} } ) {
    foreach my $dev ( @{ $devel->{devices} } ) {
      if ( $option->lower() eq $dev->{option} ) {
        return XmlDevice->new( devel_id = devel . id, prod_id = dev . id )
          ;    #TODO check parameters!
      }
    }
  }
  return undef;
}

#########################################################################
# sub getDevicePath
#
# Get path to the device definition file
#
# @param devel_id: Developer ID
# @param prod_id: Product ID
#
# @return Path (string) to the XML definition file. Return None in case of device not found
#########################################################################

sub getDevicePath($$) {
  my ( $self, $devel_id, $prod_id ) = @_;
  foreach my $developer ( @{ $self->{developers} } ) {
    if ( $devel_id eq $developer->{id} ) {
      foreach my $device ( @{ $developer->{devices} } ) {
        if ( $prod_id eq $device->{id} ) {
          return
              os 
            . path
            . join(
            XmlSettings . device_localdir,
            developer . name,
            device . option + ".xml"
            );    #TODO access global XmlSettings
        }
      }
    }
  }
  return undef;
}

#########################################################################
# sub new
#
# Class constructor
#########################################################################

sub new() {
  my $class = shift;

  my $self = bless {
    ## Path to the configuration file
    fileName => XmlSettings
      . device_localdir + os
      . sep +__xmldirfile__,    #TODO access global XmlSettings
    ## List of devices
    developers => []
  }, $class;

  # Parse document
  $self->read();
}

#########################################################################
# class XmlUnit:
#
# Endpoint units appearing in any XmlDevice object
#########################################################################

#########################################################################
# sub new
#
# Class constructor
#
# @param name: Name of the unit
# @param factor: Factor conversion operand
# @param offset: Offset conversion operand
# @param calc:
#########################################################################

sub new(;$$$$) {
  my ( $class, $name, $factor, $offset, $calc ) = @_;

  $name   = "" unless defined $name;
  $factor = 1  unless defined $factor;
  $offset = 0  unless defined $offset;

  return bless {
    ## Unit name
    name => $name,

    # Factor operator
    factor => $factor,

    # Offset operator
    offset => $offset,
    ## Optional calculator
    calc => $calc
  }, $class;
}

#########################################################################
# class XmlDevice(object):
#
# Device configuration settings
#########################################################################

#########################################################################
# sub getDefinition
#
# Read current configuration file
#########################################################################

sub getDefinition() {
  my $self = shift;
  return unless defined $self->{fileName};

  # Parse XML file
  my $tree = XMLin( $self->{fileName} );

  die $self->{fileName} . "does not exist" unless defined $tree;

  # Get manufacturer
  $self->{manufacturer} = $tree->{developer};

  # Get product name
  $self->{product} = $tree->{product};

  # Get Power Down flag
  $self->{pwrdownmode} = ( lc( $tree->{pwrdownmode} ) eq "true" )
    if defined $tree->{pwrdownmode};

  # Get periodic tx interval
  $self->{txinterval} = $tree->{txinterval};
}

#########################################################################
# sub getRegList
#
# Return list of registers
#
# @param config: Set to True if Configuration register are required. False for regular ones
#
# @return List of registers
#########################################################################

sub getRegList(;$) {
  my ( $self, $config ) = @_;
  $config = 0 unless defined $config;

  return undef unless defined $self->{fileName};

  # List of config registers belonging to the current device
  my @lstRegs = ();

  # Parse XML file
  my $tree = XMLin( $self->{fileName} );
  return undef unless defined $tree;

  # Get manufacturer

  # List of register elements belonging to the device
  my $regtype = $config ? "config" : "regular";

  my $lstElemReg = tree->{ $regtype . "/reg" );

      if ( defined $listElemReg ) {
        foreach my $reg ( @{$lstElemReg} ) {

          # Get register name
          my $regName = reg->{name} );

          # Create register from id and mote
          my $swRegister =
            SwapRegister->new( $self->{mote}, $reg->{id},
              defined $regName ? $regName : "" );

          # List of endpoints belonging to the register
          my $elementName = $config ? "param" : "endpoint";

          my $lstElemParam = $reg->{$elementName};

          foreach my $param ( @{$lstElemParam} ) {

              # Read XML fields
              my $paramType = defined $param->{type} ? $param->{type} : "num";
              my $paramDir  = defined $param->{dir}  ? $param->{dir}  : "inp";
              my $paramName = defined $param->{name} ? $param->{name} : "";
              my $paramPos =
                defined $param->{position} ? $param->{position} : "0";
              my $paramSize = defined $param->{size} ? $param->{size} : "1";
              my $defVal = defined $param->{default} ? $param->{default} : "0";
              my $verif = $param->{verif};

              # Get list of units
              my $units = $param->{"units/unit"};
              my @lstUnits;
              if ( defined $units and scalar( @{$units} ) > 0 ) {
                @lstUnits = ();
                foreach my $unit ( @{$units} ) {
                  my $name    = $unit->{name};
                  my $factor  = defined $unit->{factor} ? $unit->{factor} : 1;
                  my $offset  = defined $unit->{offset} ? $unit->{offset} : 0;
                  my $calc    = $unit->{calc};
                  my $xmlUnit = XmlUnit->new( $name, $factor, $offset, $calc );
                  push @lstUnits, $xmlUnit;
                }
              }

              my $swParam;

              if ($config) {

                # Create SWAP config parameter
                $swParam = SwapCfgParam->new(
                  register = swRegister, pType = paramType,
                  name = paramName,    #TODO parameters!
                  position = paramPos, size = paramSize, default = defVal,
                  verif    = verif
                );
              }
              else {

                # Create SWAP endpoint
                $swParam = SwapEndpoint->new(
                  register = swRegister, pType = paramType,
                  direction = paramDir,
                  name      = paramName,    #TODO parameters!
                  position = paramPos, size = paramSize, default = defVal,
                  verif = verif, units = lstUnits
                );
              }

              # Add current parameter to the register
              $swRegister->add($swParam);

              # Create empty value for the register
              $swRegister->{value} =
                SwapValue->new( [0] *swRegister . getLength() )
                ;    #TODO construct String of '0' of given length
              $swRegister->update();

              # Add endpoint to the list
              push @lstRegs, $swRegister;
          }
        }
    }
    } return scalar(@lstRegs) ? \@lstRegs : undef;
}

#########################################################################
# sub new
#
# Class constructor
#
# @param mote: Real mote object
# @param devel_id: Manufacturer ID
# @param prod_id: Product ID
#########################################################################

sub new(;$$$) {
    my ( $class, $mote, $devel_id, $prod_id ) = @_;
    ## Device (mote)

    my $self = bless { mote => $mote }, $class;

    my $device_dir = XmlDeviceDir->new();

    $self->{fileName};

    ## Name/path of the current configuration file
    if ( defined $devel_id and defined $prod_id ) {
      $self->{fileName} = $device_dir->getDevicePath( $devel_id, $prod_id );
      die "Definition file not found for mote" unless defined $self->{fileName};
    }
    ## Name of the Manufacturer
    $self->{manufacturer} = undef;
    ## Name of the Product
    $self->{product} = undef;
    ## Power down mode (True or False). If True, the mote sleeps most of the times
    $self->{pwrdownmode} = 0;
    ## Interval (in sec) between periodic transmissions. 0 for disabled
    $self->{txinterval} = 0;

    if ( defined $self->{mote} ) {
      $self->{fileName} = $device_dir
        . getDevicePath( $self->{mote}->{manufacturer_id},
        $self->{mote}->{product_id} );
      die "Definition file not found for mote" unless defined $self->{fileName};
    }

    # Read definition parameters from XML file
    $self->getDefinition();
    return $self;
}

1;
