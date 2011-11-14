#########################################################################
#
# SwapInterface
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
__date__  ="Sep 28, 2011 1:09:12 PM$"
#########################################################################

from SwapServer import SwapServer


class SwapInterface:
    """
    SWAP Interface superclass. Any SWAP application should derive from this one
    """
    def swapServerStarted(self):
        """
        SWAP server started successfully
        """
        pass


    def newMoteDetected(self, mote):
        """
        New mote detected by SWAP server
        
        @param mote: mote detected
        """
        pass


    def newParameterDetected(self, parameter):
        """
        New configuration parameter detected by SWAP server
        
        @param parameter: Endpoint detected
        """
        pass
    
    
    def newEndpointDetected(self, endpoint):
        """
        New endpoint detected by SWAP server
        
        @param endpoint: Endpoint detected
        """
        pass


    def moteStateChanged(self, mote):
        """
        Mote state changed
        
        @param mote: Mote having changed
        """
        pass


    def moteAddressChanged(self, mote):
        """
        Mote address changed
        
        @param mote: Mote having changed
        """
        pass


    def registerValueChanged(self, register):
        """
        Register value changed
        
        @param register: Register having changed
        """
        pass
    
    
    def endpointValueChanged(self, endpoint):
        """
        Endpoint value changed
        
        @param endpoint: Endpoint having changed
        """
        pass
    
    
    def parameterValueChanged(self, parameter):
        """
        Configuration parameter changed
        
        @param parameter: configuration parameter having changed
        """
        pass


    def getNbOfMotes(self):
        """
        @return the amounf of motes available in lstMotes
        """
        return self.server.getNbOfMotes()


    def getMote(self, index=None, address=None):
        """
        Return mote from list
        
        @param index: Index of the mote within lstMotes
        @param address: SWAP address of the mote
        
        @return mote
        """
        return self.server.getMote(index, address)


    def setMoteRegister(self, mote, regId, value):
        """
        Set new register value on wireless mote
        
        @param mote: Mote targeted by this command
        @param regId: Register ID
        @param value: New register value
        
        @return True if the command is correctly ack'ed. Return False otherwise
        """
        return self.server.setMoteRegister(mote, regId, value)


    def queryMoteRegister(self, mote, regId):
        """
        Query mote register, wait for response and return value
        Non re-entrant method!!
        
        @param mote: Mote to be queried
        @param regID: Register ID
        
        @return register value
        """
        return self.server.queryMoteRegister(mote, regId)


    def create_server(self):
        """
        Create server object
        """
        self.server = SwapServer(self, self.verbose)
        return self.server
        

    def start(self):
        """
        Start SWAP server
        """
        self.server.start()
        

    def stop(self):
        """
        Stop SWAP server
        """
        self.server.stop()


    def __init__(self, verbose=False, start=True):
        """
        Class constructor
        
        @param verbose: Print out SWAP frames
        @param start: Start SWAP server if True
        """
        ## Verbose option
        self.verbose = verbose
        ## SWAP server
        self.server = None
        ## List of motes
        self.lstMotes = None
                       
        print "SWAP server starting... "
        self.server = SwapServer(self, self.verbose, start)
        self.lstMotes = self.server.lstMotes
        print "SWAP server is now running... "
