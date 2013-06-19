package Device::PanStamp::Stream;

use strict;
use warnings;

use Carp;

use Device::PanStamp::protocol::SwapPacket;

use constant PANSTREAM_MAXDATASIZE => 55;
use constant PANSTREAM_BUFFERSIZE => 1024;
use constant PANSTREAM_REGISTER_ID => 11;

sub swapPacketReceived($) {
  my ($self,$packet) = @_;
  
  ## Source address
  $packet->{srcAddress};
  ## Hop count for repeating purposes
  $packet->{hop};
  ## Security option
  $packet->{security};
  ## Security nonce
  $packet->{nonce};
  ## Function code
  $packet->{function};
  ## Register address
  $packet->{regAddress};
  
  #ignore packets not for this device
  return unless ( $packet->{destAddress} eq $self->{devAddress} );
  
  #ignore packets not for the stream register
  return unless ( $packet->{regId} eq $self->{regId} );

  my $stream_packet = Device::PanStamp::SwapStream::SwapStreamPacket->new($packet);
  
  my $send = 0;
  
  #previous packet acknowledged by master -> prepare new packet send data
  if ($received_id eq $self->{send_id}) {
    
    # discard data of previous packet
    my $remaining_bytes = $self->{send_len} - $received_bytes;
    
    for (my $i = 0; $i < $remaining_bytes; $i++) {
      $self->{send_buffer}->[$i] = $self->{send_buffer}->[$received_bytes+$i];
    }
    my $send_len = $remaining_bytes;
    $self->{num_bytes} = $remaining_bytes > PANSTREAM_MAXDATASIZE ? PANSTREAM_MAXDATASIZE : $remaining_bytes;

    if ($remaining_bytes > 0) {
      my $self->{id}++;
      if ($self->{id}>255) {
        $self->{id} = 1;
      }
      $self->{send_id} = $self->{id};
      $send = 1;
    } else {
      $self->{send_id} = 0;
    }
  } else {
    # last packet not acknowledged -> send last packet data unaltered.
    $send = 1;
  }
  if ($send_id ne 0) {
    # new packet received (not a retransmit of a previously retrieved packet)
    if ($send_id ne $self->{master_id}) { 
      $self->{master_id} = $send_id;
      # acknowledge number of bytes transfered to receive_buffer
      my $receive_bytes = 
        ($num_bytes + $self->{receive_len} > PANSTREAM_BUFFERSIZE) ? PANSTREAM_BUFFERSIZE - $self->{receive_len} : $num_bytes;
      $self->{send_message}->{received_bytes} = $receive_bytes;

      for (my $i = 0; $i < $receive_bytes; $i++) {
        $self->{receive_buffer}->[($self->{receive_pos} + $self->{receive_len} + $i) % PANSTREAM_BUFFERSIZE] = $value[$i];
      }
      $self->{receive_len}+=$receive_bytes;
      
      #acknowledge package
      $self->{received_id} = $self->{master_id};
    }
    # if packet data was received before (received->send_id==master_id), acknowledge again
    $send = 1;
  }
  if ($send) {
    $self->sendSwapStatus();
  }
}

package Device::PanStamp::SwapStream::SwapStreamPacket;

use strict;
use warnings;

use parent qw(Device::PanStamp::protocol::SwapPacket);
use Device::PanStream::SwapStream;

sub new($;$$$$$) {
  my ( $class, $arg, $regAddress, $regId, $received_bytes, $received_id, $send_id, $data ) = @_;

  if (ref($arg) eq "Device::PanStamp::protocol::SwapPacket") {
    
    my @value = $arg->{value}->toList();
    $arg->{stream_received_bytes} = $value[0];   
    $arg->{stream_received_id} = $value[1];
    $arg->{stream_send_id} = $value[2];
    $arg->{stream_data} = pack ("A*", @value[3..@value-1]);
  
    return bless $arg,$class;
  } else {
    return $class->SUPER::new($arg,$regAddress,$regId,[$received_bytes,$received_id,$send_id,unpack ("A*",$data)]);
  }
}

1;



















sub new() {
  my $class = shift;
  return bless {}, $class;
}

sub TIEHANDLE {
    my $class = shift;
    my $fh    = shift;
    my $self  = {
        fh          => $fh,
        read_length => 1024,
        separator   => undef,
        buffer      => '',
        die_on_anchors => 1,
        @_
    };
    bless $self => $class;
}

sub READ {
    croak if @_ < 3;
    my $self   = shift;
    my $bufref = \$_[0];
    $$bufref = '' if not defined $$bufref;
    my ( undef, $len, $offset ) = @_;
    $offset = 0 if not defined $offset;
    if ( length $self->{buffer} < $len ) {
        my $bytes = 0;
        while ( $bytes = $self->fill_buffer()
                and length( $self->{buffer} ) < $len )
        { }

        if ( not $bytes ) {
            my $length_avail = length( $self->{buffer} );
            substr( $$bufref, $offset, $length_avail,
                    substr( $self->{buffer}, 0, $length_avail, '' ) );
            return $length_avail;
        }

        # only reached if buffer long enough.
    }
    substr( $$bufref, $offset, $len, substr( $self->{buffer}, 0, $len, '' ) );
    return $len;
}
#    READ this, scalar, length, offset
#    READLINE this
#    GETC this
#    WRITE this, scalar, length, offset
#    PRINT this, LIST
#    PRINTF this, format, LIST
#    BINMODE this
#    EOF this
#    FILENO this
#    SEEK this, position, whence
#    TELL this
#    OPEN this, mode, LIST
#    CLOSE this
#    DESTROY this
#    UNTIE this

1;
