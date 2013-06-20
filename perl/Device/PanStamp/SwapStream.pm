package Device::PanStamp::Stream;

use strict;
use warnings;

use Carp;

use Device::PanStamp::protocol::SwapPacket;

use constant PANSTREAM_MAXDATASIZE => 55 - 3;
use constant PANSTREAM_REGISTER_ID => 11;

sub swapPacketReceived($) {
  my ( $self, $packet ) = @_;

  #ignore packets not for this device
  return
    unless (
    $packet->{destAddress} eq $self->{interface}->{server}->{devaddress} );

  #ignore packets not for the stream register
  return unless ( $packet->{regId} eq $self->{regId} );

  my $received = Device::PanStamp::SwapStream::SwapStreamPacket->new($packet);

  my $send = 0;

  #previous packet acknowledged by master
  if (  $self->{send_packet}
    and $received->{stream_received_id} eq
    $self->{send_packet}->{stream_send_id} )
  {

    # discard data of previous packet
    delete $self->{send_packet};
    $self->{send_buffer} =
      substr( $self->{send_buffer}, $received->{stream_received_bytes} );

    my $self->{id}++;
    if ( $self->{id} > 255 ) {
      $self->{id} = 1;
    }

  }

  if ( $received->{stream_send_id} ) {

    # new packet received (not a retransmit of a previously retrieved packet)
    if ( ( not defined $self->{received_packet} )
      or $self->{received_packet}->{stream_send_id} ne
      $received->{stream_send_id} )
    {
      $self->{received_packet} = $received;
      $self->{receive_buffer} .= $received->{stream_data};
    }

    #acknowledge package
    if ( defined $self->{send_packet} ) {
      $self->{send_packet}->{stream_received_bytes} =
        length( $received->{stream_data} );
      $self->{send_packet}->{stream_received_id} = $received->{stream_send_id};
    } else {
      my $sendlen = length( $received->{stream_data} );
      my $sendid = $sendlen ? $self->{id} : 0;
      $self->{send_packet} =
        Device::PanStamp::SwapStream::SwapStreamPacket->new(
        undef,
        $self->{destAddress},
        $self->{regId},
        $sendlen > PANSTREAM_MAXDATASIZE ? PANSTREAM_MAXDATASIZE : $sendlen,
        $received->{stream_send_id},
        $sendid,
        substr( $self->{send_buffer}, PANSTREAM_MAXDATASIZE )
        );

# $swapPacket, $regAddress, $regId, $received_bytes, $received_id, $send_id, $data
    }
  }

  if ( defined $self->{send_packet} ) {
    $self->{send_packet}->send( $self->{interface}->{server} );
  }
}

sub available() {
  my $self = shift;
  return length( $self->{receive_buffer};
}

sub read(;$) {
  my ( $self, $len ) = @_;
  return -1 if ( $self->{receive_buffer} eq "" );
  if ( defined $len ) {
    my $ret = substr( $self->{receive_buffer}, 0, $len );
    $self->{receive_buffer} =
      $len >= length( $self->{receive_buffer} )
      ? ""
      : substr( $self->{receive_buffer}, $len );
    return $ret;
  } else {
    my $ret = $self->{receive_buffer};
    $self->{receive_buffer} = "";
    return $ret;
  }
}

sub write($) {
  my ( $self, $data ) = @_;
  $self->{send_buffer} .= $data;
}

sub new($;$) {
  my ( $class, $interface, $regId ) = @_;

  $regId = PANSTREAM_REGISTER_ID unless defined $regId;
  return bless {
    send_buffer    => "",
    receive_buffer => "" interface => $interface,
    regId          => $regId
  }, $class;
}
}

package Device::PanStamp::SwapStream::SwapStreamPacket;

use strict;
use warnings;

use parent qw(Device::PanStamp::protocol::SwapPacket);

sub new($;$$$$$) {
  my ( $class, $swapPacket, $regAddress, $regId, $received_bytes, $received_id,
    $send_id, $data )
    = @_;

  if ( defined $swapPacket ) {

    my @value = $swapPacket->{value}->toList();
    $swapPacket->{stream_received_bytes} = $value[0];
    $swapPacket->{stream_received_id}    = $value[1];
    $swapPacket->{stream_send_id}        = $value[2];
    $swapPacket->{stream_data} = pack( "A*", @value[ 3 .. @value - 1 ] );

    return bless $swapPacket, $class;
  } else {
    return $class->SUPER::new( undef, $regAddress, undef, undef, undef, undef,
      $regId,
      [ $received_bytes, $received_id, $send_id, unpack( "A*", $data ) ] );

    # $ccPacket, $destAddr, $hop, $nonce, $function, $regAddr, $regId, $value
  }
}

1;
