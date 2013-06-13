package Device::PanStamp::swap::protocol::SwapPacket;

use strict;
use warnings;

use parent qw(Exporter Device::PanStamp::swap::modem::CcPacket);
use Storable qw(dclone);

use Device::PanStamp::swap::protocol::SwapValue;
use Device::PanStamp::swap::protocol::SwapDefs;

our @EXPORT_OK = qw(smart_encrypt_pwd);    # symbols to export on request

#########################################################################
# class SwapPacket(CcPacket):
#
# SWAP packet class
#########################################################################

our $smart_encrypt_pwd = undef;

#########################################################################
# sub smart_encryption
#
# Encrypt/Decrypt packet using the Smart Encryption mechanism
#
# @param password: Smart Encryption password
# @param decrypt:  Decrypt packet if True. Encrypt otherwise
#########################################################################

sub smart_encryption($;$) {
  my ( $self, $password, $decrypt ) = @_;

  $decrypt = 0 unless defined $decrypt;

  my @data = @{ $password->{data} };

  # Update password
  $smart_encrypt_pwd = $password;

  # Encryot SwapPacket and CcPacket fields
  $self->{nonce} ^= $data[9] if $decrypt;

  my $nonce = $self->{nonce};
  $self->{function}   ^= $data[11] ^ $nonce;
  $self->{srcAddress} ^= $data[10] ^ $nonce;
  $self->{regAddress} ^= $data[8] ^ $nonce;
  $self->{regId}      ^= $data[7] ^ $nonce;

  if ( defined $self->{value} ) {
    my $pos      = 0;
    my @newarray = ();
    foreach my $byte ( $self->{value}->toList() ) {
      $byte ^= $data[$pos] ^ $nonce;
      push @newarray, $byte;
      $pos++;
      $pos = 0 if ( $pos eq 11 );
    }
    $self->{value} =
      Device::PanStamp::swap::protocol::SwapValue->new( \@newarray );
  }

  $self->{nonce} ^= $data[9] unless ($decrypt);

  $self->_update_ccdata();
}

#########################################################################
# sub send
#
# Overriden send method
#
# @param server: SWAP server object to be used for transmission
#########################################################################

sub send($) {
  my ( $self, $server ) = @_;

  $self->{srcAddress} = $server->{devaddress};
  @{ $self->{data} }[1] = $self->{srcAddress};

  # Update security option according to server's one
  $self->{security} = $server->{security};
  @{ $self->{data} }[2] |= $self->{security} & 0x0F;

  # Keep copy of the current packet before encryption
  my $packet_before_encrypt = dclone($self);

  # Smart encryption enabled?
  if ( $self->{security} & 0x02 ) {

    # Encrypt packet
    $self->smart_encryption( $server->{password} );
  }

  $self->SUPER::send( $server->{modem} );

  # Notify event
  $server->{_eventHandler}->swapPacketSent($packet_before_encrypt);
}

#########################################################################
# sub _update_ccdata
#
# Update ccPacket data bytes
#########################################################################

sub _update_ccdata() {
  my $self = shift;
  my @data = ();

  push @data, $self->{destAddress};
  push @data, $self->{srcAddress};
  push @data, ( ( $self->{hop} << 4 ) | ( $self->{security} & 0x0F ) );
  push @data, $self->{nonce};
  push @data, $self->{function};
  push @data, $self->{regAddress};
  push @data, $self->{regId};
  push @data, @{ $self->{value} } if ( defined $self->{value} );
  $self->{data} = \@data;
}

#########################################################################
# sub new
#
# Class constructor
#
# @param ccPacket: Raw CcPacket where to take the information from
# @param destAddr: Destination address
# @param hop: Transmission hop count
# @param nonce: Security nonce
# @param function: SWAP function code (see SwapDefs.SwapFunction for more details)
# @param regAddr: Register address (address of the mote where the register really resides)
# @param regId: Register ID
# @param value: Register value
#########################################################################

