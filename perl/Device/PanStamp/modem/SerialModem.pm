###########################################################
#    Class representing a serial panstamp modem
###########################################################

package Device::PanStamp::modem::SerialModem;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Device::PanStamp::modem::CcPacket;
use Device::PanStamp::modem::SerialPort;

use constant {

  # Serial modes
  DATA    => 0,
  COMMAND => 1
};

###########################################################
# sub start()
#
# Start serial gateway
###########################################################

sub start() {

  my $self = shift;

  # Run serial port thread
  $self->{_serport}->start();

  $self->{_wait_modem_start} = 0;
  my $start      = time;
  my $soft_reset = 0;
  while ( !$self->{_wait_modem_start} ) {
    $self->poll();
    my $elapsed = time - $start;
    if ( not $soft_reset and $elapsed > 5 ) {
      $self->reset();
      $soft_reset = 1;
    } elsif ( $soft_reset and $elapsed > 10 ) {
      die "Unable to reset serial modem";
    }
  }

  # Retrieve modem settings
  # Switch to command mode
  die("Modem is unable to enter command mode")
    unless $self->goToCommandMode();

  # Hardware version
  my $response = $self->runAtCommand("ATHV?\r");
  die "Unable to retrieve Hardware Version from serial modem"
    unless defined $response;
  $self->{hwversion} = hex($response);

  # Firmware version
  $response = $self->runAtCommand("ATFV?\r");
  die "Unable to retrieve Firmware Version from serial modem"
    unless defined $response;
  $self->{fwversion} = hex($response);

  # Frequency channel
  $response = $self->runAtCommand("ATCH?\r");
  die "Unable to retrieve Frequency Channel from serial modem"
    unless defined $response;

  # Frequency channel of the serial gateway
  $self->{freq_channel} = hex($response);

  # Synchronization word
  $response = $self->runAtCommand("ATSW?\r");
  die "Unable to retrieve Synchronization Word from serial modem"
    unless defined $response;

  # Synchronization word of the serial gateway
  $self->{syncword} = hex($response);

  # Device address
  $response = $self->runAtCommand("ATDA?\r");
  die "Unable to retrieve Device Address from serial modem"
    unless defined $response;

  # Device address of the serial gateway
  $self->{devaddress} = hex($response);

  # Switch to data mode
  $self->goToDataMode();
}

###########################################################
# sub stop()
#
# Stop serial gateway
###########################################################

sub stop() {
  my $self = shift;
  $self->{serport}->stop() if $self->{serport};
}

###########################################################
# sub poll
#
# Poll Modem synchronous (if not running async)
###########################################################

sub poll() {
  my $self = shift;
  if ( $self->{async} ) {
    $self->{_serport}->receive();
  } else {
    $self->{_serport}->poll();
  }
}

###########################################################
# sub _serialPacketReceived($)
#
# Serial packet received. This is a callback function called from
# the SerialPort object
#
# @param buf: Serial packet received in String format
###########################################################

sub _serialPacketReceived($) {
  my ( $self, $buf ) = @_;

  # If modem in command mode
  if ( $self->{_sermode} eq COMMAND ) {
    $self->{_atresponse}          = $buf;
    $self->{_atresponse_received} = 1;

    # If modem in data mode
  } else {

    # Waiting for ready signal from modem?
    if ( not $self->{_wait_modem_start} ) {
      if ( $buf eq "Modem ready!" ) {
        $self->{_wait_modem_start} = 1;

        # Create CcPacket from string and notify reception
      }
    } elsif ( defined $self->{_ccpacket_received} ) {
      my $ccPacket = Device::PanStamp::modem::CcPacket->new($buf);
      &{ $self->{_ccpacket_received} }($ccPacket);
    }
  }
}

###########################################################
# sub setRxCallback($)
#
# Set callback reception function. Notify new CcPacket reception
#
# @param cbFunct: Definition of custom Callback function for the reception of packets
###########################################################

sub setRxCallback($) {
  my ( $self, $cbFunct ) = @_;

  $self->{_ccpacket_received} = $cbFunct;
}

###########################################################
# sub goToCommandMode()
#
# Enter command mode (for AT commands)
#
# @return True if the serial gateway does enter Command Mode. Return false otherwise
###########################################################

sub goToCommandMode() {
  my $self = shift;

  my $sermode = $self->{_sermode};
  return 1 if ( $$sermode eq COMMAND );

  $$sermode = COMMAND;
  my $response = $self->runAtCommand( "+++", 5000 );

  return 1 if ( defined $response and $response =~ /^OK/ );

  $$sermode = DATA;
  return 0;
}

###########################################################
# sub goToDataMode()
#        Enter data mode (for Rx/Tx operations)
#
#        @return True if the serial gateway does enter Data Mode. Return false otherwise
###########################################################

sub goToDataMode() {
  my $self = shift;

  my $sermode = $self->{_sermode};
  return 1 if ( $$sermode eq DATA );

  my $response = $self->runAtCommand("ATO\r");

  if ( defined $response and $response =~ /^OK/ ) {
    $$sermode = DATA;
    return 1;
  }
  return 0;
}

###########################################################
# sub reset()
#
# Reset serial gateway
#
# @return True if the serial gateway is successfully restarted
##########################################################

sub reset() {
  my $self = shift;

  # Switch to command mode if necessary
  my $sermode = $self->{_sermode};
  if ( $$sermode eq DATA ) {
    $self->goToCommandMode();
  }

  # Run AT command
  my $response = $self->runAtCommand("ATZ\r");
  if ( defined $response and $response =~ /^OK/ ) {
    $$sermode = DATA;
    return 1;
  }

  return 0;
}

