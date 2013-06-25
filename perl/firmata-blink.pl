#!/usr/bin/perl

use strict;
use lib '../lib';
use Data::Dumper;
use Device::Firmata::Constants qw/ :all /;
use Device::Firmata;
use Device::Firmata::Platform;

use Device::PanStamp::SwapServer;
use Device::PanStamp::SwapInterface;

$Device::Firmata::DEBUG = 1;
use Time::HiRes qw(tv_interval gettimeofday sleep);

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

my $led_pin = 4;

my $io = FirmataIO->new($stream);
my $device = Device::Firmata::Platform->attach($io) or die "Could not connect to Firmata Server";

$device->system_reset();
$device->probe();

print $device->{metadata}{firmware}.", ".$device->{metadata}{firmware_version}."\n";

$device->pin_mode($led_pin=>PIN_OUTPUT);

my $iteration = 0;

while (1) {
  my @now = gettimeofday();
  my $strobe_state = $iteration++%2;
  $device->digital_write($led_pin=>$strobe_state);
  while (tv_interval(\@now) < 5) {
    select(undef,undef,undef,0.01);
    eval {
      $device->poll();
    };
    if ($@) {
      print "communication error: $@\n";
    }
  }
}

package FirmataIO;

use strict;
use warnings;

sub data_write {
    my ( $self, $buf ) = @_;
    $Device::Firmata::DEBUG and print ">".join(",",map{sprintf"%02x",ord$_}split//,$buf)."\n";
    my $ret = $self->{stream}->write( $buf );
    $self->{stream}->flush();
    return $ret;
}

sub data_read {
    my ( $self, $bytes ) = @_;
    $self->{stream}->transmit();
    $self->{stream}->{interface}->poll_server();
    my ( $count, $string ) = $self->{stream}->read($bytes);
    if ( $Device::Firmata::DEBUG and $string ) {
        print "<$count:".join(",",map{sprintf"%02x",ord$_}split//,$string)."\n";
    }
    return $string;
}

sub new($) {
	my ( $class, $stream ) = @_;
	return bless {
		stream => $stream
	}, $class;
}

package Handler;

use strict;
use warnings;
use parent (qw(Device::PanStamp::SwapInterface));
use Device::PanStamp::SwapStream;

sub registerValueChanged($) {
  my ($self,$register) = @_;
  $self->{swapstream}->registerValueChanged($register);
}

sub new() {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{swapstream} = Device::PanStamp::Stream->new($self);
  return $self;
}

1;