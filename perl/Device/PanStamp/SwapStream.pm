package Device::PanStamp::Stream;

use strict;
use warnings;

use Time::HiRes qw(tv_interval gettimeofday);

use Device::PanStamp::protocol::SwapPacket;

use constant PANSTREAM_MAXDATASIZE => 55 - 4;
use constant PANSTREAM_REGISTER_ID => 12;

sub swapPacketReceived($) {
  my ( $self, $packet ) = @_;

  #ignore packets not for this device
  #  return
  #    unless (
  #    $packet->{destAddress} eq $self->{interface}->{server}->{devaddress} );

  #ignore packets not for the stream register
  return unless ( $packet->{regId} eq $self->{regId} );

  my $received = Device::PanStamp::SwapStream::SwapStreamPacket->new($packet);

  print "received packet. ".
    "bytes: $received->{stream_received_bytes}, ".
    "received_id: $received->{stream_received_id}, " . 
    "send_id: $received->{stream_send_id}, ".
    "data: $received->{stream_data}\n";

  #check whether this package is acknowledges the previous sent packet
  if (  $self->{send_packet}
    and $self->{send_packet}->{stream_send_id} eq
    $received->{stream_received_id} )
  {

    # discard data of previous packet
    delete $self->{send_packet};
    # if previous packet had send_id 0, it was acknowledge-only, transmitting no data 
    if ( $received->{stream_received_id} ) {
      $self->{send_buffer} =
        substr( $self->{send_buffer}, $received->{stream_received_bytes} );
  
      $self->{id}++;
      if ( $self->{id} > 255 ) {
        $self->{id} = 1;
      }
    }
  }

  #check whether received packet contains data (send_id > 0)
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
    #if previous packet sent is not yet acknowledged by mote, resend outgoing data acknowledging the last received packet
    if ( defined $self->{send_packet} ) {
      $self->{send_packet} =
        Device::PanStamp::SwapStream::SwapStreamPacket->new(
        undef,
        $self->{destAddress},
        $self->{regId},
        length( $self->{received_packet}->{stream_data} ),
        $self->{received_packet}->{stream_send_id},
        $self->{send_packet}->{stream_send_id},
        $self->{send_packet}->{stream_data}
        );
    #previous packet was acknowledged by mote, craft a new packet transmitting data from sendbuffer (if any)          
    } else {
      $self->{send_packet} =
        Device::PanStamp::SwapStream::SwapStreamPacket->new(
        undef,
        $self->{destAddress},
        $self->{regId},
        length( $received->{stream_data} ),
        $received->{stream_send_id},
        $self->{send_buffer} eq "" ? 0 : $self->{id},
        substr( $self->{send_buffer}, 0, PANSTREAM_MAXDATASIZE )
        );
      $self->{retransmit_factor} = 1;
    # $swapPacket, $regAddress, $regId, $received_bytes, $received_id, $send_id, $data
    }
  }

  if ( defined $self->{send_packet} ) {
    $self->transmit();
  }
}

sub available() {
  my $self = shift;
  return length( $self->{receive_buffer} );
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
  # print "write\n";
  my ( $self, $data ) = @_;
  $self->{send_buffer} .= $data;
  if ( length( $self->{send_buffer} ) >= PANSTREAM_MAXDATASIZE ) {
    $self->flush();
  }
}

sub flush() {
  # print "flush\n";
  my $self = shift;
  return if ( defined $self->{send_packet} or $self->{send_buffer} eq "" );
  $self->{send_packet} = Device::PanStamp::SwapStream::SwapStreamPacket->new(
    undef,
    $self->{destAddress},
    $self->{regId},
    0,
    0,
    $self->{id},
    substr( $self->{send_buffer}, 0, PANSTREAM_MAXDATASIZE )
  );
  $self->{send_packet}->send( $self->{interface}->{server} );
  my @last_transmit = gettimeofday();
  $self->{last_transmit} = \@last_transmit;
  $self->{retransmit_factor} = 1;
}

sub transmit() {
  # print "transmit\n";
  my $self = shift;
  if ( tv_interval( $self->{last_transmit} ) > $self->{interval} * $self->{retransmit_factor}) {
    if ( defined $self->{send_packet} ) {
      $self->{send_packet}->send( $self->{interface}->{server} );
      if ( $self->{send_packet}->{stream_send_id} ) {
        my @last_transmit = gettimeofday();
        $self->{last_transmit} = \@last_transmit;
        $self->{retransmit_factor} *= 2;
      } else {
        delete $self->{send_packet};
        $self->{last_transmit} = [0,0];
        $self->{retransmit_factor} = 1;
      }
    } else {
      $self->flush();
    }
  }
}

sub new($;$) {
  my ( $class, $interface, $regId ) = @_;

  $regId = PANSTREAM_REGISTER_ID unless defined $regId;
  return bless {
    send_buffer    => "",
    receive_buffer => "",
    interface      => $interface,
    regId          => $regId,
    id             => 1,
    interval       => 1.0,
    last_transmit  => [0,0],
    retransmit_factor => 1
  }, $class;
}
package Device::PanStamp::SwapStream::SwapStreamPacket;

use strict;
use warnings;

use parent qw(Device::PanStamp::protocol::SwapPacket);

sub send($) {
  my ($self,$server) = @_;
  
  print "send packet. ".
    "bytes: $self->{stream_received_bytes}, ".
    "received_id: $self->{stream_received_id}, " . 
    "send_id: $self->{stream_send_id}, ".
    "data: $self->{stream_data}\n";
  
  $self->SUPER::send($server);
}

sub new($;$$$$$) {
  my ( $class, $swapPacket, $regAddress, $regId, $received_bytes, $received_id,
    $send_id, $data )
    = @_;

  if ( defined $swapPacket ) {

    my @value = $swapPacket->{value}->toList();
    $swapPacket->{stream_received_bytes} = $value[0];
    $swapPacket->{stream_received_id}    = $value[1];
    $swapPacket->{stream_send_id}        = $value[2];
    $swapPacket->{stream_data} = pack( "C*", @value[ 3 .. @value - 1 ] );

    return bless $swapPacket, $class;
  } else {
    my $self =
      $class->SUPER::new( undef, $regAddress, undef, undef, undef, undef,
      $regId,
      [ $received_bytes, $received_id, $send_id, unpack( "C*", $data ) ] );
    $self->{stream_received_bytes} = $received_bytes;
    $self->{stream_received_id}    = $received_id;
    $self->{stream_send_id}        = $send_id;
    $self->{stream_data}           = $data;

    # $ccPacket, $destAddr, $hop, $nonce, $function, $regAddr, $regId, $value
    return bless $self, $class;
  }
}

1;