sub new($$$$$$$$) {

  my (
    $class,    $ccPacket, $destAddr, $hop, $nonce,
    $function, $regAddr,  $regId,    $value
  ) = @_;

  $destAddr = Device::PanStamp::swap::protocol::SwapAddress::BROADCAST_ADDR
    unless defined $destAddr;
  $hop   = 0 unless defined $hop;
  $nonce = 0 unless defined $nonce;
  $function = Device::PanStamp::swap::protocol::SwapFunction::STATUS
    unless defined $function;
  $regAddr = 0 unless defined $regAddr;
  $regId   = 0 unless defined $regId;

  my $self = $class->SUPER::new();

  ## Destination address
  $self->{destAddress} = $destAddr;
  ## Source address
  $self->{srcAddress} = $regAddr;
  ## Hop count for repeating purposes
  $self->{hop} = $hop;
  ## Security option
  $self->{security} = 0;
  ## Security nonce
  $self->{nonce} = $nonce;
  ## Function code
  $self->{function} = $function;
  ## Register address
  $self->{regAddress} = $regAddr;
  ## Register ID
  $self->{regId} = $regId;
  ## SWAP value
  $self->{value} = $value;

  if ( defined $ccPacket ) {
    die "Packet received is too short"
      if ( scalar( @{ $ccPacket->{data} } ) < 7 );

    my @data = @{ $ccPacket->{data} };

    # Superclass attributes
    ## RSSI byte
    $self->{rssi} = $ccPacket->{rssi};
    ## LQI byte
    $self->{lqi} = $ccPacket->{lqi};
    ## CcPacket data field
    $self->{data} = $ccPacket->{data};

    # Destination address
    $self->{destAddress} = $data[0];

    # Source address
    $self->{srcAddress} = $data[1];

    # Hop count for repeating purposes
    $self->{hop} = ( $data[2] >> 4 ) & 0x0F;

    # Security option
    $self->{security} = $data[2] & 0x0F;

    # Security nonce
    $self->{nonce} = $data[3];

    # Function code
    $self->{function} = $data[4];

    # Register address
    $self->{regAddress} = $data[5];

    # Register ID
    $self->{regId} = $data[6];
    $self->{value} = SwapValue->( @data[ 7 .. ( scalar(@data) - 1 ) ] )
      if ( scalar(@data) >= 8 );

    # Encryption enabled?
    if (  ( $self->{security} & 0x02 )
      and ( defined $SwapPacket::smart_encrypt_pwd ) )
    {

      # Decrypt packet (decrypt = 1)
      $self->smart_encryption( $SwapPacket::smart_encrypt_pwd, 1 );
    }
  } else {
    $self->_update_ccdata();
  }
  return $self;
}

#########################################################################
# class SwapStatusPacket
#
# SWAP status packet class
#########################################################################

package Device::PanStamp::swap::protocol::SwapStatusPacket;

use strict;
use warnings;

use parent qw(Exporter Device::PanStamp::swap::protocol::SwapPacket);
use Device::PanStamp::swap::protocol::SwapDefs;

#########################################################################
# sub new
#
# Class constructor
#
# @param rAddr: Register address
# @param rId: Register ID
# @param val: New value
#########################################################################

sub new($$$) {
  my ( $class, $rAddr, $rId, $val ) = @_;

  #SwapPacket->new(ccPacket,destAddr,hop,nonce,function,regAddr,regId,value);
  return $class->SUPER::new( undef, undef, undef, undef, undef, $rAddr, $rId,
    $val );
}

#########################################################################
# class SwapQueryPacket
#
# SWAP Query packet class
#########################################################################

package Device::PanStamp::swap::protocol::SwapQueryPacket;

use strict;
use warnings;

use parent qw(Exporter Device::PanStamp::swap::protocol::SwapPacket);
use Device::PanStamp::swap::protocol::SwapDefs;

#########################################################################
# sub new
#
# Class constructor
#
# @param rAddr: Register address
# @param rId: Register ID
#########################################################################

sub new($$) {
  my ( $class, $rAddr, $rId ) = @_;

  $rAddr = Device::PanStamp::swap::protocol::SwapAddress::BROADCAST_ADDR
    unless defined $rAddr;
  $rId = 0 unless defined $rId;

  #SwapPacket->new(ccPacket,destAddr,hop,nonce,function,regAddr,regId,value);
  return $class->SUPER::new( undef, $rAddr, undef, undef,
    Device::PanStamp::swap::protocol::SwapFunction::QUERY,
    $rAddr, $rId, undef );
}

#########################################################################
# class SwapCommandPacket
#
# SWAP Command packet class
#########################################################################

package Device::PanStamp::swap::protocol::SwapCommandPacket;

use strict;
use warnings;

use parent qw(Exporter Device::PanStamp::swap::protocol::SwapPacket);
use Device::PanStamp::swap::protocol::SwapDefs;

#########################################################################
# sub new Class constructor
#
# @param rAddr: Register address
# @param rId: Register ID
# @param val: New value
# @param nonce: Security nonce
#########################################################################

sub new ($$$;$) {

  my ( $class, $rAddr, $rId, $val, $nonce ) = @_;

  $nonce = 0 unless defined $nonce;

  #SwapPacket->new(ccPacket,destAddr,hop,nonce,function,regAddr,regId,value);
  return $class->SUPER::new( undef, $rAddr, undef, $nonce,
    Device::PanStamp::swap::protocol::SwapFunction::COMMAND,
    $rAddr, $rId, $val );
}

1;
