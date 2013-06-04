
package main;

use strict;
use warnings;

use constant PANSTREAM_MAXDATASIZE => 32;

sub
SWAP_00000022FFFFFFFF_Initialize($)
{
  my ($hash) = @_;

  require "$attr{global}{modpath}/FHEM/34_SWAP.pm";

  $hash->{SWAP_SetFn}     = "SWAP_00000022FFFFFFFF_Set";
  $hash->{SWAP_SetList}   = { send => -99, flush => 0,
                              showSendBuffer => 0, clearSendBuffer => 0,
                              reset => 0 };
  $hash->{SWAP_GetFn}     = "SWAP_00000022FFFFFFFF_Get";
  $hash->{SWAP_GetList}   = { received => 0, };
  $hash->{SWAP_ParseFn}   = "SWAP_00000022FFFFFFFF_Parse";

  my $ret = SWAP_Initialize($hash);

  return $ret;
}

sub
getStream($$)
{
  my ($hash,$reg) = @_;

  my $stream_name = '.stream-'.$reg;
  if( !defined($hash->{$stream_name}) ) {
    my %stream;

    $stream{id} = 0;

    $stream{received_bytes} = 0;
    $stream{received_id} = 0;
    $stream{send_id} = 0;
    $stream{data} = "";

    $stream{received} = "";

    $hash->{$stream_name} = \%stream;
  }

  return $hash->{$stream_name};
}

sub
SWAP_00000022FFFFFFFF_SendStreamPacket($$)
{
  my ($hash,$reg) = @_;
  my $stream = getStream($hash,$reg);

  my $msg = sprintf( "%02X", $stream->{received_bytes});
    $msg .= sprintf( "%02X", $stream->{received_id});

  my $num_bytes = length($stream->{data});
  $num_bytes = PANSTREAM_MAXDATASIZE if( $num_bytes > PANSTREAM_MAXDATASIZE );
  if( $stream->{send_id} && $num_bytes ) {
    $msg .= sprintf( "%02X", $stream->{send_id} );
    for( my $i = 0; $i < $num_bytes; ++$i) {
      $msg .= sprintf( "%02X", ord(substr($stream->{data},$i,1)) );
    }
  } else {
    $msg .= "00";
  }

  Log 3, "FF01000000FF0B". $msg;
  SWAP_Send($hash, $hash->{addr}, "00", $reg, $msg);
}

sub
SWAP_00000022FFFFFFFF_Parse($$$$)
{
  my ($hash, $reg, $func, $data) = @_;
  my $name = $hash->{NAME};

  $hash->{reg} = "0B";
  if( $reg == hex($hash->{reg}) ) {
    foreach my $endpoint (@{$hash->{product}->{registers}->{$reg}->{endpoints}}) {
      if( $endpoint->{type} == STREAM ) {
        my $stream= getStream($hash,$hash->{reg});

        my $received_bytes = substr($data, 0, 2);
        my $received_id = substr($data, 2, 2);
        my $send_id = substr($data, 4, 2);
        my $decoded;
        for( my $i = 0; $i < length($data)-6; $i+=2 ) {
          $decoded .= sprintf( "%c", hex(substr($data, 6+$i, 2) ) );
        }

Log 3, "received_bytes: ". $received_bytes;
Log 3, "received_id:    ". $received_id;
Log 3, "send_id:        ". $send_id;
Log 3, $decoded if( $decoded );

        my $send = 0;
        $received_id = hex($received_id);
        if( $received_id
           && $received_id == $stream->{send_id}) { #previous packet acknowledged by master -> prepare new packet send data
          $stream->{data} = substr($stream->{data},hex($received_bytes));
          if( length($stream->{data}) ) {
            $stream->{id}++;
            $stream->{id} &= 0xff;
            $stream->{id} = 1 if( !$stream->{id} );
            $stream->{send_id} = $stream->{id};
            $send = 1;
          } else {
            $stream->{send_id} = 0;
          }
        } else {
          #last packet not acknowledged -> send last packet data unaltered.
          $send = 1;
        }

        $send_id = hex($send_id);
        if( $send_id != 0) {
          if( $send_id!=$stream->{received_id}) { #new packet received (not a retransmit of a previously retrieved packet)
            $stream->{received_bytes} = length($data)/2-3;
            $stream->{received_bytes} &= 0xff;
            $stream->{received_id} = $send_id; #acknowledge package
          }
          # if packet data was received before (received->received_id==send_id), acknowledge again
          $send = 1;
        }

        $stream->{received} .= $decoded if( $decoded );
        my $value = $stream->{received};

        SWAP_00000022FFFFFFFF_SendStreamPacket($hash,$hash->{reg}) if( $send );
      }
    }
  }
}

sub
flush($$)
{
  my ($hash) = @_;
  my $stream = getStream($hash,$hash->{reg});

  if( !$stream->{send_id} && length($stream->{data}) ) {
    $stream->{id}++;
    $stream->{id} &= 0xff;
    $stream->{id} = 1 if( !$stream->{id} );
    $stream->{send_id} = $stream->{id};
    SWAP_00000022FFFFFFFF_SendStreamPacket($hash,$hash->{reg});
  }
}

sub
SWAP_00000022FFFFFFFF_Set($@)
{
  my ($hash, $name, $cmd, @args) = @_;

  my $stream = getStream($hash,$hash->{reg});
  if( $cmd eq "send" ) {
    foreach my $arg (@args) {
      $stream->{data} .= ' ' if( $stream->{data} );
      $stream->{data} .= $arg;
    }
    flush($hash,$hash->{reg}) if( length($stream->{data}) >= PANSTREAM_MAXDATASIZE );
  } elsif( $cmd eq "flush" ) {
    flush($hash,$hash->{reg});
  } elsif( $cmd eq "showSendBuffer" ) {
    my $ret;
    $ret .= "  id:      ". $stream->{id} ."\n";
    $ret .= "  send_id: ". $stream->{send_id} ."\n";
    $ret .= "  data:    ". $stream->{data};
    return (undef, $ret );
  } elsif( $cmd eq "clearSendBuffer" ) {
    $stream->{id} = 0;
    $stream->{send_id} = 0;
    $stream->{data} = "";
  }

  return undef;
}

sub
SWAP_00000022FFFFFFFF_Get($@)
{
  my ($hash, $name, $cmd, @a) = @_;

  my $stream = getStream($hash,$hash->{reg});
  if( $cmd eq 'received' ) {
    my $ret =  $stream->{received};
    $stream->{received} = "";
    return $ret;
  }

  return undef;
}

1;
