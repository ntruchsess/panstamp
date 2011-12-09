#########################################################################
#
# SwapManager
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
__date__ ="$Aug 21, 2011 4:30:47 PM$"
#########################################################################

from SwapBrowser import SwapBrowser
from LogWindow import LogFrame

from SwapInterface import SwapInterface
from swap.SwapDefs import SwapState
from SwapException import SwapException

import wx

class SwapManager(SwapInterface):
    """
    SWAP Management Class
    """
    def swapServerStarted(self):
        """
        SWAP server started successfully
        """
        self.browser.build_tree()

    
    def newMoteDetected(self, mote):
        """
        New mote detected by SWAP server
        
        'mote'  Mote object
        """
        if self.browser is not None:
            if self._printSWAP == True:
                print "New mote with address " + str(mote.address) + " : " + mote.definition.product + \
                " (by " + mote.definition.manufacturer + ")"
                
            # Append mote to the browsing tree
            self.browser.addMote(mote)


    def newEndpointDetected(self, endpoint):
        """
        New endpoint detected by SWAP server
        
        'endpoint'  Endpoint object
        """
        if self._printSWAP == True:
            print "New endpoint with Reg ID = " + str(endpoint.getRegId()) + " : " + endpoint.name


    def moteStateChanged(self, mote):
        """
        Mote state changed
        
        'mote' Mote object
        """
        if self._printSWAP == True:
            print "Mote with address " + str(mote.address) + " switched to \"" + \
            SwapState.toString(mote.state) + "\""
        # SYNC mode entered?
        if mote.state == SwapState.RXON:
            if self.browser is not None:
                self.browser.syncReceived(mote)


    def moteAddressChanged(self, mote):
        """
        Mote address changed
        
        'mote'  Mote object
        """
        if self._printSWAP == True:
            print "Mote changed address to " + str(mote.address)


    def endpointValueChanged(self, endpoint):
        """
        Endpoint value changed
        
        'endpoint' Endpoint object
        """
        if self._printSWAP == True:
            print endpoint.name + " in address " + str(endpoint.getRegAddress()) + " changed to " + endpoint.getValueInAscii()
            
        # Update value in SWAP browser
        if self.browser is not None:
            self.browser.updateEndpointInTree(endpoint)


    def paramValueChanged(self, param):
        """
        Config parameter value changed
        
        'param' Config parameter object
        """
        if self._printSWAP == True:
            print param.name + " in address " + str(param.getRegAddress()) + " changed to " + param.getValueInAscii()
            
        # Update value in SWAP browser
        self.browser.updateEndpointInTree(param)
        

    def terminate(self):
        """
        Exit application
        """
        self.app.Exit()
        self.app.ExitMainLoop()


    def __init__(self, verbose=False, monitor=False):
        """
        Class constructor
        
        'verbose'  Print out SWAP frames or not
        'monitor'  Print out network events or not
        """
        self.browser = None
        # Print SWAP activity
        self._printSWAP = monitor
        # Callbacks not being used
        self.registerValueChanged = None


        # wxPython app
        self.app = wx.PySimpleApp(0)
        wx.InitAllImageHandlers()
               
        # Start SWAP server
        try:
            # Superclass call
            SwapInterface.__init__(self, verbose, False)  
            # Clear error file
            SwapException.clear()         
        except SwapException as ex:
            ex.display()
            ex.log()

        # Create SWAP Network Monitor window
        net_monitor = LogFrame("SWAP Network Monitor")
        # Open SWAP browser
        self.browser = SwapBrowser(self, server=self.server, monitor=net_monitor)
        self.browser.SetSize(wx.Size(370,500))
        self.app.SetTopWindow(self.browser)
        self.browser.CenterOnScreen()
        self.browser.Show()
        # Open monitor window
        position = self.browser.GetPosition()
        size = self.browser.GetSize()
        position += (size[0]+200, 0)
        net_monitor.SetPosition(position)
        net_monitor.Show(True)

        self.app.MainLoop()
