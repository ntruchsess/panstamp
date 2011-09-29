#########################################################################
#
# SerialModem
#
# Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
# 
# This file is part of the panStamp project.
# 
# panStamp  is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# panStamp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with panLoader; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 
# USA
#
#########################################################################
__author__="Daniel Berenguer"
__date__ ="$Aug 20, 2011 10:36:00 AM$"
#########################################################################

import time

from modem.SerialPort import SerialPort
from modem.CcPacket import CcPacket
from swapexception.SwapException import SwapException

class SerialModem:
    """
    Class representing a serial panstamp modem
    """

    class Mode:
        """
        Serial modes
        """
        DATA = 0
        COMMAND = 1


    def stop(self):
        """
        Stop serial gateway
        """
        if self._serPort is not None:
            self._serPort.stop()


    def _serialPacketReceived(self, buffer):
        """
        Serial packet received. This is a callback function called from
        the SerialPort object
        
        @param buffer: Serial packet received in String format
        """
        # If modem in command mode
        if self._serMode == SerialModem.Mode.COMMAND:
            self._atResponse = buffer
            self._atResponseReceived = True
        # If modem in data mode
        else:
            # Waiting for ready signal from modem?
            if self._waitModemStart == False:
                if buffer == "Modem ready!":
                    self._waitModemStart = True
            # Create CcPacket from string and notify reception
            elif self._ccPacketReceived is not None:
                try:
                    ccPacket = CcPacket(buffer)
                    self._ccPacketReceived(ccPacket)
                except SwapException:
                    raise


    def setRxCallback(self, cbFunct):
        """
        Set callback reception function. Notify new CcPacket reception
        
        @param cbFunct: Definition of custom Callback function for the reception of packets
        """
        self._ccPacketReceived = cbFunct
        

    def goToCommandMode(self):
        """
        Enter command mode (for AT commands)
        
        @return True if the serial gateway does enter Command Mode. Return false otherwise
        """
        self._serMode = SerialModem.Mode.COMMAND
        response = self.runAtCommand("+++", 3000)
        if response is None:
            return False
        if response[:2] == "OK":
            return True

        self._serMode = SerialModem.Mode.DATA
        return False


    def goToDataMode(self):
        """
        Enter data mode (for Rx/Tx operations)
        
        @return True if the serial gateway does enter Data Mode. Return false otherwise
        """
        response = self.runAtCommand("ATO\r")
        if response is None:
            return False
        if response[0:2] == "OK":
            self._serMode = SerialModem.Mode.DATA;
            return True;
        return False;

    
    def reset(self):
        """
        Reset serial gateway
        
        @return True if the serial gateway is successfully restarted
        """
        # Switch to command mode if necessary
        if self._serMode == SerialModem.Mode.DATA:
            self.goToCommandMode()
        # Run AT command
        response = self.runAtCommand("ATZ\r")
        if response is None:
            return False
        return response[0:2] == "OK"


    def runAtCommand(self, cmd="AT\r", timeout=1000):
        """
        Run AT command on the serial gateway
        
        @param cmd: AT command to be run
        @param timeout: Period after which the function should timeout
        
        @return Response received from gateway or None in case of lack of response (timeout)
        """
        self._atResponseReceived = False
        # Send command via serial
        if self._serPort is None:
            raise SwapException("Port " + self.portName + " is not open")

        # Skip wireless packets
        self._atResponse = "("
        # Send serial packet
        self._serPort.send(cmd)

        while self._atResponse[0] == '(':
            if not self._waitForResponse(timeout):
                return None
        # Return response received from gateway
        return self._atResponse


    def sendCcPacket(self, packet):
        """
        Send wireless CcPacket through the serial gateway
        
        @param packet: CcPacket to be transmitted
        """
        strBuf = packet.toString() + "\r"
        self._serPort.send(strBuf)

   
    def setFreqChannel(self, value):
        """
        Set frequency channel for the wireless gateway
        
        @param value: New frequency channel
        """
        # Check format
        if value > 0xFF:
            raise SwapException("Frequency channels must be 1-byte length")
        # Switch to command mode if necessary
        if self._serMode == SerialModem.Mode.DATA:
            self.goToCommandMode()
        # Run AT command
        response =  self.runAtCommand("ATCH=" + "{0:02X}".format(value) + "\r")
        if response is None:
            return False
        if response[0:2] == "OK":
            self.freqChannel = value
            return True
        return False
    
    def setSyncWord(self, value):
        """
        Set synchronization word for the wireless gateway
        
        @param value: New synchronization word
        """
        # Check format
        if value > 0xFFFF:
            raise SwapException("Synchronization words must be 2-byte length")
        # Switch to command mode if necessary
        if self._serMode == SerialModem.Mode.DATA:
            self.goToCommandMode()
        # Run AT command
        response = self.runAtCommand("ATSW=" + "{0:04X}".format(value) + "\r")
        if response is None:
            return False
        if response[0:2] == "OK":
            self.syncWord = value
            return True
        else:
            return False
    
    def setDevAddress(self, value):
        """
        Set device address for the serial gateway
        
        @param value: New device address
        """
        # Check format
        if value > 0xFF:
            raise SwapException("Device addresses must be 1-byte length")
        # Switch to command mode if necessary
        if self._serMode == SerialModem.Mode.DATA:
            self.goToCommandMode()
        # Run AT command
        response = self.runAtCommand("ATDA=" + "{0:02X}".format(value) + "\r")
        if response is None:
            return False
        if response[0:2] == "OK":
            self.devAddress = value
            return True
        else:
            return False
    
    def _waitForResponse(self, millis):
        """
        Wait a given amount of milliseconds for a response from the serial modem
        
        @param millis: Amount of milliseconds to wait for a response
        """
        loops = millis / 10
        while not self._atResponseReceived:
            time.sleep(0.01)
            loops -= 1
            if loops == 0:
                return False
        return True


    def __init__(self, portName="/dev/ttyUSB0", speed=38400, verbose=False):
        """
        Class constructor
        
        @param portName: Name/path of the serial port
        @param speed: Serial baudrate in bps
        @param verbose: Print out SWAP traffic (True or False)
        """
        # Serial mode (command or data modes)
        self._serMode = None
        # Response to the last AT command sent to the serial modem
        self._atResponse = ""
        # AT response received from modem
        self._atResponseReceived = None
        # "Packet received" callback function. To be defined by the parent object
        self._ccPacketReceived = None
        ## Name(path) of the serial port
        self.portName = portName
        ## Speed of the serial port in bps
        self.portSpeed = speed
        ## Hardware version of the serial modem
        self.hwVersion = None
        ## Firmware version of the serial modem
        self.fwVersion = None

        try:
            # Open serial port
            self._serPort = SerialPort(self.portName, self.portSpeed, verbose)
            # Reset serial mode
            self._serPort.reset()
            # Define callback function for incoming serial packets
            self._serPort.setRxCallback(self._serialPacketReceived)
            # Run serial port thread
            self._serPort.start()
    
            # This flags switches to True when the serial modem is ready
            self._waitModemStart = False
            while self._waitModemStart == False:
                pass
    
            # Retrieve modem settings
            # Switch to command mode
            if not self.goToCommandMode():
                raise SwapException("Modem is unable to enter command mode")
    
            # Hardware version
            response = self.runAtCommand("ATHV?\r")
            if response is None:
                raise SwapException("Unable to retrieve Hardware Version from serial modem")
            self.hwVersion = long(response, 16)
    
            # Firmware version
            response = self.runAtCommand("ATFV?\r")
            if response is None:
                raise SwapException("Unable to retrieve Firmware Version from serial modem")
            self.fwVersion = long(response, 16)
    
            # Frequency channel
            response = self.runAtCommand("ATCH?\r")
            if response is None:
                raise SwapException("Unable to retrieve Frequency Channel from serial modem")
            ## Frequency channel of the serial gateway
            self.freqChannel = int(response, 16)
    
            # Synchronization word
            response = self.runAtCommand("ATSW?\r")
            if response is None:
                raise SwapException("Unable to retrieve Synchronization Word from serial modem")
            ## Synchronization word of the serial gateway
            self.syncWord = int(response, 16)
    
            # Device address
            response = self.runAtCommand("ATDA?\r")
            if response is None:
                raise SwapException("Unable to retrieve Device Address from serial modem")
            ## Device address of the serial gateway
            self.deviceAddr = int(response, 16)
    
            # Switch to data mode
            self.goToDataMode()
        except:
            raise
