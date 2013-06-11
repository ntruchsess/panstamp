#########################################################################
# class SerialPort
#
# Wrapper class of the pyserial package
#########################################################################

package Device::PanStamp::swap::modem::SerialPort;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw();    # symbols to export on request

use Device::SerialPort qw( :PARAM :STAT 0.07 );

# Minimum delay between transmissions (in seconds)
our $txdelay = 0.05;

#########################################################################
# sub run
#
# Run serial port listener on its own thread
#########################################################################

sub run() {
  my $self = shift;

  $self->{_go_on} = 1;
  if ( defined $self->{_serport} ) {
    if ( $self->{_serport}->isOpen() ) {

      # Flush buffers
      $self->{_serport}->flushInput();
      $self->{_serport}->flushOutput();
      my @serbuf = ();

      # Listen for incoming serial data
      while ( $self->{_go_on} ) {

        # Read single byte (non blocking function)
        my $ch = $self->{_serport}->read();
        if ( length($ch) > 0 ) {

          # End of serial packet?
          if ( $ch eq '\r'
            or ( ( $ch eq '(' ) and ( scalar(@serbuf) > 0 ) ) )
          {
            my $strBuf = join( "", @serbuf );
            @serbuf = ();

            # Enable for debug only
            print "Rved: " + $strBuf if ( $self->{_verbose} );

            # Notify reception
            if ( defined $self->{serial_received} ) {
              &{ $self->{serial_received} }($strBuf);
            }
          } elsif ( $ch ne '\n' ) {

            # Append char at the end of the buffer (list)
            push @serbuf, $ch;
          }
        } else {
          select( undef, undef, undef, 0.01 )
            ;    #TODO check time (was time.sleep(0.01))
        }

        # Anything to be sent?
        #$self->{_send_lock.acquire()
        unless ( $self->{_strtosend} . empty() ) {
          if ( time . time() - $self->{last_transmission_time} > $txdelay )
          {      #TODO time
            my $strpacket = $self->{_strtosend}->get();

            # Send serial packet
            $self->{_serport}->write($strpacket);

            # Update time stamp
            $self->{last_transmission_time} = time . time();    #TODO time
                 # Enable for debug only
            print "Sent: " + $strpacket if ( $self->{_verbose} );
          }
        }

        #$self->{_send_lock.release()
      }
    } else {
      die "Unable to read serial port "
        . $self->{portname}
        . " since it is not open";
    }
  } else {
    die "Unable to read serial port "
      . $self->{portname}
      . " since it is not open";
    print "Closing serial port...";
  }
}

#########################################################################
# sub stop
#
# Stop serial port
#########################################################################

sub stop() {
  my $self = shift;
  $self->{_go_on} = 0;
  if ( defined $self->{_serport} ) {
    if ( $self->{_serport}->isOpen() ) {
      $self->{_serport}->flushInput();
      $self->{_serport}->flushOutput();
      $self->{_serport}->close();
    }
  }
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

  #$self->{_send_lock.acquire()
  $self->{_strtosend}->put($buf);

  #$self->{_send_lock.release()
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

  # Clear DTR/RTS lines
  $self->{_serport}->setDTR(0);
  $self->{_serport}->setRTS(0);

  select( undef, undef, undef, 0.001 );    #TODO time (was time.sleep(0.001))

  # Set DTR/R lines
  $self->{_serport}->setDTR(1);
  $self->{_serport}->setRTS(1);
}

#########################################################################
# sub new
#
# Class constructor
#
# @param portname: Name/path of the serial port
# @param speed: Serial baudrate in bps
# @param verbose: Print out SWAP traffic (True or False)
#########################################################################

sub new(;$$$) {
  my ( $class, $portname, $speed, $verbose ) = @_;

  $portname = "/dev/ttyUSB0" unless defined $portname;
  $speed    = 38400          unless defined $speed;
  $verbose  = 0              unless defined $verbose;

  #        threading.Thread.__init__(self)
  my $self = bless {
    ## Name(path) of the serial port
    portname => $portname,
    ## Speed of the serial port in bps
    portspeed => $speed,
    ## Serial port object
    _serport => undef,
    ## Callback Rx function
    serial_received => undef,

    # Strint to be sent
    # _strtosend => Queue . Queue(), #TODO Queue!

    #_send_lock => threading.Lock()
    # Verbose network traffic
    _verbose => $verbose,

    # Time stamp of the last transmission
    last_transmission_time => 0
  }, $class;

  # Open serial port in blocking mode
  $self->{_serport} =
    Device::SerialPort->new( $self->{portname} );
    
  #timeout = 0)
  #TODO port python serial to perl Device::Serial!
  
  die "Unable to open serial port" . $self->{portname}
    unless ( defined $self->{_serport} and $self->{_serport}->isOpen() );

  $self->{_serport}->baudrate($self->{portspeed});
  # Set to >0 in order to avoid blocking at Tx forever
  $self->{_serport}->{writeTimeout} = 1;

  # Reset modem
  $self->reset();

  return $self;
}

1;
