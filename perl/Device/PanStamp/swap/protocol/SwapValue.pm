#########################################################################
# class SwapValue
#
# Multi-format SWAP value class
#########################################################################

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
    $val |= $data[$i] << ( $#data -i ) * 8;
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
  return SwapValue->new(@data);
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

my $self = shift;

my @out = ();
foreach my $item ( @{ $self->{_data} } ) {
  push @out, sprintf( "%02X", $item );
}

# Return ASCII string
return join "", @out;

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
      my @data1 = @{$self->{_data}};
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
#########################################################################

sub new(;$) {
  my ( $class, $value, $length ) = @_;
  ## Raw value in form of list

  $length = 0 unless defined $length;
  
  return bless {
    _data => ref($value) eq "ARRAY" ? $value : unpack( "C*", $value ) #TODO unpack is array, not ref to array
  }, $class;
}

1;

        ## Raw value in form of list
        self._data = []
        isAsciiString = False
        if value is not None:
            # In case of list passed in the constructor
            if type(value) is list:
                self._data = value
            # Boolean
            elif type(value) is bool:
                res = int(value)
            # Float
            elif type(value) is float:
                res = int(value*10)
            # In case a string is passed in the constructor
            elif type(value) in [str, unicode]:
                try:
                    # Remove decimal point
                    value = value.replace(".", "")
                    # Convert to integer
                    res = int(value)
                except ValueError:
                    isAsciiString = True
            else:
                res = value

            if isAsciiString:
                # OK, treat value as a pure ASCII string
                strlen = len(value)
                # Truncate string
                if strlen > length:                    
                    value = value[:length]
                # Copy string
                for ch in value:
                    self._data.append(ord(ch))
                # Trailing zeros
                if length > strlen:
                    for i in range(length - strlen):
                        self._data.append(0)
            # In case of integer or long
            elif length > 0 and length <= 4:
                for i in range(length):
                    val = (res >> (8 * (length-1-i))) & 0xFF
                    self._data.append(val)

