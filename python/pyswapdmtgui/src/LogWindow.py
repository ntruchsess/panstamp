#########################################################################
#
# LogWindow
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
__date__  = "$Sep 23, 2011 10:28:31 AM$"
#########################################################################

import wx
import sys, time


class LogFrame(wx.Frame):
    """
    Frame subclass used to log events
    """
    def write(self, text):
        """
        Add new line into the log window
        
        @param text: Text string to be displayed in the log window
        """
        if text:
            if len(text) > 1: # Condition added to avoid printing single white spaces
                if text.startswith("Rved: "):                    
                    msg = text[6:]
                    msgtype = self.get_message_type(msg)
                    if msgtype is None:
                        return
                    image = self.arrow_left_icon
                elif text.startswith("Sent: "):
                    msgtype = "sent"
                    msg = text[6:-1]
                    msgtype = self.get_message_type(msg)
                    if msgtype is None:
                        return
                    image = self.arrow_right_icon
                elif text.startswith("SwapException occurred: "):
                    msgtype = "ERROR"
                    msg = text[24:]
                    image = self.warning_icon
                else:
                    return

                index = self.log.GetItemCount()
                self.log.InsertStringItem(index, str(time.time()))
                self.log.SetStringItem(index, 1, msgtype)
                self.log.SetStringItem(index, 2, msg)
                self.log.SetItemImage(index, image)
                self.log.EnsureVisible(index)

    
    def get_message_type(self, msg):
        """
        Get the type of message received or being sent
        
        @param msg: SWAP message
        
        @return Type of message in string format
        """
        if len(msg) < 14:
            return None

        if msg[0] == '(':
            if msg[5] == ')':
                shift = 6
            else:
                return None
        else:
            shift = 0
            
        msgtype = msg[8+shift:10+shift]

        if msgtype == "00":
            return "status"
        elif msgtype == "01":
            return "query"
        elif msgtype == "02":
            return "command"

        return None

    
    def _OnClose(self, evn):
        """
        This function is automatically called before closing the window
        """
        self.Show(False)
    

    def _display_info(self):
        """
        Show Information dialog about the selected line
        """
        err = False
        # Get current selection from list
        index = self.log.GetFirstSelected()
        timestamp = self.log.GetItem(index, 0).GetText()
        msgtype = self.log.GetItem(index, 1).GetText()
        packet = self.log.GetItem(index, 2).GetText()
               
        text = "Time: " + timestamp + "\n"
        text += "Type of packet: " + msgtype + "\n"
        
        if packet[0] == '(':
            if packet[5] == ')':
                text += "RSSI: " + packet[1:3] + "\n"
                text += "LQI: " + packet[3:5] + "\n"
                shift = 6
            else:
                text = "Message malformed"
                err = True
        else:
            shift = 0
        
        if not err:
            destaddr = packet[shift:shift+2]
            if destaddr == "00":
                destaddr = "broadcast"
            text += "Destination address: " + destaddr + "\n"
            text += "Source address: " + packet[shift+2:shift+4] + "\n"
            text += "Transmission hop: " + packet[shift+4:shift+5] + "\n"
            text += "Security: " + packet[shift+5:shift+6] + "\n"
            text += "Security nonce: " + packet[shift+6:shift+8] + "\n"
            text += "Register address: " + packet[shift+10:shift+12] + "\n"
            text += "Register ID: " + packet[shift+12:shift+14] + "\n"
            if len(packet) > 14:
                text += "Register value: " + packet[shift+14:] + "\n"
        
        dialog = wx.MessageDialog(self, text, "Details", wx.OK | wx.ICON_INFORMATION)
        dialog.ShowModal()
        dialog.Destroy()
        
        
    def _cb_right_click(self, evn):
        """
        Mouse right click on log list
        
        @param evn: Event received
        """
        index = self.log.GetFirstSelected()
        if index > -1:
            msgtype = self.log.GetItem(index, 1).GetText()
            if msgtype != "ERROR":        
                menu = wx.Menu()
                menu.Append(0, "Show details")
                wx.EVT_MENU(menu, 0, self._cb_on_details)
                self.PopupMenu(menu, evn.GetPoint())
                menu.Destroy()


    def _cb_on_details(self, evn):
        """
        Display packet details
        
        @param evn: Event received
        """
        self._display_info()
        

    def __init__(self, tittle):
        """
        Class constructor
        """
        wx.Frame.__init__(self, None, -1, tittle)    

        favicon = wx.Icon("images/swap.ico", wx.BITMAP_TYPE_ICO, 16, 16)
        self.SetIcon(favicon)
        
        # Create list box
        #self.log = wx.ListCtrl(self, -1, style=wx.LC_REPORT, size=wx.Size(590,490))
        self.log = wx.ListCtrl(self, -1, style=wx.LC_REPORT, size=wx.Size(590,490))
        self.log.ScrollList(10, 10)
        self.log.InsertColumn(0, "Timestamp")
        self.log.InsertColumn(1, "Type")
        self.log.InsertColumn(2, "Message")
        self.log.SetColumnWidth(0, 140)
        self.log.SetColumnWidth(1, 60)
        self.log.SetColumnWidth(2, 400)

        # Create sizer
        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(self.log, 0, wx.EXPAND)
        self.SetSizer(sizer)
        self.SetSize((600, 500))
        
        # Redirect stdout to the LogCtrl widget
        sys.stdout = RedirectText(self)
        # Run function before closing
        self.Bind(wx.EVT_CLOSE, self._OnClose)

        # create the image list:
        il = wx.ImageList(16, 16)
        self.arrow_left_icon = il.Add(wx.Bitmap("images/arrow_left.ico", wx.BITMAP_TYPE_ICO))
        self.arrow_right_icon = il.Add(wx.Bitmap("images/arrow_right.ico", wx.BITMAP_TYPE_ICO))
        self.warning_icon = il.Add(wx.Bitmap("images/warning.ico", wx.BITMAP_TYPE_ICO))
        self.log.AssignImageList(il, wx.IMAGE_LIST_SMALL)
        
        # Right-click event
        wx.EVT_LIST_ITEM_RIGHT_CLICK(self.log, -1, self._cb_right_click)
        

class RedirectText(object):
    """
    Class for redirecting text to a given widget
    """
    def __init__(self, widget):
        self.out = widget
 
    def write(self, string):
        if self.out is not None:
            wx.CallAfter(self.out.write, string)
