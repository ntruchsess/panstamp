package Device::PanStamp::swap::modem::SerialModem;

use Device::PanStamp::swap::modem::CcPacket;

###########################################################
#    Class representing a serial panstamp modem
###########################################################

use constant {
  # Serial modes
  DATA => 0,
  COMMAND => 1
};

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
# sub _serialPacketReceived($)
#
# Serial packet received. This is a callback function called from
# the SerialPort object
#        
# @param buf: Serial packet received in String format
###########################################################

sub _serialPacketReceived($) {
  my ($self, $buf) = @_;

  # If modem in command mode
  if ($self->{_sermode} eq COMMAND) {
    $self->{_atresponse} = $buf;
    $self->{_atresponse_received} = 1;
  # If modem in data mode
  } else {
    # Waiting for ready signal from modem?
    unless ($self->{_wait_modem_start} {
      if ($buf eq "Modem ready!") {
        $self->{_wait_modem_start} = 1;
        # Create CcPacket from string and notify reception
      } elsif (defined $self->{_ccpacket_received}) {
         my $ccPacket = Device::PanStamp::swap::modem::CcPacket->new($buf);
         $self->_ccpacket_received->($ccPacket);
      }
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
  my ($self, $cbFunct) = @_;
  
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
 
  return 1 if ($self->{_sermode} eq COMMAND);

  $self->{._sermode} = COMMAND;
  my $response = $self->runAtCommand("+++", 5000);

  return 1 if (defined $response and $response =~ /^OK/);

  $self->{_sermode} = DATA;
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

  return 1 if ($self->{_sermode} eq DATA);
        
  my $response = $self->runAtCommand("ATO\r");
        
  if (defined $response and $response =~ /^OK/) {
    $self->{_sermode} = DATA;
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
  if ($self->{_sermode} eq DATA) {
    $self->goToCommandMode();
  }
  # Run AT command
  my $response = self->runAtCommand("ATZ\r");
  if (defined $response and $response =~ /^OK/) {
    $self->{_sermode} = DATA;
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

sub runAtCommand(@) {
  my ($self, $cmd, $timeout) = @_;
  
  $cmd = "AT\r" unless $cmd;
  $timeout = 1000 unless $timeout;

  $self->{_atresponse_received} = 0;
  
  # Send command via serial
  die "Port " + $self->{portname} + " is not open" unless (defined $self->{_serport});

  # Skip wireless packets
  $self->{_atresponse} = "(";
  # Send serial packet
  $self->{_serport}->send($cmd);

  # Wait for response from modem
  while (length($self->{_atresponse}) == 0 or $self->{_atresponse} =~ /^\(/ );
  return undef unless ($self->_waitForResponse($timeout));

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
  my ($self, $packet) = @_; 

  my $strBuf = $packet.toString()."\r";
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
  my ($self, $value) = @_;
  
  # Check format
  die "Frequency channels must be 1-byte length" if ($value > 0xFF);

  # Switch to command mode if necessary
  if ($self->{_sermode} eq DATA) {
    $self->goToCommandMode();
  }
  
  # Run AT command
  my $response = $self->runAtCommand(sprintf ("ATCH=%02X\r",$value));
  if (defined $response and $response =~ /^OK/ ) {
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
  my ($self, $value) = @_;

  # Check format
  die "Synchronization words must be 2-byte length" if ($value > 0xFFFF);

  # Switch to command mode if necessary
  if ($self->{_sermode} eq DATA {
    $self->goToCommandMode();
  }
  # Run AT command
  my $response = $self->runAtCommand(sprintf ("ATSW=%04X\r",$value);
  
  if (defined $ and $response =~ /^OK/ ) {
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
  my ($self, $value) = @_;
  
  # Check format
  die "Device addresses must be 1-byte length" if ($value > 0xFF);

  # Switch to command mode if necessary
  if ($self->{_sermode} eq DATA) {
    $self->goToCommandMode();
  }
  # Run AT command
  my $response = $self->runAtCommand(sprintf ("ATDA=%02X\r",$value));
  if (defined $response and $response =~ /^OK/ ) {
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
  my ($self, $millis) = @_;

  my $loops = $millis / 10
  while (! $self->{_atresponse_received} ) { 
    select (undef,undef,undev,0.01);
    $loops--;
    return 0 if ($loops eq 0);
  }
  return 1;
}

##########################################################
# Class Constructor
#
# @param portname: Name/path of the serial port
# @param speed: Serial baudrate in bps
# @param verbose: Print out SWAP traffic (True or False)
##########################################################

sub new(@) {
  my ($class,$portname,$speed,$verbose) = @;
  
  $portname="/dev/ttyUSB0" unless $portname;
  $speed=38400 unless $speed;

  my $self = {
    # Serial mode (command or data modes)
    ._sermode => DATA,
    # Response to the last AT command sent to the serial modem
    _atresponse => "",
    # AT response received from modem
    #_atresponse_received => None,
    # "Packet received" callback function. To be defined by the parent object
    # _ccpacket_received => None,
    # Name(path) of the serial port
    portname => portname,
    # Speed of the serial port in bps
    portspeed => speed,
    # Hardware version of the serial modem
    #hwversion => None,
    # Firmware version of the serial modem
    #fwversion => None
  };
        try:
            # Open serial port
            self._serport = SerialPort(self.portname, self.portspeed, verbose)
            # Define callback function for incoming serial packets
            self._serport.setRxCallback(self._serialPacketReceived)
            # Run serial port thread
            self._serport.start()
               
            # This flags switches to True when the serial modem is ready
            self._wait_modem_start = False
            start = time.time()
            soft_reset = False
            while self._wait_modem_start == False:
                elapsed = time.time() - start
                if not soft_reset and elapsed > 5:
                    self.reset()
                    soft_reset = True
                elif soft_reset and elapsed > 10:
                    raise SwapException("Unable to reset serial modem")

            # Retrieve modem settings
            # Switch to command mode
            if not self.goToCommandMode():
                raise SwapException("Modem is unable to enter command mode")
    
            # Hardware version
            response = self.runAtCommand("ATHV?\r")
            if response is None:
                raise SwapException("Unable to retrieve Hardware Version from serial modem")
            self.hwversion = long(response, 16)
    
            # Firmware version
            response = self.runAtCommand("ATFV?\r")
            if response is None:
                raise SwapException("Unable to retrieve Firmware Version from serial modem")
            self.fwversion = long(response, 16)
    
            # Frequency channel
            response = self.runAtCommand("ATCH?\r")
            if response is None:
                raise SwapException("Unable to retrieve Frequency Channel from serial modem")
            ## Frequency channel of the serial gateway
            self.freq_channel = int(response, 16)
    
            # Synchronization word
            response = self.runAtCommand("ATSW?\r")
            if response is None:
                raise SwapException("Unable to retrieve Synchronization Word from serial modem")
            ## Synchronization word of the serial gateway
            self.syncword = int(response, 16)
    
            # Device address
            response = self.runAtCommand("ATDA?\r")
            if response is None:
                raise SwapException("Unable to retrieve Device Address from serial modem")
            ## Device address of the serial gateway
            self.devaddress = int(response, 16)
    
            # Switch to data mode
            self.goToDataMode()
        except:
            raise
