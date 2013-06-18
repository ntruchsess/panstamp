use Device::PanStamp::SwapServer;
use Device::PanStamp::SwapInterface;

use constant portname => "/dev/ttyUSB0";

my $server = Handler->new()->create_server();

my $port = Device::SerialPort->new( portname );
  
die "Unable to open serial port" . portname
      unless ( defined $port );
  
$port->baudrate(38400);
$port->databits(8);
$port->parity("none");
$port->stopbits(1);
$port->write_settings;

$server->attach($port,0); #1 to handle port in separate detached thread, 0 run port synchronous on 'poll'

$server->start(1); #1 to handle server in separate detached thread (also polls port), 0 run server synchronous on 'poll'

my $until = time+30;
while (time-$until) {
  select(undef,undef,undef,0.01);
  #$server->poll();
}

$server->stop();

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