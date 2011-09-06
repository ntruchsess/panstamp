#########################################################################
#
# SwapPacket
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
# Author: Daniel Berenguer
# Creation date: 20-Aug-2011
#
#########################################################################
__author__="Daniel Berenguer"
__date__ ="$Aug 20, 2011 10:36:00 AM$"
#########################################################################

from modem.CcPacket import CcPacket
from swap.SwapValue import SwapValue
from swap.SwapDefs import SwapAddress, SwapFunction

class SwapPacket(CcPacket):

    def send(self, ccModem):
        """ Overriden send method """
        self.srcAddress = ccModem.deviceAddr
        self.data[1] = self.srcAddress
        CcPacket.send(self, ccModem)

    """ SWAP packet class"""
    def __init__(self, ccPacket=None, destAddr=SwapAddress.BROADCAST_ADDR, hop=0, nonce=0, function=SwapFunction.INFO, regAddr=0, regId=0, value=None):
        """ Class constructor """
        CcPacket.__init__(self)

        # Destination address
        self.destAddress = destAddr
        # Source address
        self.srcAddress = None
        #Hop count for repeating purposes
        self.hop = hop
        #Security option
        self.security = 0
        #Security nonce
        self.nonce = nonce
        #Function code
        self.function = function
        #Register address
        self.regAddress = regAddr
        #Register ID
        self.regId = regId
        #SWAP value
        self.value = value

        if ccPacket is not None:
            # Superclass attributes
            self.rssi = ccPacket.rssi
            self.lqi = ccPacket.lqi
            self.data = ccPacket.data
            # Destination address
            self.destAddress = ccPacket.data[0]
            # Source address
            self.srcAddress = ccPacket.data[1]
            #Hop count for repeating purposes
            self.hop = (ccPacket.data[2] >> 4) & 0x0F
            #Security option
            self.security = ccPacket.data[2] & 0x0F
            #Security nonce
            self.nonce = ccPacket.data[3]
            #Function code
            self.function = ccPacket.data[4]
            #Register address
            self.regAddress = ccPacket.data[5]
            #Register ID
            self.regId = ccPacket.data[6]
            #SWAP value
            self.value = SwapValue(ccPacket.data[7:])
        else:
            self.data.append(self.destAddress)
            self.data.append(0)     # Empty source address
            self.data.append((self.hop << 4) | (self.security & 0x0F))
            self.data.append(self.nonce)
            self.data.append(self.function)
            self.data.append(self.regAddress)
            self.data.append(self.regId)

            if value is not None:
                for item in self.value.toList():
                    self.data.append(item)


  
