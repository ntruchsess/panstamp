package Device::PanStamp::Stream;

use strict;
use warnings;

use Time::HiRes qw(tv_interval gettimeofday);

use Device::PanStamp::protocol::SwapPacket;

use constant PANSTREAM_MAXDATASIZE => 36; #55 - 4;
use constant PANSTREAM_REGISTER_ID => 12;

sub registerValueChanged($) {
  my ( $self, $register ) = @_;

  my $received = Device::PanStamp::SwapStream::Value->new( $register->{value} );

  print "received packet. "
    . "bytes: $received->{received_bytes}, "
    . "received_id: $received->{received_id}, "
    . "send_id: $received->{send_id}, "
    . "data: $received->{data}\n";

  #check whether this package is acknowledges the previous sent packet
  if (  $self->{send_value}
    and $self->{send_value}->{send_id} eq $received->{received_id} )
  {
    # discard data of previous packet
    delete $self->{send_value};

# if previous packet had send_id 0, it was acknowledge-only, transmitting no data
    if ( $received->{received_id} ) {
      $self->{send_buffer} =
        substr( $self->{send_buffer}, $received->{received_bytes} );

      $self->{id}++;
      if ( $self->{id} > 255 ) {
        $self->{id} = 1;
      }
    }
  }

  #check whether received packet contains data (send_id > 0)
  if ( $received->{send_id} ) {
    
    # new packet received (not a retransmit of a previously retrieved packet)
    if ( ( not defined $self->{received_value} )
      or $self->{received_value}->{send_id} ne $received->{send_id} )
    {
      $self->{received_value} = $received;
      $self->{receive_buffer} .= $received->{data};
    }

#acknowledge package
#if previous packet sent is not yet acknowledged by mote, resend outgoing data acknowledging the last received packet
    if ( defined $self->{send_value} ) {
      $self->{send_value}->{received_bytes} =
        length( $self->{received_value}->{data} );
      $self->{send_value}->{received_id} = $self->{received_value}->{send_id};

#previous packet was acknowledged by mote, craft a new packet transmitting data from sendbuffer (if any)
    } else {
      $self->{send_value} = Device::PanStamp::SwapStream::Value->new(
        undef,
        length( $self->{received_value}->{data} ),
        $self->{received_value}->{send_id},
        $self->{send_buffer} eq "" ? 0 : $self->{id},
        substr( $self->{send_buffer}, 0, PANSTREAM_MAXDATASIZE )
      );
      $self->{retransmit_factor} = 1;
    }
  }

  if ( defined $self->{send_value} ) {
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
  return if ( defined $self->{send_value} or $self->{send_buffer} eq "" );
  
  $self->{send_value} =
    Device::PanStamp::SwapStream::Value->new( undef, 0, 0, $self->{id},
    substr( $self->{send_buffer}, 0, PANSTREAM_MAXDATASIZE ) );

  Device::PanStamp::SwapStream::Packet->new( $self->{destAddress},
    $self->{regId}, $self->{send_value} )->send( $self->{interface}->{server} )
    ;

  my @last_transmit = gettimeofday();
  $self->{last_transmit}     = \@last_transmit;
  $self->{retransmit_factor} = 1;
}

sub transmit() {

  # print "transmit\n";
  my $self = shift;
  
  if ( tv_interval( $self->{last_transmit} ) >
    $self->{interval} * $self->{retransmit_factor} )
  {
    if ( defined $self->{send_value} ) {

      Device::PanStamp::SwapStream::Packet->new( $self->{destAddress},
        $self->{regId}, $self->{send_value} )
        ->send( $self->{interface}->{server} );

      if ( $self->{send_value}->{send_id} ) {
        my @last_transmit = gettimeofday();
        $self->{last_transmit} = \@last_transmit;
        $self->{retransmit_factor} *= 2;
      } else {
        delete $self->{send_value};
        $self->{last_transmit} = [ 0, 0 ];
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
    send_buffer       => "",
    receive_buffer    => "",
    interface         => $interface,
    regId             => $regId,
    id                => 1,
    interval          => 1.0,
    last_transmit     => [ 0, 0 ],
    retransmit_factor => 1
  }, $class;
}

package Device::PanStamp::SwapStream::Packet;

use strict;
use warnings;

use parent qw(Device::PanStamp::protocol::SwapPacket);

sub send($) {
  my ( $self, $server ) = @_;

  print "send packet. "
    . "bytes: $self->{stream_value}->{received_bytes}, "
    . "received_id: $self->{stream_value}->{received_id}, "
    . "send_id: $self->{stream_value}->{send_id}, "
    . "data: $self->{stream_value}->{data}\n";

  $self->SUPER::send($server);
}

sub new($$$) {
  my ( $class, $regAddress, $regId, $swap_stream_value ) = @_;

  my $self =
    $class->SUPER::new( undef, $regAddress, undef, undef, undef, undef, $regId,
    $swap_stream_value->toSwapValue() );
  $self->{stream_value} = $swap_stream_value;
  return $self;
}

package Device::PanStamp::SwapStream::Value;

use strict;
use warnings;

use Device::PanStamp::protocol::SwapValue;

sub toSwapValue() {
  my $self = shift;
  return Device::PanStamp::protocol::SwapValue->new(
    [
      $self->{received_bytes}, $self->{received_id},
      $self->{send_id}, unpack( "C*", $self->{data} )
    ]
  );
}

sub new($;$$$$) {
  my ( $class, $swap_value, $received_bytes, $received_id, $send_id, $data ) =
    @_;

  if ( defined $swap_value ) {
    my @value = $swap_value->toList();
    return bless {
      received_bytes => $value[0],
      received_id    => $value[1],
      send_id        => $value[2],
      data           => pack( "C*", @value[ 3 .. @value - 1 ] )
    }, $class;
  } else {
    return bless {
      received_bytes => $received_bytes,
      received_id    => $received_id,
      send_id        => $send_id,
      data           => $data
    }, $class;
  }
}

1;
