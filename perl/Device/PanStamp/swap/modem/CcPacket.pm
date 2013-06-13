###########################################################
#    Standard packet structure of the CC11xx family of IC's
###########################################################

package Device::PanStamp::swap::modem::CcPacket;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

###########################################################
# sub send
#        Transmit packet
#        @param modem: Modem object
###########################################################

sub send($) {
  my ( $self, $modem ) = @_;
  $modem->sendCcPacket($self) if ($modem);
}

###########################################################
# sub toString
#        Convert packet data to string
#        @return CcPacket in string format
###########################################################

sub toString() {
  my $self = shift;

  # Convert list of bytes to list of strings
  my $str = "";
  foreach my $c ( @{ $self->{data} } ) {
    $str .= sprintf( "%02X", $c );
  }
  return $str;
}

###########################################################
#        Class constructor
#        @param strPacket: Wireless packet in string format
###########################################################

sub new(;$) {
  my ( $class, $strPacket ) = @_;

  my $self = {
    data => [],    # Data bytes
    rssi => 0,     # RSSI value in case of packet received
    lqi  => 0      # LQI in case of packet received
  };

  if ( defined $strPacket ) {

    # Check packet length
    die "Incomplete packet received." if ( length $strPacket < 20 );

    # Check the existence of the (RSSI/LQI) pair
    die "Incorrect packet format for incoming data. Lack of (RSSI,LQI)."
      unless $strPacket =~ /^\([0-9a-f]{4}\)/;
    die "Incorrect packet format. Amount of characters should not be odd."
      if ( length $strPacket ) % 2 > 0;
    die "Incorrect packet format" unless $strPacket =~ /^.{6}[0-9a-f]+$/;
    ## RSSI byte
    $self->{rssi} = hex substr( $strPacket, 1, 2 );
    ## LQI byte
    $self->{lqi} = hex substr( $strPacket, 3, 2 );

    # Parse data fields
    for ( my $i = 6 ; $i < length $strPacket ; $i += 2 ) {
      push @{ $self->{data} }, hex substr( $strPacket, $i, 2 );
    }
  }
  return bless $self, $class;
}

1;

