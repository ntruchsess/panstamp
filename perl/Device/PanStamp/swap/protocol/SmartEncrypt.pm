package Device::PanStamp::swap::protocol::SmartEncrypt;

#########################################################################
# class Password
#
# Encryption password
#########################################################################

#########################################################################
# sub to_string
#
# Convert password (list of bytes) to string
#
# @return password in string format
#########################################################################

sub to_string() {
  my $self = shift;

  # Convert list of bytes to list of strings
  my @strlist = ();
  foreach my $item ( @{ $self->{data} } ) {
    push @strlist, sprintf( "%02X", $item );
  }

  # Convert list of strings to string
  my $strpwd = join( "", @strlist );

  # Return string
  return $strpwd;
}

#########################################################################
# sub new
# Class constructor
#
# @param password: password formated as a list or string
#########################################################################

sub new($) {
  my ( $class, $password ) = @_;

  ## Password bytes
  $self->{data} = [];

  if ( ref($password) eq ARRAY ) {
    @{ $self->{password} } = @$password;
  }
  else {
    for ( my $i = 0 ; $i < length($password) ; $i += 2 ) {
      push @{ $self->{data} }, hex( substr( $password, $i, 2 ) );
    }
  }
}

1;
