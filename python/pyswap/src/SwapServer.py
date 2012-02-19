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
from swap.SwapDefs import SwapFunction, SwapRegId
from swap.SwapPacket import SwapPacket, SwapQueryPacket
from swap.SwapMote import SwapMote
from swap.SwapNetwork import SwapNetwork
from SwapException import SwapException
from xmltools.XmlSettings import XmlSettings
from xmltools.XmlSerial import XmlSerial
from xmltools.XmlNetwork import XmlNetwork

import threading
import time
import urllib2
import tarfile
import os


class SwapServer(threading.Thread):
    """
    SWAP server class
    """
    # Maximum waiting time (in ms) for ACK's
    _MAX_WAITTIME_ACK = 2000
    # Max tries for any SWAP command
    _MAX_SWAP_COMMAND_TRIES = 3

   
    def run(self):
        """
        Start SWAP server thread
        """
        # Network configuration settings
        self._xmlnetwork = XmlNetwork(self._xmlSettings.network_file)
        # Serial configuration settings
        self._xmlserial = XmlSerial(self._xmlSettings.serial_file)
        
        try:
            # Create and start serial modem object
            self.modem = SerialModem(self._xmlserial.port, self._xmlserial.speed, self.verbose)

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
            threading.Thread.__init__(self)
            raise
        
        threading.Thread.__init__(self)
           

    def stop(self):
        """
        Stop SWAP server
        """
        #self._stop.set()
        if self.modem is not None:
            self.modem.stop()
        self.is_running = False
        
        threading.Thread.__init__(self)


    def resetNetwork(self):
        """
        Clear SWAP network adata nd read swapnet file again
        """
        # Clear network data
        self.network.read()

        
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
                    mote = SwapMote(self, swPacket.value.toAscii(), swPacket.srcAddress, swPacket.security, swPacket.nonce)
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
            # Periodic Tx interval received
            elif swPacket.regId == SwapRegId.ID_TX_INTERVAL:
                # Update interval in list of motes
                self._updateMoteTxInterval(swPacket)
            # For any other register id
            else:
                # Update register in the list of motes
                self._updateRegisterValue(swPacket)
        # QUERY packet received
        elif swPacket.function == SwapFunction.QUERY:
            # Query addressed to our gateway?
            if swPacket.destAddress == self.modem.devaddress:
                # Get mote from address
                mote = self.network.get_mote(address=swPacket.regAddress)
                if mote is not None:
                    # Send status packet
                    mote.staRegister(swPacket.regId)
                    

    def _checkMote(self, mote):
        """
        Check SWAP mote from against the current list
        
        @param mote: to be searched in the list
        """
        # Add mote to the network
        if self.network.add_mote(mote):
            # Save mote in SWAP network file
            self.network.save()
            # Notify event handler about the discovery of a new mote
            if self._eventHandler.newMoteDetected is not None:
                self._eventHandler.newMoteDetected(mote)
            # Notify the event handler about the discovery of new endpoints
            for reg in mote.regular_registers:
                for endp in reg.parameters:
                    if  self._eventHandler.newEndpointDetected is not None:
                        self._eventHandler.newEndpointDetected(endp)
                       

    def _updateMoteAddress(self, oldAddr, newAddr):
        """
        Update new mote address in list
        
        @param oldAddr: Old address
        @param newAddr: New address
        """
        # Has the address really changed?
        if oldAddr == newAddr:
            return
        # Get mote from list
        mote = self.network.get_mote(address=oldAddr)
        if mote is not None:
            mote.address = newAddr
            # Notify address change to event handler
            if self._eventHandler.moteAddressChanged is not None:
                self._eventHandler.moteAddressChanged(mote)


    def _updateMoteState(self, packet):
        """
        Update mote state in list

        @param packet: SWAP packet to extract the information from
        """
        # New system state
        state = packet.value.toInteger()

        # Get mote from list
        mote = self.network.get_mote(address=packet.regAddress)
        if mote is not None:
            # Has the state really changed?
            if mote.state == state:
                return

            # Update system state in the list
            mote.state = state

            # Notify state change to event handler
            if self._eventHandler.moteStateChanged is not None:
                self._eventHandler.moteStateChanged(mote)


    def _updateMoteTxInterval(self, packet):
        """
        Update mote Tx interval in list

        @param packet: SWAP packet to extract the information from
        """
        # New periodic Tx interval (in seconds)
        interval = packet.value.toInteger()

        # Get mote from list
        mote = self.network.get_mote(address=packet.regAddress)
        if mote is not None:
            # Has the interval really changed?
            if mote.txinterval == interval:
                return

            # Update system state in the list
            mote.txinterval = interval
       
        
    def _updateRegisterValue(self, packet):
        """
        Update register value in the list of motes

        @param packet: SWAP packet to extract the information from
        """
        # Get mote from list
        mote = self.network.get_mote(address=packet.regAddress)
        if mote is not None:
            # Search within its list of regular registers
            if mote.regular_registers is not None:
                for reg in mote.regular_registers:
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
                                for endp in reg.parameters:
                                    if endp.valueChanged == True:
                                        self._eventHandler.endpointValueChanged(endp)
                            return
            # Search within its list of config registers
            if mote.config_registers is not None:
                for reg in mote.config_registers:
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
                                for param in reg.parameters:
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

        # Update security option and nonce in list
        mote = self.network.get_mote(address=status.srcAddress)
        
        if mote is not None:
            mote.security = status.security
            mote.nonce = status.nonce
            

    def _discoverMotes(self):
        """
        Send broadcasted query to all available (awaken) motes asking them
        to identify themselves
        """
        query = SwapQueryPacket(SwapRegId.ID_PRODUCT_CODE)
        query.send(self.modem)


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
            ack = mote.cmdRegister(regId, value)
            # Wait for aknowledgement from mote
            if self._waitForAck(ack, SwapServer._MAX_WAITTIME_ACK):
                return True;    # ACK received
        return False            # Got no ACK from mote
    

    def setEndpointValue(self, endpoint, value):
        """
        Set endpoint value

        @param endpoint: Endpoint to be controlled
        @param value: New endpoint value

        @return True if the command is correctly ack'ed. Return False otherwise
        """
        # Send command multiple times if necessary
        for i in range(SwapServer._MAX_SWAP_COMMAND_TRIES):
            # Send command            
            ack = endpoint.sendSwapCmd(value)
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


    def _waitForAck(self, ackpacket, wait_time):
        """
        Wait for ACK (SWAP status packet)
        Non re-entrant method!!

        @param ackpacket: SWAP status packet to expect as a valid ACK
        @param wait_time: Max waiting time in milliseconds
        
        @return True if the ACK is received. False otherwise
        """
        self._packetAcked = False
        # Expected ACK packet (SWAP status)
        self._expectedAck = ackpacket
        
        #loops = wait_time / 10
        start = time.time()
        while not self._packetAcked:
            """
            time.sleep(0.01)
            loops -= 1
            if loops == 0:
                break
            """
            if (time.time() - start)*1000 >= wait_time:
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


    def update_definition_files(self):
        """
        Update Device Definition Files from remote server
        """
        print "Downloading Device Definition Files"
        local_tar = XmlSettings.device_localdir + ".tar.gz"
        
        try:
            remote = urllib2.urlopen(XmlSettings.device_remote)
            local = open(local_tar, 'w')
            local.write(remote.read())
            local.close()
            
            tar = tarfile.open(local_tar)
            direc = (XmlSettings.device_localdir).rpartition("/")[0]
            tar.extractall(path=direc)
            tar.close()
            
            os.remove(local_tar)
        except:
            raise SwapException("Unable to update Device Definition Files")
        
        
    def __init__(self, eventHandler, settings=None, start=True):
        """
        Class constructor

        @param eventHandler: Parent event handler object
        @param settings: path to the main configuration file
        @param verbose: Verbose SWAP traffic
        @param start: Start server upon creation if this flag is True
        """
        threading.Thread.__init__(self)
        self._stop = threading.Event()

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

        # Update Device Definition Files from Internet server
        if self._xmlSettings.updatedef:
            self.update_definition_files()

        ## Verbose SWAP frames
        self.verbose = False
        if self._xmlSettings.debug > 0:
            self.verbose = True

        ## Network data
        self.network = SwapNetwork(self, self._xmlSettings.swap_file)

        ## Tells us if the server is running
        self.is_running = False
        # Start server
        if start:
            self.start()
