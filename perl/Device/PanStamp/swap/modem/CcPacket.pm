package Device::PanStamp::swap::modem::CcPacket;

###########################################################
#    Standard packet structure of the CC11xx family of IC's
###########################################################

###########################################################
# sub send
#        Transmit packet
#        @param modem: Modem object
###########################################################

sub send($) {
  my ($self, $modem) = @_;
  $modem->sendCcPacket($self) if ($modem);
}

###########################################################
# sub toString
#        Convert packet data to string
#        @return CcPacket in string format
###########################################################
    
sub toString() {
  my $self = shift; 
  # Convert list of bytes to list of strings
  my $str="";
  foreach my $c (@{$self->{data}}) {
    $str.= sprintf ("%02X", $c);
  }
  return $str;
}

###########################################################
#        Class constructor
#        @param strPacket: Wireless packet in string format
###########################################################
sub new(@) {
  my $strPacket = shift;

  my $self = {
  	data => [], # Data bytes
  	rssi => 0,  # RSSI value in case of packet received
  	lqi  => 0   # LQI in case of packet received
  };

  if ($strPacket) {
  	# Check packet length
    if (length $strPacket < 20):
                raise SwapException("Incomplete packet received.")
            # Check the existence of the (RSSI/LQI) pair
            if (strPacket[0], strPacket[5]) != ('(', ')'):
                raise SwapException("Incorrect packet format for incoming data. Lack of (RSSI,LQI).")
            if len(strPacket) % 2 > 0:
                raise SwapException("Incorrect packet format. Amount of characters should not be odd.")
            
            try:
                ## RSSI byte
                self.rssi = int(strPacket[1:3], 16)
                ## LQI byte
                self.lqi = int(strPacket[3:5], 16)
                # Parse data fields
                for i in range(6, len(strPacket), 2):
                    byte = int(strPacket[i:i + 2], 16)
                    self.data.append(byte)
            except ValueError:
                SwapException("Incorrect packet format")
