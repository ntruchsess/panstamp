#########################################################################
# Wireless network configuration settings
#########################################################################

package Device::PanStamp::swap::xmltools::XmlNetwork;

use strict;
use warnings;

use File::Basename;
use XML::Simple qw(:strict);

#########################################################################
# sub read
#
# Read configuration file
#########################################################################

sub read() {
  my $self = shift;

  my $tree;

  # Parse XML file
  eval {
    my $tree =
      XMLin( $self->{file_name}, ForceArray => [], KeyAttr => [] );
  };
  if ($@) {
    if ( defined $self->{file_name} ) {
      print
"Unable to read network settings from $self->{file_name}. Reason is: $@\n";
    } else {
      print "unable to read network settings. Reason is: undefined filename.\n";
    }
  }
  return unless defined $tree;

  # Get frequency channel
  $self->{freq_channel} = $tree->{channel} if defined $tree->{channel};

  # Get Network ID
  $self->{network_id} = $tree->{netid} if defined $tree->{netid};

  # Get device address
  $self->{devaddress} = $tree->{address} if defined $tree->{address};

  # Get security option
  $self->{security} = $tree->{security} if defined $tree->{security};

  # Get encryption password
  $self->{password} = $tree->{password} if defined $tree->{password};
}

#########################################################################
# sub save
#
# Save network settings in file
#########################################################################

sub save() {
  my $self = shift;

  open FILE, ">", $self->{file_name}
    or die $!;
  print FILE "<?xml version=\"1.0\"?>\n";
  print FILE "<network>\n";
  print FILE "\t<channel>" . $self->{freq_channel} . "</channel>\n";
  printf FILE "\t<netid>%02X</netid>\n", $self->{network_id};
  print FILE "\t<address>" . $self->{devaddress} . "</address>\n";
  print FILE "\t<security>" . $self->{security} . "</security>\n";

  if ( $self->{password} ne "" ) {
    print FILE "\t<password>" . $self->{password} . "</password>\n";
  }
  print FILE "</network>\n";
  close FILE;
}
#########################################################################
# sub new
#
# Class constructor
#
# @param filename: Path to the network configuration file
#########################################################################

sub new(;$) {
  my ( $class, $file_name ) = @_;

  $file_name = "network.xml" unless defined $file_name;

  my $self = bless {
    ## Name/path of the current configuration file
    file_name => $file_name,
    ## Frequency channel
    freq_channel => 0,
    ## Network identifier (synchronization word)
    network_id => 0xB547,
    ## Device address
    devaddress => 1,
    ## Security option
    security => 0,
    ## Encryption password (12 bytes)
    password => ""
    },
    $class;

  # Read XML file
  $self->read();
  return $self;
}

1;
