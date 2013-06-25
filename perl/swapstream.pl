use Device::PanStamp::SwapServer;
use Device::PanStamp::SwapInterface;

use Time::HiRes qw(tv_interval gettimeofday);

use constant portname => "/dev/ttyUSB0";

my $interface = Handler->new(); 
my $server = $interface->create_server();

my $port = Device::SerialPort->new( portname );
  
die "Unable to open serial port" . portname
      unless ( defined $port );
  
$port->baudrate(38400);
$port->databits(8);
$port->parity("none");
$port->stopbits(1);
$port->write_settings;

$server->attach($port,1); #1 to handle port in separate detached thread, 0 run port synchronous on 'poll'

$server->start(0); #1 to handle server in separate detached thread (also polls port), 0 run server synchronous on 'poll'

my $stream = $interface->{swapstream};

$stream->{destAddress} = 1; 

my $i = 0;
while (1) {
  my @now = gettimeofday();
  while (tv_interval(\@now) < 0.1) {
    select(undef,undef,undef,0.01);
    eval {
      $server->poll();
      $stream->transmit();
    };
    if ($@) {
      print "communication error: $@\n";
    }
  }
  if ($stream->available()) {
    print "read ".length ($stream->read(1024))." bytes\n";
  }
  $stream->write("Hallo $i\n");
  $i++;
}

$server->stop();

package Handler;

use parent (qw(Device::PanStamp::SwapInterface));
use Device::PanStamp::SwapStream;
use Data::Dumper;

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
#  print "swapPacketReceived\n";
  my ($self,$packet) = @_;
#  print Dumper($packet);
#  $self->{swapstream}->swapPacketReceived($packet);
}

###########################################################
# sub swapPacketSent
#
# SWAP packet transmitted
#
# @param packet: SWAP packet transmitted
###########################################################

sub swapPacketSent($) {
#  print "swapPacketSent\n";
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
  my ($self,$mote) = @_;
#  print Dumper($mote);
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
  my ($self,$parameter) = @_;
#  print Dumper($parameter);
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
  my ($self,$endpoint) = @_;
#  print Dumper($endpoint);
}

###########################################################
# sub moteStateChanged
#
# Mote state changed
#
# @param mote: Mote having changed
###########################################################

sub moteStateChanged($) {
  print "moteStateChanged\n";
  my ($self,$mote) = @_;
#  print Dumper($mote);
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
  my ($self,$mote) = @_;
#  print Dumper($mote);
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
  my ($self,$register) = @_;
  $self->{swapstream}->registerValueChanged($register);
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

sub new() {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{swapstream} = Device::PanStamp::Stream->new($self);
  return $self;
}

1;