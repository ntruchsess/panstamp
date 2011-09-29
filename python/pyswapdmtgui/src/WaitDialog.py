#########################################################################
#
# WaitDialog
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
__date__  ="$Sep 21, 2011 08:58:05 AM$"
#########################################################################

from ConfigDialog import ConfigDialog

import wx

class WaitDialog(ConfigDialog):
    """
    Waiting dialog class
    """
    def _createControls(self):
        """
        Create GUI controls
        """
        # Add control for every parameter contained in the register
        self.addToLayout(None, self.message)
        # Add cancel button
        self.addCancelButton()


    def close(self):
        """
        Close dialog
        """
        self.EndModal(wx.ID_OK) 
        
                
    def __init__(self, parent=None, message=None):
        """
        Class constructor

        'parent'     Parent object
        'message'    Message to be displayed
        """
        ConfigDialog.__init__(self, parent, title="Waiting...")
        # Message to be displayed
        self.message = message
        # Create widgets
        self._createControls()
        # Layout widgets
        self.doLayout()
        # Fit dialog size to its contents
        self.Fit()
