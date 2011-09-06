#########################################################################
#
# CcPacket
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

class CcPacket(object):
    """Standard packet structure of the CC11xx family of IC's"""

    def send(self, modem):
        """ Transmit packet"""
        if modem is not None:
            modem.sendCcPacket(self)
    
    def toString(self):
        """ Convert packet data to string"""
        # Convert list of bytes to list of strings
        strList = []
        for item in self.data:
            strList.append("{0:02X}".format(int(item)))
        # Convert list of strings to string
        strBuf = "".join(item for item in strList)
        # Return string
        return strBuf
    
    def __init__(self, strPacket=None):
        # Data bytes
        self.data = []
        # RSSI value in case of packet received
        self.rssi = 0
        # LQI in case of packet received
        self.lqi = 0
        if strPacket is not None:
            # Check the existence of the (RSSI/LQI) pair
            assert (strPacket[0], strPacket[5]) == ('(', ')'), "Incorrect packet format for incoming data. Lack of (RSSI,LQI)."
            assert len(strPacket) % 2 == 0, "Incorrect packet format. Amount of characters should not be odd."
            # RSSI and LQI bytes
            self.rssi = int(strPacket[1:3], 16)
            self.lqi = int(strPacket[3:5], 16)
            # Parse data fields
            for i in range(6, len(strPacket), 2):
                byte = int(strPacket[i:i + 2], 16)
                self.data.append(byte)


  
