#########################################################################
#
# SwapServer
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

from modem.SerialModem import SerialModem
from swap.SwapRegister import SwapRegister
from swap.SwapDefs import SwapFunction, SwapRegId, SwapState
from swap.SwapPacket import SwapPacket, SwapQueryPacket
from swap.SwapMote import SwapMote
from SwapException import SwapException
from xmltools.XmlSettings import XmlSettings
from xmltools.XmlSerial import XmlSerial
from xmltools.XmlNetwork import XmlNetwork

import threading
import time

class SwapServer(threading.Thread):
    """
    SWAP server class
    """
    # Maximum waiting time (in ms) for ACK's
    _MAX_WAITTIME_ACK = 500
    # Max tries for any SWAP command
    _MAX_SWAP_COMMAND_TRIES = 3

   
    def run(self):
        """
        Start SWAP server thread
        """
        self._start()


    def _start(self):
        """
        Start SWAP server
        """
        # Network configuration settings
        self._xmlnetwork = XmlNetwork(self._xmlSettings.network_file)
        # Serial configuration settings
        self._xmlserial = XmlSerial(self._xmlSettings.serial_file)
        
        try:
            # Create and start serial modem object
            self.modem = SerialModem(self._xmlserial.port, self._xmlserial.speed, self.verbose)
            if self.modem is None:
                raise SwapException("Unable to start serial modem on port " + self._xmlserial.port)
            # Declare receiving callback function
            self.modem.setRxCallback(self._ccPacketReceived)
    
            # Set modem configuration from _xmlnetwork
            param_changed = False
            # Device address
            if self._xmlnetwork.devaddress is not None:
                if self.modem.devaddress != self._xmlnetwork.devaddress:
                    if self.modem.setDevAddress(self._xmlnetwork.devaddress) == False:
                        raise SwapException("Unable to set modem's device address to " + self._xmlnetwork.devaddress)
                    else:
                        param_changed = True
            # Device address
            if self._xmlnetwork.network_id is not None:
                if self.modem.syncword != self._xmlnetwork.network_id:
                    if self.modem.setSyncWord(self._xmlnetwork.network_id) == False:
                        raise SwapException("Unable to set modem's network ID to " + self._xmlnetwork.network_id)
                    else:
                        param_changed = True
            # Frequency channel
            if self._xmlnetwork.freq_channel is not None:
                if self.modem.freq_channel != self._xmlnetwork.freq_channel:
                    if self.modem.setFreqChannel(self._xmlnetwork.freq_channel) == False:
                        raise SwapException("Unable to set modem's frequency channel to " + self._xmlnetwork.freq_channel)
                    else:
                        param_changed = True
    
            # Return to data mode if necessary
            if param_changed == True:
                self.modem.goToDataMode()
                
            self.is_running = True
            # Notify parent about the start of the server
            self._eventHandler.swapServerStarted()
    
            # Discover motes in the current SWAP network
            self._discoverMotes()
        except SwapException:
            raise
        

    def stop(self):
        """
        Stop SWAP server
        """
        self._stop.set()
        self.is_running = False
        if self.modem is not None:
            self.modem.stop()


    def stopped(self):
        return self._stop.isSet()


    def resetNetwork(self):
        """
        Clear SWAP network
        """
        # Clear lists of motes
        self.lstMotes = []

        
    def _ccPacketReceived(self, ccPacket):
        """
        CcPacket received
        
        @param ccPacket: CcPacket received        
        """
        try:
            # Convert CcPacket into SwapPacket
            swPacket = SwapPacket(ccPacket)
        except SwapException:
            return
        
        # Check function code
        # STATUS packet received
        if swPacket.function == SwapFunction.STATUS:
            # Expected response?
            self._checkStatus(swPacket)
            # Check type of data received
            # Product code received
            if swPacket.regId == SwapRegId.ID_PRODUCT_CODE:
                try:
                    mote = SwapMote(self, swPacket.value.toList(), swPacket.srcAddress)
                    mote.nonce = swPacket.nonce
                    self._checkMote(mote)
                except IOError as ex:
                    raise SwapException("Unable to create mote: {0}".format(ex))
            # Device address received
            elif swPacket.regId == SwapRegId.ID_DEVICE_ADDR:
                # Check address in list of motes
                self._updateMoteAddress(swPacket.srcAddress, swPacket.value.toInteger())
            # System state received
            elif swPacket.regId == SwapRegId.ID_SYSTEM_STATE:
                self._updateMoteState(swPacket)
            # For any other register id
            else:
                # Update register in the list of motes
                self._updateRegisterValue(swPacket)
        # QUERY packet received
        elif swPacket.function == SwapFunction.QUERY:
            # Query addressed to our gateway?
            if swPacket.destAddress == self.modem.devaddress:
                # Get mote from address
                mote = self.getMote(address=swPacket.regAddress)
                if mote is not None:
                    # Send status packet
                    mote.staRegister(swPacket.regId)
                    

    def _checkMote(self, mote):
        """
        Check SWAP mote from against the current list
        
        @param mote: to be searched in the list
        """
        # Search mote in list
        exists = False
        for item in self.lstMotes:
            if item.address == mote.address:
                exists = True
                break

        # Is this a new mote?
        if exists == False:
            # Append mote to the list
            self.lstMotes.append(mote)
            # Notify event handler about the discovery of a new mote
            if self._eventHandler.newMoteDetected is not None:
                self._eventHandler.newMoteDetected(mote)
            # Notify the event handler about the discovery of new endpoints
            for reg in mote.lstRegRegs:
                for endp in reg.lstItems:
                    if  self._eventHandler.newEndpointDetected is not None:
                        self._eventHandler.newEndpointDetected(endp)

        if mote.state != SwapState.RXON:
            # Update mote state to Rx ON
            mote.state = SwapState.RXON
            # Notify state change to event handler
            if self._eventHandler.moteStateChanged is not None:
                self._eventHandler.moteStateChanged(mote)
                        

    def _updateMoteAddress(self, oldAddr, newAddr):
        """
        Update new mote address in list
        
        @param oldAddr: Old address
        @param newAddr: New address
        """
        # Has the address really changed?
        if oldAddr == newAddr:
            return
        # Search mote in list
        for mote in self.lstMotes:
            if mote.address == oldAddr:
                mote.address = newAddr
                # Notify address change to event handler
                if self._eventHandler.moteAddressChanged is not None:
                    self._eventHandler.moteAddressChanged(mote)
                break


    def _updateMoteState(self, packet):
        """
        Update mote state in list

        @param packet: SWAP packet to extract the information from
        """
        # New system state
        state = packet.value.toInteger()

        # Search mote in list
        for mote in self.lstMotes:
            if mote.address == packet.srcAddress:
                # Has the state really changed?
                if mote.state == state:
                    return

                # Update system state in the list
                mote.state = state

                # Notify state change to event handler
                if self._eventHandler.moteStateChanged is not None:
                    self._eventHandler.moteStateChanged(mote)
                break

           
    def _updateRegisterValue(self, packet):
        """
        Update register value in the list of motes

        @param packet: SWAP packet to extract the information from
        """
        # Search in the list of motes
        for mote in self.lstMotes:
            # Same register address?
            if mote.address == packet.regAddress:
                # Search within its list of regular registers
                if mote.lstRegRegs is not None:
                    for reg in mote.lstRegRegs:
                        # Same register ID?
                        if reg.id == packet.regId:
                            # Did register's value change?
                            if not reg.value.isEqual(packet.value):
                                # Save new register value
                                reg.setValue(packet.value)
                                # Notify register'svalue change to event handler
                                if self._eventHandler.registerValueChanged is not None:
                                    self._eventHandler.registerValueChanged(reg)
                                # Notify endpoint's value change to event handler
                                if self._eventHandler.endpointValueChanged is not None:
                                    # Has any of the endpoints changed?
                                    for endp in reg.lstItems:
                                        if endp.valueChanged == True:
                                            self._eventHandler.endpointValueChanged(endp)
                                return
                # Search within its list of config registers
                if mote.lstCfgRegs is not None:
                    for reg in mote.lstCfgRegs:
                        # Same register ID?
                        if reg.id == packet.regId:
                            # Did register's value change?
                            if not reg.value.isEqual(packet.value):
                                # Save new register value
                                reg.setValue(packet.value)
                                # Notify register'svalue change to event handler
                                if self._eventHandler.registerValueChanged is not None:
                                    self._eventHandler.registerValueChanged(reg)
                                # Notify parameter's value change to event handler
                                if self._eventHandler.paramValueChanged is not None:
                                    # Has any of the endpoints changed?
                                    for param in reg.lstItems:
                                        if param.valueChanged == True:
                                            self._eventHandler.paramValueChanged(param)
                                return
                return


    def _checkStatus(self, status):
        """
        Compare expected SWAP status against status packet received

        @param status: SWAP packet to extract the information from
        """
        # Check possible command ACK
        self._packetAcked = False
        if (self._expectedAck is not None) and (status.function == SwapFunction.STATUS):
            if status.regAddress == self._expectedAck.regAddress:
                if status.regId == self._expectedAck.regId:
                    self._packetAcked = self._expectedAck.value.isEqual(status.value)

        # Check possible response to a precedent query
        self._valueReceived = None
        if (self._expectedRegister is not None) and (status.function == SwapFunction.STATUS):
            if status.regAddress == self._expectedRegister.getAddress():
                if status.regId == self._expectedRegister.id:
                    self._valueReceived = status.value

        # Update nonce in list
        mote = self.getMote(address=status.srcAddress)
        if mote is not None:
            mote.nonce = status.nonce
            

    def _discoverMotes(self):
        """
        Send broadcasted query to all available (awaken) motes asking them
        to identify themselves
        """
        query = SwapQueryPacket(SwapRegId.ID_PRODUCT_CODE)
        query.send(self.modem)


    def getNbOfMotes(self):
        """
        Return the amounf of motes available in the list
        
        @return Amount of motes available in lstMotes
        """
        return len(self.lstMotes)


    def getMote(self, index=None, address=None):
        """
        Return mote from list given its index or address

        @param index: Index of hte mote within lstMotes
        @param address: Address of the mote
        
        @return mote
        """
        if index is not None and index >= 0:
            return self.lstMotes[index]
        elif (address is not None) and (address > 0) and (address <= 255):
            for item in self.lstMotes:
                if item.address == address:
                    return item
        return None


    def setMoteRegister(self, mote, regId, value):
        """
        Set new register value on wireless mote
        Non re-entrant method!!

        @param mote: Mote containing the register
        @param regId: Register ID
        @param value: New register value

        @return True if the command is correctly ack'ed. Return False otherwise
        """
        # Send command multiple times if necessary
        for i in range(SwapServer._MAX_SWAP_COMMAND_TRIES):
            # Send command
            ack = mote.cmdRegister(regId, value);
            # Wait for aknowledgement from mote
            if self._waitForAck(ack, SwapServer._MAX_WAITTIME_ACK):
                return True;    # ACK received
        return False            # Got no ACK from mote


    def queryMoteRegister(self, mote, regId):
        """
        Query mote register, wait for response and return value
        Non re-entrant method!!
        
        @param mote: Mote containing the register
        @param regId: Register ID
        
        @return register value
        """
        # Queried register
        register = SwapRegister(mote, regId)
        # Send query multiple times if necessary
        for i in range(SwapServer._MAX_SWAP_COMMAND_TRIES):
            # Send query
            register.sendSwapQuery()
            # Wait for aknowledgement from mote
            regVal = self._waitForReg(register, SwapServer._MAX_WAITTIME_ACK)
            if regVal is not None:
                break   # Got response from mote
        return regVal


    def _waitForAck(self, ackPacket, waitTime):
        """
        Wait for ACK (SWAP status packet)
        Non re-entrant method!!

        @param ackPacket: SWAP status packet to expect as a valid ACK
        @param waitTime: Max waiting time in milliseconds
        
        @return True if the ACK is received. False otherwise
        """
        # Expected ACK packet (SWAP status)
        self._expectedAck = ackPacket
        
        loops = waitTime / 10
        while not self._packetAcked:
            time.sleep(0.01)
            loops -= 1
            if loops == 0:
                break
 
        res = self._packetAcked
        self._expectedAck = None
        self._packetAcked = False
        return res


    def _waitForReg(self, register, waitTime):
        """
        Wait for ACK (SWAP status packet)
        Non re-entrant method!!
        
        @param register: Expected register to be informed about
        @param waitTime: Max waiting time in milliseconds
        
        @return True if the ACK is received. False otherwise
        """
        # Expected ACK packet (SWAP status)
        self._expectedRegister = register

        loops = waitTime / 10
        while self._valueReceived is None:
            time.sleep(0.01)
            loops -= 1
            if loops == 0:
                break

        res = self._valueReceived
        self._expectedRegister = None
        self._valueReceived = None
        return res


    def getNetId(self):
        """
        Get current network ID
        
        @return Network ID
        """
        return self.modem.syncword


    def __init__(self, eventHandler, settings=None, verbose=False, start=True):
        """
        Class constructor

        @param eventHandler: Parent event handler object
        @param settings: path to the main configuration file
        @param verbose: Verbose SWAP traffic
        @param start: Start server upon creation if this flag is True
        """
        threading.Thread.__init__(self)
        self._stop = threading.Event()
        ## Verbose SWAP frames
        self.verbose = verbose
        ## Serial wireless gateway
        self.modem = None
        # Server's Security nonce
        self._nonce = 0
        # True if last packet was ack'ed
        self._packetAcked = False
        # Expected ACK packet (SWAP status packet containing a given endpoint data)
        self._expectedAck = None
        # Value received about register being queried
        self._valueReceived = None
        # Register being queried
        self._expectedRegister = None
        ## List of SWAP motes available in the network
        self.lstMotes = []

        # Event handling object. Its class must define the following methods
        # in order to dispatch incoming SWAP events:
        # - newMoteDetected(mote)
        # - newEndpointDetected(endpoint)
        # - newParameterDetected(parameter)
        # - moteStateChanged(mote)
        # - moteAddressChanged(mote)
        # - registerValueChanged(register)
        # - endpointValueChanged(endpoint)
        # - parameterValueChanged(parameter)
        self._eventHandler = eventHandler

        # General settings
        self._xmlSettings = XmlSettings(settings)

        ## Ture if server is running
        self.is_running = False
        # Start server
        if start:
            self.start()
