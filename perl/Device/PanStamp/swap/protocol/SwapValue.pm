#########################################################################
# class SwapValue
#
# Multi-format SWAP value class
#########################################################################

package Device::PanStamp::swap::protocol::SwapValue;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

#########################################################################
# sub getLength
#
# Get data length
#
# @return Length in bytes of the current value
#########################################################################

sub getLength() {
  my $self = shift;
  return scalar @{ $self->{_data} };
}

#########################################################################
# sub toInteger
#
# Convert SWAP value into number
#
# @return Current value in integer format
#########################################################################

sub toInteger() {
  my $self = shift;
  my $val  = 0;
  my @data = @{ $self->{_data} };
  foreach my $i ( 0 .. $#data ) {
    $val |= $data[$i] << ( $#data -$i ) * 8;
  }
  return $val;
}

#########################################################################
# sub clone
#
# Get a copy of the current value
#
# @return Copy of the current value
#########################################################################

sub clone() {
  my $self = shift;
  my @data = @{ $self->{_data} };
  return Device::PanStamp::swap::protocol::SwapValue->new(\@data);
}

#########################################################################
# sub toAscii
#
# Convert SWAP value into ASCII string. Use this function for sequences of integer numbers
#
# @return Current value in ASCII format
#########################################################################

sub toAscii() {
  my $self = shift;
  return join( "", @{ $self->{_data} } );
}

#########################################################################
# sub toAsciiStr
#
# Convert SWAP value into readable ASCII string. Use this function for real ASCII strings
#
# @return
#########################################################################

sub toAsciiStr() {
  my $self = shift;
  return pack "A*", @{ $self->{_data} };
}

#########################################################################
# sub toAsciiHex
#
# Convert SWAP value into printable ASCII hex string. Use this function for sequences of
# integer numbers
#########################################################################

sub toAsciiHex() {
  my $self = shift;
  my @out  = ();
  foreach my $item ( @{ $self->{_data} } ) {
    push @out, sprintf( "%02X", $item );
  }

  # Return ASCII string
  return join "", @out;
}
#########################################################################
# sub toList
#
# Convert SWAP value into list
#
# @return Current value as a list of bytes
#########################################################################

sub toList() {
  my $self = shift;

  return @{ $self->{_data} };
}

#########################################################################
# sub isEqual
#
# Compare current value with the one passed as argument
#
# @param value: Value to be compared agains the current one
#
# @return 1 if the value passed as argument is equal to the current one. Return 0
# otherwise
#########################################################################

sub isEqual($) {
  my ( $self, $value ) = @_;

  if ( defined $value ) {
    if ( $self->getLength() eq $value->getLength() ) {
      my @data1 = @{ $self->{_data} };
      my @data2 = $value->toList();
      foreach my $i ( 0 .. $#data1 ) {
        return 0 if ( $data1[$i] ne $data2[$i] );
      }
      return 1;
    }
  }
  return 0;
}

#########################################################################
# sub new
#
# Class constructor
#
# @param value: Raw value in form of list or string
# @param length: byte length of the value
# @param template: perl 'unpack' template to read value byte data from string
#########################################################################

sub new(;$$$) {
  my ( $class, $value, $length, $template ) = @_;

  # no value:
  return bless { _data => [] }, $class unless defined $value;

  # Raw value in form of list:
  return bless { _data => $value }, $class if ( ref($value) eq "ARRAY" );

  # template supplied:
  return bless { _data => unpack( $template, $value ) }, $class
    if ( defined $template );

  # default length = 0:
  return bless { _data => [] }, $class unless defined $length;
  my $res;

  #Boolean or int
  if ( $value =~ /^[01]$/ or $value =~ /^\d+$/ ) {
    $res = $value;

    #Float
  } elsif ( $value =~ /^\d+\.\d*$/ ) {
    $res = int( $value * 10 );

    #just Numbers and dots, remove dots
  } elsif ( $value =~ /^\d[\d.]*$/ ) {
    $res = ( $value =~ s/\.//gr );

    #ascii string
  } else {
    return bless {
      _data => unpack "a" x $length,
      substr( $value, 0, $length )
    }, $class;
  }
  my @data = ();
  if ( $length > 0 and $length <= 4 ) {
    foreach my $i ( 0 .. $length ) {
      push @data, ( $res >> ( 8 * ( $length - 1 - $i ) ) ) & 0xFF;
    }
  }
  return bless { _data => \@data }, $class;
}

1;
