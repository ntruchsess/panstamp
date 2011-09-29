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
import wx.stc as stc
import sys

class LogCtrl(stc.StyledTextCtrl):
    """
    Subclass the StyledTextCtrl to provide  additions
    and initializations to make it useful as a log window.

    """
    def __init__(self, parent, style=wx.SIMPLE_BORDER):
        """
        Constructor
        
        """
        stc.StyledTextCtrl.__init__(self, parent, style=style)
        self._styles = [None]*32
        self.SetReadOnly(True)
        self._free = 1


    def getStyle(self, c='black'):
        """
        Returns a style for a given colour if one exists.  If no style
        exists for the colour, make a new style.
        
        If we run out of styles, (only 32 allowed here) we go to the top
        of the list and reuse previous styles.

        """
        free = self._free
        if c and isinstance(c, (str, unicode)):
            c = c.lower()
        else:
            c = 'black'

        try:
            style = self._styles.index(c)
            return style

        except ValueError:
            style = free
            self._styles[style] = c
            self.StyleSetForeground(style, wx.NamedColour(c))

            free += 1
            if free >31:
                free = 0
            self._free = free
            return style


    def write(self, text, c=None):
        """
        Add the text to the end of the control using colour c which
        should be suitable for feeding directly to wx.NamedColour.
        
        'text' should be a unicode string or contain only ascii data.
        """
        self.SetReadOnly(False)
        style = self.getStyle(c)
        lenText = len(text.encode('utf8'))
        end = self.GetLength()
        self.SetCurrentPos(end)     
        self.AddText(text)
        self.StartStyling(end, 31)
        self.SetStyling(lenText, style)
        self.EnsureCaretVisible()
        self.SetReadOnly(True)


    __call__ = write
    
    
class LogPanel(wx.Panel):
    '''
    Panel subclass used to log events
    '''
    def __init__(self, parent, log):
        '''
        Class Constructor
        
        'parent'    Parent object
        'log'       LogCtrl object
        '''
        wx.Panel.__init__(self, parent, -1)
        self.log = log


class LogFrame(wx.Frame):
    """
    Frame subclass used to log events
    """
    def write(self, text, color="black"):
        """
        Add new line into the log window
        """
        if text.find("Sent") >= 0:
            self.log(text, "green")
        elif text.find("Rved") >= 0:
            self.log(text, "black")
        elif text.find("SwapException") >= 0:
            self.log(text, "red")
        else:
            self.log(text, "blue")

    
    def _OnClose(self, evn):
        """
        This function is automatically called before closing the window
        """
        self.Show(False)
        #self = None
        
        
    def __init__(self, tittle):
        """
        Class constructor
        """
        wx.Frame.__init__(self, None, -1, tittle)

        self.log = LogCtrl(self)
        lp = LogPanel(self, self.log)
        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(lp, 0, wx.EXPAND)
        sizer.Add(self.log, 1, wx.EXPAND)
        self.SetSizer(sizer)
        self.SetSize((500, 500))
        # Redirect stdout to the LogCtrl widget
        sys.stdout = RedirectText(self)
        # Run function before closing
        self.Bind(wx.EVT_CLOSE, self._OnClose)


class RedirectText(object):
    """
    Class for redirecting text to a given widget
    """
    def __init__(self, widget):
        self.out = widget
 
    def write(self, string):
        if self.out is not None:
            wx.CallAfter(self.out.write, string)
        
        
if __name__=="__main__":
    app = wx.PySimpleApp()
    win = LogFrame()
    win.Show(True)
    app.MainLoop()
