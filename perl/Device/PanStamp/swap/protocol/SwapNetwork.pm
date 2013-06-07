use SwapMote;
use JSON qw(decode_json encode_json);

#########################################################################
# class SwapNetwork
#
# Container of SWAP network data
#########################################################################

#########################################################################
# sub read
#
# Read initial network data from file
#########################################################################

sub read() {
  my $self = shift;

  # Clear current list of motes:
  $self->clear();

  open NETWORK_FILE, "<", $self->{filename} or die $!;
  my @lines = <NETWORK_FILE>;
  close <NETWORK_FILE>;
  my $json = decode_json( join( "", @lines ) );
  my $network_data = $json->{network};

  # Initialize list of motes
  foreach my $mote_data ( @{ $network_data->{motes} } ) {
    my $mote =
      SwapMote->new( $self->{server}, $mote_data->{pcode},
      $mote_data{address} );
    push @{ $self->{motes} }, $mote;

    # Initialize endpoints belonging to this mote
    foreach my $register ( @{ $mote->{regular_registers} } ) {

      # Find register config
      foreach my $register_data ( @{ $mote_data->{registers} } ) {
        if ( $register_data->{id} eq $register->{id} ) {
          foreach my $endpoint ( @{ $register->{parameters} } ) {

            # Find endpoint config
            foreach my $endpoint_data ( @{ $register_data->{endpoints} } ) {
              if ( $endpoint_data->{id} eq $endpoint{id} ) {
                $endpoint->{name}     = $endpoint_data->{name};
                $endpoint->{location} = $endpoint_data->{location};
                $endpoint->setUnit( $endpoint_data->{unit} )
                  if (defined $endpoint_data->{unit}
                  and defined $endpoint->{unit} );
                $endpoint->setValue( $endpoint_data->{value} )
                  if ( defined $endpoint_data->{value} );
                $endpoint->{direction} = $endpoint_data->{direction};
                $endpoint->{type}      = $endpoint_data->{type};

                $endpoint->{display} = 1;
                if ( defined $endpoint_data->{display} ) {
                  my $display = lc( $endpoint_data->{display} );
                  if ( grep { $_ eq $display },
                    ( "false", "no", 0, "0", "disabled" ) )
                  {
                    $endpoint->{display} = 0;
                  }
                }
                last;
              }
            }
          }
          last;
        }
      }
    }
  }
}

#########################################################################
# sub save
#
# Save current network data into file
#########################################################################

sub save() {
  my $self = shift;

  my $network = $self->dumps();
  print "Saving" . $self->{filename} open NETWORK_FILE, ">", $self->{filename};
  print NETWORK_FILE encode_json($network);
  close NETWORK_FILE;
}

#########################################################################
#sub add_mote
#
# Add mote to the network
#
# @param mote: SWAP mote to be added
#
# @return true if the mote did not exist in the list. False otherwise
#########################################################################

sub add_mote($) {
  my ( $self, $mote ) = @_;

  my $address = $mote->{address};

  # Search mote in list
  return 0 if ( grep { $address eq $_->{address} }, @{ $self->{motes} } );

  push @{ $self->{motes} }, $mote;
  return 1;
}

#########################################################################
# sub delete_mote
#
# Delete mote from network
#
# @param address: address of the mote to be removed
#########################################################################

sub delete_mote($) {
  my ( $self, $address ) = @_;

  my @removed = grep { $address ne $_->{address} } @{ $self->{motes} };
  if ( scalar @{ $self->{motes} } gt scalar(@removed) ) {
    $self->{motes} = \@removed;
    $self->save();
  }
}

#########################################################################
# sub get_mote
#
# Return mote from list given its index or address
#
# @param index: Index of hte mote within lstMotes
# @param address: Address of the mote
#
# @return mote
#########################################################################

sub get_mote(;$$) {
  my ( $self, $index, $address ) = @_;

  return $self->{motes}->{$index} if ( defined $index and $index >= 0 );

  if ( defined $address and $address > 0 and $address <= 255 ) {
    my @found = grep { $_->{address} eq $address } @{ $self->{motes} };
    return shift @found if (@found);
  }
  return undef;
}

#########################################################################
# sub get_nbof_motes
#
# Return number of motes available in the network
#
# @return amount of motes
#########################################################################

sub get_nbof_motes() {
  my $self = shift;
  return scalar( @{ $self->{motes} } );
}

#########################################################################
# sub get_endpoint
#
# Get endpoint given its user name and location
#
# @param usrlocation: user location
# @param usrname: user name
#
# @return endpoint object
#########################################################################

sub get_endpoint(;$$) {
  my ( $self, $usrlocation, $usrname ) = @_;

  return undef unless ( defined $userlocation and defined $usrname );

  foreach my $mote ( @{ $self->{motes} } ) {
    foreach my $reg ( @{ $mote->{regular_registers} } ) {
      foreach my $endp ( @{ $reg->{parameters} } ) {
        return $endp
          if ($endp->{usrlocation} eq $usrlocation
          and $endp->{usrname} eq $usrname );
      }
    }
  }
  return undef;
}

#########################################################################
# sub clear
#
# Clear list of motes
#########################################################################

sub clear() {
  my $self = shift;
  $self->{motes} = [];
}

#########################################################################
# sub dumps
#
# Serialize network data to a JSON formatted string
#########################################################################

sub dumps() {
  my $self = shift;

  my @motes_data = ();

  foreach my $mote ( @{ $self->{motes} } ) {
    push @motes_data, $mote->dumps(1);    # include_units=1
  }

  return {
    network => {
      name  => "SWAP",
      motes => \@motes_data
    }
  };
}

#########################################################################
# sub new
#
# Class constructor
#
# @param filename: Name fo the SWAP network file
#########################################################################

sub new($;$) {
  my ( $class, $server, $filename ) = @_;

  my $filename = "swapnet.json" unless ( defined $filename );

  my $self = bless {
    ## SWAP server
    server => $server,

    ## File name
    filename => $filename,

    ## List of mote objects
    motes => []
  }, $class;

  # Read config file
  $self->read();
}

1;
