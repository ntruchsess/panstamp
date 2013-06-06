package Device::PanStamp::swap::SwapInterface;

use SwapServer qw(SwapServer);

###########################################################
# SWAP Interface superclass. Any SWAP application should derive from this one
###########################################################

###########################################################
# sub swapServerStarted
#
# SWAP server started successfully
###########################################################

sub swapServerStarted() {

}

###########################################################
# sub swapPacketReceived
#
# New SWAP packet received
#
# @param packet: SWAP packet received
###########################################################

sub swapPacketReceived($) {

}

###########################################################
# sub swapPacketSent
#
# SWAP packet transmitted
#
# @param packet: SWAP packet transmitted
###########################################################

sub swapPacketSent($) {

}

###########################################################
# sub newMoteDetected($)
#
# New mote detected by SWAP server
#
# @param mote: mote detected
###########################################################

sub newMoteDetected($) {

}

###########################################################
# sub newParameterDetected
#
# New configuration parameter detected by SWAP server
#
# @param parameter: Endpoint detected
###########################################################

sub newParameterDetected($) {

}

###########################################################
# sub newEndpointDetected
#
# New endpoint detected by SWAP server
#
# @param endpoint: Endpoint detected

###########################################################

sub newEndpointDetected($) {

}

###########################################################
# sub moteStateChanged
#
# Mote state changed
#
# @param mote: Mote having changed
###########################################################

sub moteStateChanged($) {

}

###########################################################
# sub moteAddressChanged
#
# Mote address changed
#
# @param mote: Mote having changed
###########################################################

sub moteAddressChanged($) {

}

###########################################################
# sub registerValueChanged
#
# Register value changed
#
# @param register: Register having changed
###########################################################

sub registerValueChanged($) {

}

###########################################################
# sub endpointValueChanged
#
# Endpoint value changed
#
# @param endpoint: Endpoint having changed
###########################################################

sub endpointValueChanged($) {

}

###########################################################
# sub parameterValueChanged
#
# Configuration parameter changed
#
# @param parameter: configuration parameter having changed
###########################################################

sub parameterValueChanged($) {

}

###########################################################
# sub getNbOfMotes
#
# @return the amount of motes available in lstMotes
###########################################################

sub getNbOfMotes() {

}

###########################################################
# sub getMote
#
# Return mote from list
#
# @param index: Index of the mote within lstMotes
# @param address: SWAP address of the mote
# @return mote
###########################################################

sub getMote(;$$) {
  my ( $self, $index, $address ) = @_;
  return $self->{server}->{network}->get_mote( $index, $address );
}

###########################################################
# sub setMoteRegister
#
# Set new register value on wireless mote
#
# @param mote: Mote targeted by this command
# @param regId: Register ID
# @param value: New register value
#
# @return True if the command is correctly ack'ed. Return False otherwise
###########################################################

sub setMoteRegister($$$) {
  my ( $self, $mote, $regId, $value ) = @_;
  return $self->{server} . > setMoteRegister( $mote, $regId, $value );
}

###########################################################
# sub queryMoteRegister
#
# Query mote register, wait for response and return value
#
# Non re-entrant method!!
#
# @param mote: Mote to be queried
# @param regID: Register ID
# @return register value
###########################################################

sub queryMoteRegister($$) {
  my ( $self, $mote, $regId ) = @_;
  return self . server . queryMoteRegister( mote, regId );
}

###########################################################
# sub create_server
#
# Create server object
###########################################################

sub create_server() {
  my $self = shift;
  self->{server} =
    Device::PanStamp::swap::SwapServer->new( $self, $self->{verbose} );
  return $self->{server};
}

###########################################################
# sub start_server
#
# Start SWAP server
###########################################################

sub start_server() {
  my $self = shift;
  $self->{server}->start();
}

###########################################################
# sub stop
#
# Stop SWAP server
###########################################################

sub stop() {
  my $self = shift;
  $self->{server}->stop();
}

###########################################################
# sub get_endpoint
#
# Get endpoint given its unique id or location.name pair
#
# @param endpid endpoint id
# @param location endpoint location
# @param name endpoint name
#
# @return endpoint object
###########################################################

sub get_endpoint(;$$$) {
  my ( $self, $endpid, $location, $name ) = @_;
  foreach my $mote ( @{ $self->{network}->{motes} } ) {
    foreach my $register ( @{ $mote->{regular_registers} } ) {
      foreach my $endpoint ( @{ $register->{parameters} } ) {
        if (
          defined $endpid and $endpid eq $endpoint->{id}
          or (  defined $name
            and defined $location
            and $name eq $endpoint->{name}
            and $location eq $endpoint->{location} ) {
            return $endpoint;
            };
        }
      }
    }
    return undef;
  }

###########################################################
# sub update_definition_files
#
# Update Device Definition Files from Internet server
###########################################################

sub update_definition_files() {
  my $self = shift;        
  $self->{server}->update_definition_files();
}

###########################################################
# sub new
#
# Class constructor
#
# @param settings: path to the main configuration file
# @param verbose: Print out SWAP frames
# @param start: Start SWAP server if True
###########################################################

sub new(;$$) {
  my ($class, $settings, $start) = @_;

  $start = 1 unless (defined $start);
  ## SWAP server
  my $self = {};
  
  if ($start) {
    print "SWAP server starting... ";
    $self->{server} = Device::PanStamp::swap::SwapServer->new($self, $settings, $start);
    $self->{network} = $self->{server}->{network};
    if ($start) print "SWAP server is now running... ";
  }
  return bless $self,$class;
}

1;