#########################################################################
#
# SwapMote
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
__date__  ="$Aug 20, 2011 10:36:00 AM$"
#########################################################################

from swap.SwapInfoPacket import SwapInfoPacket
from swap.SwapCommandPacket import SwapCommandPacket
from swap.SwapQueryPacket import SwapQueryPacket
from swap.SwapDefs import SwapRegId, SwapState
from swap.SwapValue import SwapValue
from swapexception.SwapException import SwapException
from xmltools.XmlDevice import XmlDevice

import time


class SwapMote(object):
    """ SWAP device class"""
    def cmdRegister(self, regId, value):
        """ Send command to register and return expected response (SWAP info)"""
        # Expected response from mote
        infPacket = SwapInfoPacket(self.address, regId, value)
        # Command to be sent to the mote
        cmdPacket = SwapCommandPacket(self.address, regId, value, self.nonce)
        # Send command
        cmdPacket.send(self.server.modem)
        # Return expected response
        return infPacket;


    def qryRegister(self, regId):
        """ Send query to register"""
        # Query packet to be sent
        qryPacket = SwapQueryPacket(self.address, regId)
        # Send query
        qryPacket.send(self.server.modem)


    def infRegister(self, regId):
        """ Send SWAP info packet about the current value of the register passed as argument"""
        # Info packet to be sent
        infPacket = SwapInfoPacket(self.address, regId)
        # Send SWAP info packet
        infPacket.send(self.server.modem)


    def cmdRegisterWack(self, regId, value):
        """ Send SWAP command to remote register and wait for confirmation
        Return True if ACK received from mote """
        return self.server.setMoteRegister(self, regId, value)


    def setAddress(self, address):
        """ Set mote address. Return true if ACK received from mote"""
        val = SwapValue(address, length=1)
        return self.cmdRegisterWack(SwapRegId.ID_DEVICE_ADDR, val)


    def setNetworkId(self, netId):
        """ Set mote's network id. Return true if ACK received from mote"""
        val = SwapValue(netId, length=2)
        return self.cmdRegisterWack(SwapRegId.ID_NETWORK_ID, val)


    def setFreqChannel(self, channel):
        """ Set mote's frequency channel. Return true if ACK received from mote"""
        val = SwapValue(channel, length=1)
        return self.cmdRegisterWack(SwapRegId.ID_FREQ_CHANNEL, val)


    def setSecurity(self, secu):
        """ Set mote's security option. Return true if ACK received from mote"""
        val = SwapValue(secu, length=1)
        return self.cmdRegisterWack(SwapRegId.ID_SECU_OPTION, val)

    
    def restart(self):
        """ Ask mote to restart """
        val = SwapValue(SwapState.RESTART, length=1)
        return self.cmdRegisterWack(SwapRegId.ID_SYSTEM_STATE, val)


    def leaveSync(self):
        """ Ask mote to leave SYNC mode """
        val = SwapValue(SwapState.STOP, length=1)
        return self.cmdRegisterWack(SwapRegId.ID_SYSTEM_STATE, val)

    
    def updateTimeStamp(self):
        """
        Update time stamp
        """
        self.timeStamp = time.time()
    
    
    def __init__(self, server=None, productCode=None, address=0xFF):
        if server is None:
            raise SwapException("SwapMote constructor needs a valid SwapServer object")
        # Swap server object
        self.server = server
        # Product ID
        self.productId = 0
        # Manufacturer ID
        self.manufacturerId = 0
        # Definition settings
        self.config = None

        # Get manufacturer and product id from product code
        if productCode is not None:
            for i in range(4):
                self.manufacturerId = self.manufacturerId | (productCode[i] << 8 * (3-i))
                self.productId = self.productId | (productCode[i + 4] << 8 * (3-i))

        # Definition file
        # Definition settings
        self.definition = XmlDevice(self);

        # Device address
        self.address = address
        # Current mote's security nonce
        self.nonce = 0
        # State of the mote
        self.state = SwapState.RUNNING
        # List of regular registers provided by this mote
        self.lstRegRegs = None
        # List of config registers provided by this mote
        self.lstCfgRegs = None
        if self.definition is not None:
            # List of regular registers
            self.lstRegRegs = self.definition.getRegList()
            # List of config registers
            self.lstCfgRegs = self.definition.getRegList(config=True)
        # Initial time stamp
        self.timeStamp = None

