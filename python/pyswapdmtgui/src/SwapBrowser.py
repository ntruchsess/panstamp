#########################################################################
#
# SwapBrowser
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
__author__="Daniel Berenguer (dberenguer@usapiens.com)"
__date__ ="$Sep 16, 2011 10:46:15 AM$"
__appname__ = "SWAPdmt (GUI version)"
__version__ = "1.0"
#########################################################################

from DeviceSelector import DeviceSelector
from ParamDialog import ParamDialog
from WaitDialog import WaitDialog
from SerialDialog import SerialDialog
from NetworkDialog import NetworkDialog

from swap.SwapDefs import SwapType, SwapState
from SwapException import SwapException
from xmltools.XmlDevice import XmlDeviceDir
from xmltools.XmlSettings import XmlSettings
from xmltools.XmlNetwork import XmlNetwork

import wx


class SwapBrowser(wx.Frame):
    '''
    SWAP data browser
    '''

    def __init__(self, parent=None, server=None, monitor=None):
        '''
        Class constructor
        
        @param parent: parent object
        @param monitor: monitor dialog
        @param server: SWAP server
        '''
        args = (None, -1, "SWAP browser")
        kwargs = {"style" : wx.DEFAULT_FRAME_STYLE}
        wx.Frame.__init__(self, *args, **kwargs)

        favicon = wx.Icon("images/swap.ico", wx.BITMAP_TYPE_ICO, 16, 16)
        self.SetIcon(favicon)
        
        # Parent
        self.parent = parent
        # SWAP server
        self.server = server
        # SWAP monitor
        self.monitor = monitor
        # Server startup dialog
        self._waitfor_startdialog = None
        
        # Sync dialog
        self._waitfor_syncdialog = None
        # Mote in SYNC mode
        self._moteinsync = None
               
        # Create menu bar
        self.menubar = wx.MenuBar()
        # Create menus
        menufile = wx.Menu()
        self.menugateway = wx.Menu()
        menudevices = wx.Menu()
        menuview = wx.Menu()
        menuhelp = wx.Menu()
        # Append items into the menus
        # File menu
        menufile.Append(101, "&Close", "Close SWAP Browser")
        
        # Gateway menu
        self.menugateway.Append(201, "&Connect", "Connect serial gateway")
        self.menugateway.Append(202, "&Disconnect", "Disconnect serial gateway")
        self.menugateway.Append(203, "&Serial port", "Configure gateway\'s serial port")
        self.menugateway.Append(204, "&Network", "Configure gateway\'s network settings")
        
        # Devices menu
        menudevices.Append(301, "&Network settings", "Configure network settings")
        menudevices.Append(302, "&Custom settings", "Configure custom settings")
        
        # Devices menu
        menuview.Append(401, "&Network monitor", "SWAP network monitor")
        
        # Help menu
        menuhelp.Append(501, "&About", "About this application")

        self.menubar.Append(menufile, "&File")
        self.menubar.Append(self.menugateway, "&Gateway")
        self.menubar.Append(menudevices, "&Devices")
        self.menubar.Append(menuview, "&View")
        self.menubar.Append(menuhelp, "&Help")
        
        # Set menubar
        self.SetMenuBar(self.menubar)
        
        # Attach event handlers
        wx.EVT_MENU(self, 201, self._OnConnect)
        wx.EVT_MENU(self, 202, self._OnDisconnect)
        wx.EVT_MENU(self, 203, self._OnSerialConfig)
        wx.EVT_MENU(self, 204, self._OnGatewayNetworkConfig)
        wx.EVT_MENU(self, 301, self._OnMoteNetworkConfig)
        wx.EVT_MENU(self, 302, self._OnConfigDevice)
        wx.EVT_MENU(self, 401, self._OnViewMonitor)
        wx.EVT_MENU(self, 501, self._OnAbout)
        wx.EVT_MENU(self, 101, self._OnClose)
        self.Bind(wx.EVT_CLOSE, self._OnCloseBrowser)
               
        # SWAP browsing tree
        self.tree = wx.TreeCtrl(self, -1, style=wx.TR_HAS_BUTTONS|wx.TR_DEFAULT_STYLE|wx.SUNKEN_BORDER)
        sizer = wx.BoxSizer(wx.HORIZONTAL)
        sizer.Add(self.tree, 1, wx.EXPAND, 0)

        self.SetAutoLayout(True)
        self.SetSizer(sizer)
        sizer.Fit(self)
        sizer.SetSizeHints(self)
        self.SetSize((800, 500))
        self.Layout()        

        # create the image list:
        il = wx.ImageList(16, 16)
        self.rootIcon = il.Add(wx.Bitmap("images/network.ico", wx.BITMAP_TYPE_ICO))
        self.moteIcon = il.Add(wx.Bitmap("images/swap.ico", wx.BITMAP_TYPE_ICO))
        self.regRegIcon = il.Add(wx.Bitmap("images/database.ico", wx.BITMAP_TYPE_ICO))
        self.cfgRegIcon = il.Add(wx.Bitmap("images/cfgreg.ico", wx.BITMAP_TYPE_ICO))
        self.cfgParamIcon = il.Add(wx.Bitmap("images/cfgparam.ico", wx.BITMAP_TYPE_ICO))
        self.inputIcon = il.Add(wx.Bitmap("images/input.ico", wx.BITMAP_TYPE_ICO))
        self.outputIcon = il.Add(wx.Bitmap("images/output.ico", wx.BITMAP_TYPE_ICO))
        self.tree.AssignImageList(il)

        # Disable Disconnect item. Enable Connect item
        self.menugateway.Enable(202, enable=False)
        self.menugateway.Enable(201, enable=True)
        # Disable Device menu
        self.menubar.EnableTop(2, enable=False)      
            
            
    def _OnViewMonitor(self, evn):
        """
        View->SWAP Network Monitor pressed
        """
        if self.monitor is not None:
            self.monitor.Show(True)


    def _OnSerialConfig(self, evn):
        """
        Config serial port pressed
        """
        # Open serial port config dialog
        SerialDialog()
        
        
    def _OnGatewayNetworkConfig(self, evn):
        """
        Gateway->Network pressed. Callback function
        """
        # Configuration settings
        config = XmlNetwork(XmlSettings.network_file)
        # Open network config dialog
        if self.server.modem is None:
            dialog = NetworkDialog(self, config.devaddress, hex(config.network_id), config.freq_channel, config.security)
        else:
            dialog = NetworkDialog(self, self.server.modem.devaddress, hex(self.server.modem.syncword), self.server.modem.freq_channel, config.security)
        res = dialog.ShowModal()
        
        # Save new settings in xml file
        if res == wx.ID_CANCEL:
            return
        
        config.devaddress = int(dialog.devaddress)
        config.network_id = int(dialog.netid, 16)
        config.freq_channel = int(dialog.freq_channel)
        config.security = int(dialog.security)
        config.save()
        
        self._Info("In order to take the new settings, you need to restart the gateway", "Gateway restart required")


    def _OnMoteNetworkConfig(self, evn):
        """
        Devices->Network settings pressed. Callback function
        """
        paramsOk = False
        # Configuration settings
        config = XmlNetwork(XmlSettings.network_file)
        
        # This is our mote
        mote = None
        
        # Any mote selected from the tree?
        itemID = self.tree.GetSelection()
        if itemID is not None:
            obj = self.tree.GetPyData(itemID)
            if obj.__class__.__name__ == "SwapMote":
                mote = obj
                address = mote.address
                netid = config.network_id
                freqChann = config.freq_channel
                secu = mote.security
                if mote.pwrdownmode == True:
                    txinterval = mote.txinterval
                    mote = None
                else:
                    txinterval = None
                paramsOk = True

        # No mote selected from the tree?
        if not paramsOk:
            address = 0xFF
            netid = config.network_id
            freqChann = config.freq_channel
            secu = config.security
            txinterval = ""
        
        # Open network config dialog
        dialog = NetworkDialog(self, address, hex(netid), freqChann, secu, txinterval)
        res = dialog.ShowModal()

        if res == wx.ID_CANCEL:
            return
              
        # No mote selected?
        if mote is None:
            # Ask for SYNC mode
            res = self._WaitForSync()
            if not res:
                return
            mote = self._moteinsync  
        
        # Send new config to mote
        if int(dialog.devaddress) != address:
            if not mote.setAddress(int(dialog.devaddress)):
                self._Warning("Unable to set mote's address")
        if dialog.netid != hex(netid):
            if not mote.setNetworkId(int(dialog.netid, 16)):
                self._Warning("Unable to set mote's Network ID")
        if int(dialog.security) != secu:
            if not mote.setSecurity(int(dialog.security)):
                self._Warning("Unable to set mote's security option")
        if dialog.interval is not None:
            if dialog.interval != txinterval:
                if not mote.setTxInterval(int(dialog.interval)):
                    self._Warning("Unable to set mote's Tx interval")
        if int(dialog.freq_channel) != freqChann:
            if not mote.setFreqChannel(int(dialog.freq_channel)):
                self._Warning("Unable to set mote's frequency channel")
                    
       
    def _OnConnect(self, evn=None):
        """
        Connect option pressed
        """        
        try:
            # Start SWAP server
            self.server.start()
            
            self._waitfor_startdialog = WaitDialog(self, "Connecting to SWAP network...", 10)
            if not self._waitfor_startdialog.show():
                # Stop SWAP server
                if self.server is not None:
                    self.server.stop()
                self._Warning("Unable to start SWAP server. Please check connection and try again.")
                return

            # Build tree
            self._build_tree()
            
            self.menugateway.Enable(201, enable=False)
            self.menugateway.Enable(202, enable=True)
            self.menubar.EnableTop(2, enable=True)
            
        except SwapException as ex:
            self._Warning(ex.description)
            ex.log()


    def _OnDisconnect(self, evn):
        """
        Disconnect option pressed
        """
        # Stop SWAP server
        if self.server is not None:
            self.server.stop()
            
        WaitDialog(self, "Disconnecting from SWAP network...", 3).show()    
        
        self.menugateway.Enable(201, enable=True)
        self.menugateway.Enable(202, enable=False)
        self.menubar.EnableTop(2, enable=False)
        
        self._Info("Server stopped and disconnected from SWAP network", caption = "Disconnected")


    def _OnConfigDevice(self, evn):
        """
        Devices->Custom settings pressed. Callback function
        """
        isOk = False
        # Any mote selected from the tree?
        itemID = self.tree.GetSelection()
        if itemID is not None:
            obj = self.tree.GetPyData(itemID)
            if obj.__class__.__name__ == "SwapMote":
                isOk = True
            elif obj.__class__.__name__ == "SwapRegister":
                if obj.isConfig():
                    isOk = True
                 
        if not isOk:
            selector = DeviceSelector()
            res = selector.ShowModal()
            
            if res == wx.ID_CANCEL:
                return
            
            option = selector.getSelection()                    
            selector.Destroy()       
            # Get Develoepr/device directory from devices.xml
            deviceDir = XmlDeviceDir()
            # Find our mote within the directory
            obj = deviceDir.getDeviceDef(option)
            if obj is None:
                self._Warning("Unable to find device \"" + option + "\" in directory")
                return
            
        # Configure registers
        self._configure(obj)
        

    def _RightClickCb(self, evn):
        """
        Mouse right-click event. Callback function
        """
        # Get item currently selected
        itemID = self.tree.GetSelection()
        obj = self.tree.GetPyData(itemID)
        menu = None
        if obj.__class__.__name__ == "SwapMote":
            menu = wx.Menu()                
            menu.Append(0, "Network settings")
            wx.EVT_MENU(menu, 0, self._OnMoteNetworkConfig)
            if obj.lstcfgregs is not None:
                menu.Append(1, "Custom settings")
                wx.EVT_MENU(menu, 1, self._OnConfigDevice)
        elif obj.__class__.__name__ == "SwapRegister":
            if obj.isConfig():
                menu = wx.Menu()
                menu.Append(0, "Configure")
        
        if menu is not None:
            self.PopupMenu(menu, evn.GetPoint())
            menu.Destroy()   
        
        
    def _build_tree(self):
        '''
        Build SWAP tree
        '''
        if self.server is None:
            return

        if self.server.is_running:
            # Disable Connect item. Enable Disconnect item
            self.menugateway.Enable(201, enable=False)
            self.menugateway.Enable(202, enable=True)
            self.menubar.EnableTop(2, enable=True)
            
        netid = self.server.getNetId()
        
        if netid is not None:
            rootStr = "SWAP network " + hex(netid)
        else:
            rootStr = "SWAP network"
      
        # Clear tree
        self.tree.DeleteAllItems()
        self.rootID = self.tree.AddRoot(rootStr)
        self.tree.SetPyData(self.rootID, None)

        if self.server is not None:
            for mote in self.server.lstMotes:
                self.addMote(mote)
 
        self.tree.SetItemImage(self.rootID, self.rootIcon, wx.TreeItemIcon_Normal)
 
        self.tree.Expand(self.rootID)
        
        # Right-click event
        wx.EVT_TREE_ITEM_RIGHT_CLICK(self.tree, -1, self._RightClickCb)


    def cbServerStarted(self):
        """
        Callback function called from SwapManager when the SWAP sever has been
        successfully started
        """
        if self._waitfor_startdialog is not None:
            self._waitfor_startdialog.close()


    def addMote(self, mote):
        """
        Add mote to the tree
        
        'mote'  Mote to be added to the tree
        """
        # Add mote to the root
        moteID = self.tree.AppendItem(self.rootID, "Mote " + str(mote.address) + ": " + mote.definition.product)
        self.tree.SetItemImage(moteID, self.moteIcon, wx.TreeItemIcon_Normal)
        # Associate mote with its tree entry
        self.tree.SetPyData(moteID, mote)

        if mote.lstcfgregs is not None:
            # Append associated config registers
            for reg in mote.lstcfgregs:
                # Add register to the mote item
                regID = self.tree.AppendItem(moteID, "Register " + str(reg.id) + ": " + reg.name)
                self.tree.SetItemImage(regID, self.cfgRegIcon, wx.TreeItemIcon_Normal)
                # Associate register with its tree entry
                self.tree.SetPyData(regID, reg)
                # Append associated parameters
                for param in reg.lstItems:
                    # Add register to the mote item
                    paramID = self.tree.AppendItem(regID, param.name + " = " + param.getValueInAscii())
                    self.tree.SetItemImage(paramID, self.cfgParamIcon, wx.TreeItemIcon_Normal)
                    # Associate register with its tree entry
                    self.tree.SetPyData(paramID, param)
        if mote.lstregregs is not None:
            # Append associated regular registers
            for reg in mote.lstregregs:
                # Add register to the mote item
                regID = self.tree.AppendItem(moteID, "Register " + str(reg.id) + ": " + reg.name)
                self.tree.SetItemImage(regID, self.regRegIcon, wx.TreeItemIcon_Normal)
                # Associate register with its tree entry
                self.tree.SetPyData(regID, reg)
                # Append associated endpoints
                for endp in reg.lstItems:
                    # Add register to the mote item
                    endpID = self.tree.AppendItem(regID, endp.name + " = " + endp.getValueInAscii())
                    if endp.direction == SwapType.OUTPUT:
                        self.tree.SetItemImage(endpID, self.outputIcon, wx.TreeItemIcon_Normal)
                    else:
                        self.tree.SetItemImage(endpID, self.inputIcon, wx.TreeItemIcon_Normal)
                    # Associate register with its tree entry
                    self.tree.SetPyData(endpID, endp)
                  

    def updateEndpointInTree(self, endpoint):
        """
        Update endpoint value in tree
        
        @param endpoint:  Endpoint to be updated in the tree
        """
        moteID, moteCookie = self.tree.GetFirstChild(self.rootID)
        
        while moteID.IsOk():
            mote = self.tree.GetPyData(moteID)
            if mote.address == endpoint.getRegAddress():
                regID, regCookie = self.tree.GetFirstChild(moteID)
                while regID.IsOk():
                    reg = self.tree.GetPyData(regID)
                    if reg.id == endpoint.getRegId():
                        endpID, endpCookie = self.tree.GetFirstChild(regID)
                        while endpID.IsOk():
                            endp = self.tree.GetPyData(endpID)
                            if endp.name == endpoint.name:
                                # Get endpoint icon
                                icon = self.tree.GetItemImage(endpID)
                                # Append new endpoint to the tree
                                newEndpID = self.tree.InsertItem(regID, endpID, text=endpoint.name + " = " + endpoint.getValueInAscii(), image=icon)
                                self.tree.SetPyData(newEndpID, endp)
                                # Remove old endpoint
                                self.tree.Delete(endpID)
                                return
                            endpID, endpCookie = self.tree.GetNextChild(regID, endpCookie)
                        return
                    regID, regCookie = self.tree.GetNextChild(moteID, regCookie)
                return
            moteID, moteCookie = self.tree.GetNextChild(self.rootID, moteCookie)
            
            
    def updateAddressInTree(self, mote):
        """
        Update mote address in tree
        
        @param mote  Mote to be updated in the tree
        """
        # Try with first mote in tree
        moteID, moteCookie = self.tree.GetFirstChild(self.rootID)
        
        while moteID.IsOk():
            m = self.tree.GetPyData(moteID)
            if m == mote:                
                # Add mote to the root
                newMoteID = self.tree.AppendItem(self.rootID, "Mote " + str(mote.address) + ": " + mote.definition.product)
                self.tree.SetItemImage(newMoteID, self.moteIcon, wx.TreeItemIcon_Normal)
                # Associate mote with its tree entry
                self.tree.SetPyData(newMoteID, mote)                
                # Remove old mote
                self.tree.Delete(moteID)
                return
            
            # Try with next mote in tree
            moteID, moteCookie = self.tree.GetNextChild(self.rootID, moteCookie)


    def _configure(self, obj):
        """
        Configure registers in mote
        
        @param obj:  Mote or parameter to be configured
        """
        if obj is not None:
            if obj.__class__.__name__ == "XmlDevice":
                mote = None
                regs = obj.getRegList(True)
                if regs is not None:
                    for reg in regs:                        
                        dialog = ParamDialog(self, reg)                        
                        dialog.Destroy()
                    # Does this device need to enter SYNC mode first?
                    if obj.pwrdownmode == True:
                        res = self._WaitForSync()
                        if not res:
                            return
                        mote = self._moteinsync           
                    # Send new configuration to mote
                    if mote is not None:
                        for reg in regs:
                            if mote.cmdRegisterWack(reg.id, reg.value) == False:
                                self._Warning("Unable to set register \"" + reg.name + "\" in device " + str(reg.getAddress()))
                                break
            elif obj.__class__.__name__ == "SwapMote":
                mote = obj
                if mote.lstcfgregs is not None:
                    for reg in mote.lstcfgregs:
                        dialog = ParamDialog(self, reg)
                        dialog.Destroy()
                    # Does this device need to enter SYNC mode first?
                    if mote.definition.pwrdownmode == True:
                        res = self._WaitForSync()
                        if not res:
                            return
                        mote = self._moteinsync           
                    # Send new configuration to mote
                    if mote is not None:
                        for reg in mote.lstcfgregs:
                            if mote.cmdRegisterWack(reg.id, reg.value) == False:
                                self._Warning("Unable to set register \"" + reg.name + "\" in device " + str(reg.getAddress()))
                                break              
            elif obj.__class__.__name__ == "SwapRegister":
                dialog = ParamDialog(self, obj)
                dialog.Destroy()
                mote = obj.mote
                # Does this device need to enter SYNC mode first?
                if mote.definition.pwrdownmode == True:
                    res = self._WaitForSync()
                    if not res:
                        return
                    mote = self._moteinsync
                    
                # Send new configuration to mote
                if mote is not None:
                    if mote.cmdRegisterWack(obj.id, obj.value) == False:
                        self._Warning("Unable to set register \"" + obj.name + "\" in device " + str(obj.getAddress()))
            
            # Mote still in SYNC mode?
            if self._moteinsync is not None:
                if self._moteinsync.state == SwapState.SYNC:
                    # Leave SYNC mode
                    self._moteinsync.leaveSync()
                    self._moteinsync = None
                                
        
    def syncReceived(self, mote):
        """
        SYNC signal received
        
        @param mote  Mote having entered the SYNC mode
        """
        if self._waitfor_syncdialog is not None:
            self._moteinsync = mote
            self._waitfor_syncdialog.close()
             
    
    def _Warning(self, message, caption = "Warning!"):
        """
        Display warning message
        """
        dialog = wx.MessageDialog(self, message, caption, wx.OK | wx.ICON_WARNING)
        dialog.ShowModal()
        dialog.Destroy()


    def _Info(self, message, caption = "Attention!"):
        """
        Show Information dialog with custom message
        """
        dialog = wx.MessageDialog(self, message, caption, wx.OK | wx.ICON_INFORMATION)
        dialog.ShowModal()
        dialog.Destroy()


    def _WaitForSync(self):
        """
        Show Waiting dialog and wait until a SYNC message is received
        """
        self._waitfor_syncdialog = WaitDialog(self, "Please, put your device in SYNC mode")
        result = self._waitfor_syncdialog.ShowModal() != wx.ID_CANCEL
        self._waitfor_syncdialog.Destroy()
        self._waitfor_syncdialog = None
        return result
           

    def _YesNo(self, question, caption = 'Yes or no?'):
        """
        Show YES/NO dialog with custom question
        """
        dialog = wx.MessageDialog(self, question, caption, wx.YES_NO | wx.ICON_QUESTION)
        result = dialog.ShowModal() == wx.ID_YES
        dialog.Destroy()
        return result


    def _OnAbout(self, evn):
        """
        Show About dialog
        """
        info = wx.AboutDialogInfo()
        info.SetIcon(wx.Icon('images/swapdmt.png', wx.BITMAP_TYPE_PNG))
        info.SetName(__appname__)
        info.SetVersion(__version__)
        info.SetDescription("SWAp Device Management Tool")
        info.SetCopyright('(C) 2011 panStamp')
        info.SetWebSite("http://www.panstamp.com")
        info.SetLicence("General Public License (GPL) version 2")
        info.AddDeveloper(__author__)
        wx.AboutBox(info)

        
    def _OnClose(self, evn):
        """
        Close browser
        """
        self.Close(True)


    def _OnCloseBrowser(self, evn):
        """
        Callback function called whenever the browser is closed
        """
        if self.monitor is not None:
            self.monitor.Destroy()
        if self.server is not None:
            self.server.stop()
        self.Destroy()
        self.parent.terminate()

