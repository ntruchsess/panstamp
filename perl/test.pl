use Device::PanStamp::SwapServer;
use Device::PanStamp::SwapInterface;

my $interface = Handler->new(undef,1,0);

$interface->{server}->start(0);

while (1) {
  select(undef,undef,undef,0.01);
  $interface->{server}->poll();
}

package Handler;

use parent (qw(Device::PanStamp::SwapInterface));

###########################################################
# sub swapServerStarted
#
# SWAP server started successfully
###########################################################

sub swapServerStarted() {
  print "swapServerStarted\n";
}

###########################################################
# sub swapPacketReceived
#
# New SWAP packet received
#
# @param packet: SWAP packet received
###########################################################

sub swapPacketReceived($) {
  print "swapPacketReceived\n";
}

###########################################################
# sub swapPacketSent
#
# SWAP packet transmitted
#
# @param packet: SWAP packet transmitted
###########################################################

sub swapPacketSent($) {
  print "swapPacketSent\n";
}

###########################################################
# sub newMoteDetected($)
#
# New mote detected by SWAP server
#
# @param mote: mote detected
###########################################################

sub newMoteDetected($) {
  print "newMoteDetected\n";
}

###########################################################
# sub newParameterDetected
#
# New configuration parameter detected by SWAP server
#
# @param parameter: Endpoint detected
###########################################################

sub newParameterDetected($) {
  print "newParameterDetected\n";
}

###########################################################
# sub newEndpointDetected
#
# New endpoint detected by SWAP server
#
# @param endpoint: Endpoint detected

###########################################################

sub newEndpointDetected($) {
  print "newEndpointDetected\n";
}

###########################################################
# sub moteStateChanged
#
# Mote state changed
#
# @param mote: Mote having changed
###########################################################

sub moteStateChanged($) {
  my ($self,$mote) = @_;
  print "moteStateChanged\n";
}

###########################################################
# sub moteAddressChanged
#
# Mote address changed
#
# @param mote: Mote having changed
###########################################################

sub moteAddressChanged($) {
  print "moteAddressChanged\n";
}

###########################################################
# sub registerValueChanged
#
# Register value changed
#
# @param register: Register having changed
###########################################################

sub registerValueChanged($) {
  print "registerValueChanged\n";
}

###########################################################
# sub endpointValueChanged
#
# Endpoint value changed
#
# @param endpoint: Endpoint having changed
###########################################################

sub endpointValueChanged($) {
  print "endpointValueChanged\n";
}

###########################################################
# sub parameterValueChanged
#
# Configuration parameter changed
#
# @param parameter: configuration parameter having changed
###########################################################

sub parameterValueChanged($) {
  print "parameterValueChanged\n";
}

1;