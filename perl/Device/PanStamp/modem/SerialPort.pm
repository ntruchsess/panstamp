#########################################################################
# class SerialPort
#
# Wrapper class of the pyserial package
#########################################################################

package Device::PanStamp::modem::SerialPort;

use strict;
use warnings;

use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw(time);

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Device::SerialPort qw( :PARAM :STAT 0.07 );

# Minimum delay between transmissions (in seconds)
our $txdelay = 0.05;

#########################################################################
# sub _run
#
# Run serial port listener on its own thread
#########################################################################

sub _run() {
  my $self = shift;

  # Listen for incoming serial data
  while ( ${ $self->{_go_on} } ) {
    eval {
      unless ( $self->poll() )
      {
        select( undef, undef, undef, 0.01 );
      }
    };
    if ($@) {
      print "Error processing data from serial port: $@\n";
      select( undef, undef, undef, 0.01 );
    }
  }
  
  if ( defined $self->{_serport} ) {

    eval {  
      # Flush buffers
      $self->{_serport}->purge_rx();
      $self->{_serport}->purge_tx();
      $self->{_serport}->close() unless $self->{_attached};
    };
  }
}

#########################################################################
# sub poll
#
# Poll the serial port (called either from background thread or SwapServer through SwapModem)
#########################################################################

sub poll() {
  my $self = shift;

  # Read up to 255 bytes (non blocking function)
  my ( $count, $data ) = $self->{_serport}->read(255);
  if ($count) {
    my @data = unpack "a" x $count, $data;
    my $serbuf = $self->{_serbuf};
    foreach my $ch (@data) {

      # End of serial packet?
      if ( $ch =~ /[\r\(]/ and (@$serbuf) ) {
        my $strBuf = join( "", @$serbuf );
        @$serbuf = ();

        # Enable for debug only
        print "Rved: $strBuf\n" if ( $self->{_verbose} );

        # Notify reception
        if ( defined $self->{_strreceived} ) {
          $self->{_strreceived}->enqueue($strBuf);
        } elsif ( defined $self->{serial_received} ) {
          &{ $self->{serial_received} }($strBuf);
        }
      } elsif ( $ch =~ /[^\r\n]/ ) {

        # Append char at the end of the buffer (list)
        push @$serbuf, $ch;
      }
    }
  }

  # Anything to be sent?
  if ( $self->{_strtosend}->pending() ) {
    if ( time - $self->{last_transmission_time} > $txdelay ) {
      my $strpacket = $self->{_strtosend}->dequeue();

      # Send serial packet
      $self->{_serport}->write($strpacket);

      # Update time stamp
      $self->{last_transmission_time} = time;

      # Enable for debug only
      print "Sent: $strpacket\n" if ( $self->{_verbose} );
    }
  }
  return $count;
}

#########################################################################
# sub start() {
#
# Start serial port
#
# @param async: if 1 run a separate thread to handle incomming data. Defaults to 0.
###########################################################

sub start(;$) {
  my ($self, $async) = @_;

  unless ( ${ $self->{_go_on} } ) {

    ${ $self->{_go_on} } = 1;
    if ( defined $self->{_serport} ) {

      if ( $async ) {
        # queue to pass Strings received to method 'receive' 
        $self->{_strreceived} = Thread::Queue->new() unless defined $self->{_strreceived}; 
        # Worker thread
        my $thr = threads->create(
          sub {
            $self->_run();
          }
        )->detach();
      }
    } else {
      die "Unable to read serial port "
        . $self->{portname}
        . " since it is not open";
      print "Closing serial port...";
    }
  }
}

#########################################################################
# sub stop
#
# Stop serial port
#########################################################################

sub stop() {
  my $self = shift;
  ${ $self->{_go_on} } = 0;
}

#########################################################################
# sub send($)
#
# Send string buffer via serial
#
# @param buf: Packet to be transmitted
#########################################################################

sub send($) {
  my ( $self, $buf ) = @_;

  $self->{_strtosend}->enqueue($buf);
}

#########################################################################
# sub receive()
#
# dequeue raw message from receive_queue and call serial_received callback (if any)
#########################################################################

sub receive() {
  my $self = shift;

  if (  defined $self->{serial_received}
    and defined $self->{_strreceived}
    and defined( my $strBuf = $self->{_strreceived}->dequeue_nb() ) )
  {
    &{ $self->{serial_received} }($strBuf);
  }
}

#########################################################################
# sub setRxCallback($) {
#
# Set callback reception function. This function is called whenever a new serial packet
# is received from the gateway
#
# @param cb_function: User-defined callback function
#########################################################################

sub setRxCallback($) {
  my ( $self, $cb_function ) = @_;

  $self->{serial_received} = $cb_function;
}

#########################################################################
# sub reset
#
# Hardware reset serial modem
#########################################################################

sub reset() {
  my $self = shift;

  # Flush buffers
  $self->{_serport}->purge_rx();
  $self->{_serport}->purge_tx();

  #force reset of arduino by pulsing DTR:
  $self->{_serport}->pulse_dtr_on(100);
}

#########################################################################
# sub new
#
# Class constructor
#
# @param port: Name/path of the serial port or reference to existing Device::SerialPort object
# @param speed: Serial baudrate in bps
# @param verbose: Print out SWAP traffic (True or False)
#########################################################################

sub new(;$$$) {
  my ( $class, $port, $speed, $verbose ) = @_;

  my $attached = defined $port and ref($port) =~ /::SerialPort$/; 
  if ( $attached ) {
    $portname = "Device::Serial object provided by application";
  } else {
    $portname = "/dev/ttyUSB0" unless defined $portname;
    $speed    = 38400          unless defined $speed;
  }

  $verbose  = 0              unless defined $verbose;

  my $_go_on : shared = 0;

  my $self = bless {
    ## Name(path) of the serial port
    portname => $portname,
    ## Speed of the serial port in bps
    portspeed => $speed,
    ## Serial port object
    _serport => undef,
    ## Callback Rx function
    serial_received => undef,

    # String to be sent
    _strtosend => Thread::Queue->new(),

    # Verbose network traffic
    _verbose => $verbose,

    # Time stamp of the last transmission
    last_transmission_time => 0,

    _go_on => \$_go_on,
    
    _attached => $attached,

    _serbuf => []
  }, $class;

  if ( $attached ) {
    $self->{_serport} = $port;
  } else {
    # Open serial port in blocking mode
    $self->{_serport} = Device::SerialPort->new( $self->{portname} );
  
    die "Unable to open serial port" . $self->{portname}
      unless ( defined $self->{_serport} );
  
    $self->{_serport}->baudrate( $self->{portspeed} );
    $self->{_serport}->databits(8);
    $self->{_serport}->parity("none");
    $self->{_serport}->stopbits(1);
    $self->{_serport}->write_settings;
  }

  # Reset modem
  $self->reset();

  return $self;
}

1;
