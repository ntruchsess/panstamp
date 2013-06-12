###########################################################
# Serial configuration settings
###########################################################

package Device::PanStamp::swap::xmltools::XmlSerial;

use strict;
use warnings;

use File::Basename;
use XML::Simple qw(:strict);

###########################################################
# sub read
#
# Read configuration file
###########################################################

sub read() {
  my $self = shift;

  my $tree;

  # Parse XML file
  eval { $tree = XMLin( $self->{file_name}, ForceArray => [], KeyAttr => [] ); };
  if ($@) {
    if ( defined $self->{file_name} ) {
      print
        "Unable to read serial config from $self->{file_name}. Reason is: $@\n";
    }
    else {
      print "unable to read serial config. Reason is: undefined filename.\n";
    }
  }

  return unless defined $tree;

  # Get serial port
  $self->{port} = $tree->{port} if ( defined $tree->{port} );

  # Get serial speed
  $self->{speed} = $tree->{speed} if ( defined $tree->{speed} );

  # Run SerialPort in it's own thread
  $self->{async} = $tree->{async} if ( defined $tree->{asnyc} );
}

###########################################################
# sub save
#
# Save serial port settings in disk
###########################################################

sub save() {
  my $self = shift;

  open FILE, ">", $self->{file_name}
    or die $!;
  print FILE "<?xml version=\"1.0\"?>\n";
  print FILE "<serial>\n";
  print FILE "\t<port>" . $self->{port} . "</port>\n";
  print FILE "\t<speed>" . $self->{speed} . "</speed>\n";
  print FILE "\t<async>" . $self->{asnyc} . "</async>\n";
  print FILE "</serial>\n";
  close FILE;
}

###########################################################
# sub new
#
# Class constructor
#
# @param filename: Path to the serial configuration file
###########################################################

sub new(;$) {
  my ( $class, $file_name ) = @_;
  $file_name = "serial.xml" unless defined $file_name;

  my $self = bless {
    ## Name/path of the current configuration file
    file_name => $file_name,
    ## Name/path of the serial port
    port => "/dev/ttyUSB0",
    ## Speed of the serial port in bps
    speed => 9600,
    ## Run SerialPort in it's own thread
    async => 1
  }, $class;

  # Read XML file
  $self->read();
  return $self;
}

1;