##########################################################
# sub runAtCommand(self, cmd="AT\r", timeout=1000)
#
# Run AT command on the serial gateway
#
# @param cmd: AT command to be run
# @param timeout: Period after which the function should timeout
#
# @return Response received from gateway or None in case of lack of response (timeout)
##########################################################

sub runAtCommand(;$$) {
  my ( $self, $cmd, $timeout ) = @_;

  $cmd     = "AT\r" unless $cmd;
  $timeout = 1000   unless $timeout;

  $self->{_atresponse_received} = 0;

  # Send command via serial
  die "Port " + $self->{portname} + " is not open"
    unless ( defined $self->{_serport} );

  # Skip wireless packets
  $self->{_atresponse} = "(";

  # Send serial packet
  $self->{_serport}->send($cmd);

  # Wait for response from modem
  while ( length( $self->{_atresponse} ) eq 0
    or $self->{_atresponse} =~ /^\(/ )
  {
    return undef unless ( $self->_waitForResponse($timeout) );
  }

  # Return response received from gateway
  return $self->{_atresponse};
}

##########################################################
# sub sendCcPacket
#
# Send wireless CcPacket through the serial gateway
#
# @param packet: CcPacket to be transmitted
##########################################################

sub sendCcPacket($) {
  my ( $self, $packet ) = @_;

  my $strBuf = $packet->toString() . "\r";
  $self->{_serport}->send($strBuf);
}

##########################################################
# sub setFreqChannel
#
# Set frequency channel for the wireless gateway
#
# @param value: New frequency channel
##########################################################

sub setFreqChannel($) {
  my ( $self, $value ) = @_;

  # Check format
  die "Frequency channels must be 1-byte length" if ( $value > 0xFF );

  # Switch to command mode if necessary
  my $sermode = $self->{_sermode};
  if ( $$sermode eq DATA ) {
    $self->goToCommandMode();
  }

  # Run AT command
  my $response = $self->runAtCommand( sprintf( "ATCH=%02X\r", $value ) );
  if ( defined $response and $response =~ /^OK/ ) {
    $self->{freq_channel} = $value;
    return 1;
  }
  return 0;
}

##########################################################
# sub setSyncWord
#
# Set synchronization word for the wireless gateway
#
# @param value: New synchronization word
##########################################################

sub setSyncWord($) {
  my ( $self, $value ) = @_;

  # Check format
  die "Synchronization words must be 2-byte length" if ( $value > 0xFFFF );

  # Switch to command mode if necessary
  if ( $self->{_sermode} eq DATA ) {
    $self->goToCommandMode();
  }

  # Run AT command
  my $response = $self->runAtCommand( sprintf( "ATSW=%04X\r", $value ) );

  if ( defined $response =~ /^OK/ ) {
    $self->{syncword} = $value;
    return 1;
  }
  return 0;
}

##########################################################
# sub setDevAddress
#
# Set device address for the serial gateway
#
# @param value: New device address
##########################################################

sub setDevAddress($) {
  my ( $self, $value ) = @_;

  # Check format
  die "Device addresses must be 1-byte length" if ( $value > 0xFF );

  # Switch to command mode if necessary
  if ( $self->{_sermode} eq DATA ) {
    $self->goToCommandMode();
  }

  # Run AT command
  my $response = $self->runAtCommand( sprintf( "ATDA=%02X\r", $value ) );
  if ( defined $response and $response =~ /^OK/ ) {
    $self->{devaddress} = $value;
    return 1;
  }
  return 0;
}

##########################################################
# sub _waitForResponse
#
# Wait a given amount of milliseconds for a response from the serial modem
#
# @param millis: Amount of milliseconds to wait for a response
##########################################################

sub _waitForResponse($) {
  my ( $self, $millis ) = @_;

  my $loops = $millis / 10;
  while ( !$self->{_atresponse_received} ) {
    $self->poll();
    select( undef, undef, undef, 0.01 );
    $loops--;
    return 0 if ( $loops eq 0 );
  }
  return 1;
}

##########################################################
# Class Constructor
#
# @param portname: Name/path of the serial port
# @param speed: Serial baudrate in bps
# @param verbose: Print out SWAP traffic (True or False)
# @param async: run SerialPort handling in it's own thread
##########################################################

sub new(;$$$$) {
  my ( $class, $portname, $speed, $verbose, $async ) = @_;

  $portname = "/dev/ttyUSB0" unless ( defined $portname );
  $speed    = 38400          unless ( defined $speed );
  $async    = 1              unless ( defined $async );

  my $self = bless {

    # Serial mode (command or data modes)
    _sermode => DATA,

    # Response to the last AT command sent to the serial modem
    _atresponse => "",

    # AT response received from modem
    _atresponse_received => 0,

    # "Packet received" callback function. To be defined by the parent object
    _ccpacket_received => undef,

    # Name(path) of the serial port
    portname => $portname,

    # Speed of the serial port in bps
    portspeed => $speed,

    # Hardware version of the serial modem
    hwversion => undef,

    # Firmware version of the serial modem
    fwversion => undef,

    async => $async,

    # This flags switches to True when the serial modem is ready
    _wait_modem_start => 0

  }, $class;

  # Open serial port
  $self->{_serport} =
    Device::PanStamp::modem::SerialPort->new( $portname, $speed, $verbose,
    $async )
    || die "cant open Serial Port: $self->{portname}: $!";

  # Define callback function for incoming serial packets
  $self->{_serport}->setRxCallback( sub { $self->_serialPacketReceived(@_); } );

  return $self;
}

1;
