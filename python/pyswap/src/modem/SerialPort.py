#########################################################################
#
# SerialPort
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
__date__ ="$Aug 21, 2011 17:05:27 AM$"
#########################################################################

from SwapException import SwapException

import threading
import serial
import time, sys

class SerialPort(threading.Thread):
    """
    Wrapper class of the pyserial package
    """

    def run(self):
        """
        Run serial port listener on its own thread
        """
        self._go_on = True
        if self._serport is not None:
            if self._serport.isOpen():
                # Flush buffers
                self._serport.flushInput()
                self._serport.flushOutput()
                serbuf = []
                # Listen for incoming serial data
                while self._go_on:
                    try:
                        # Read single byte (non blocking function)
                        ch = self._serport.read()
                        if len(ch) > 0:                    
                            # End of serial packet?
                            if ch == '\r' or ((ch == '(') and (len(serbuf) > 0)):
                                strBuf = "".join(serbuf)
                                serbuf = []
        
                                # Enable for debug only
                                if self._verbose == True:
                                    print "Rved: " + strBuf
                                
                                # Notify reception
                                if self.serial_received is not None:
                                    try:
                                        self.serial_received(strBuf)
                                    except SwapException as ex:
                                        ex.display()
                            elif ch != '\n':
                                # Append char at the end of the buffer (list)
                                serbuf.append(ch)
                    except OSError:
                        raise SwapException(str(sys.exc_type) + ": " + str(sys.exc_info()))

            else:
                raise SwapException("Unable to read serial port " + self.portname + " since it is not open")
        else:
            raise SwapException("Unable to read serial port " + self.portname + " since it is not open")

    
    def stop(self):
        """
        Stop serial port
        """
        self._go_on = False
        if self._serport is not None:
            if self._serport.isOpen():
                self._serport.flushInput()
                self._serport.flushOutput()
                self._serport.close()
                

    def send(self, buf):
        """
        Send string buffer via serial
        
        @param buf: Packet to be transmitted
        """
        # Send serial packet
        self._serport.write(buf)
        # Enable for debug only
        if self._verbose == True:
            print "Sent: " + buf


    def setRxCallback(self, cb_function):
        """
        Set callback reception function. This function is called whenever a new serial packet
        is received from the gateway
        
        @param cb_function: User-defined callback function
        """
        self.serial_received = cb_function


    def reset(self):
        """
        Hardware reset serial modem
        """
        # Set DTR line
        self._serport.setDTR(True)
        time.sleep(0.1)
        # Clear DTR line
        self._serport.setDTR(False)

           
    def __init__(self, portname="/dev/ttyUSB0", speed=38400, verbose=False):
        """
        Class constructor
        
        @param portname: Name/path of the serial port
        @param speed: Serial baudrate in bps
        @param verbose: Print out SWAP traffic (True or False)
        """
        threading.Thread.__init__(self)
        ## Name(path) of the serial port
        self.portname = portname
        ## Speed of the serial port in bps
        self.portspeed = speed
        ## Serial port object
        self._serport = None
        ## Callback Rx function
        self.serial_received = None
        # Verbose network traffic
        self._verbose = verbose
        try:
            # Open serial port in blocking mode
            self._serport = serial.Serial(self.portname, self.portspeed, timeout=1)
            if self._serport is None:
                raise SwapException("Unable to open serial port" + self.portname)
            elif not self._serport.isOpen():
                raise SwapException("Unable to open serial port" + self.portname)
            # Set to >0 in order to avoid blocking at Tx forever
            self._serport.writeTimeout = 1
            # Set DTR line to LOW
            self._serport.setDTR(False)
            
        except serial.SerialException as ex:
            raise SwapException(str(ex))
