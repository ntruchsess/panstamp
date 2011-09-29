#########################################################################
#
# NetworkDialog
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
__author__= "Daniel Berenguer"
__date__  = "$Sep 22, 2011 5:02:58 PM$"
#########################################################################

from xmltools.XmlSettings import XmlSettings
from xmltools.XmlNetwork import XmlNetwork

from ConfigDialog import ConfigDialog
from validators import TextValidator

import wx

class NetworkDialog(ConfigDialog):
    """
    Network configuration dialog
    """
    def _createControls(self):
        """
        Create GUI controls
        """
        # Add controls to the layout
        self.addToLayout(wx.TextCtrl(self, validator=TextValidator(self, "freqChannel"), size=(200, 26)), "Frequency channel")
        self.addToLayout(wx.TextCtrl(self, validator=TextValidator(self, "netId")), "Network ID")
        self.addToLayout(wx.TextCtrl(self, validator=TextValidator(self, "devAddress")), "Device address")
        self.addToLayout(wx.TextCtrl(self, validator=TextValidator(self, "security")), "Security option")
        self.addOkCancelButtons()
        

    def __init__(self, parent=None, devAddr=255, netId=0xB547, freqChann=0, secu=0):
        """
        Class constructor

        'parent'    Parent object
        """
        ConfigDialog.__init__(self, parent, title="Network settings")
        # Configuration settings
        self.config = XmlNetwork(XmlSettings.networkFile)
        # SWAP device address
        self.devAddress = devAddr
        # SWAP Network ID
        self.netId = netId
        # Frequency channel
        self.freqChannel = freqChann
        # Security option
        self.security = secu
        # Create widgets
        self._createControls()
        # Layout widgets
        self.doLayout()
        # Fit dialog size to its contents
        self.Fit()
        # Display dialog
        self.ShowModal()
