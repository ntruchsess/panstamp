#########################################################################
#
# lagarto-speech
#
# Copyright (c) 2012 Daniel Berenguer <dberenguer@usapiens.com>
#
# This file is part of the lagarto project.
#
# lagarto  is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# lagarto is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with lagarto; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
# USA
#
#########################################################################
__author__="Daniel Berenguer"
__date__  ="$Oct 4, 2012$"
__appname__= "lagarto-speech"
__version__= "0.0.1"
#########################################################################

from speechmanager import SpeechManager

from lagartoresources import LagartoException

import os
import sys
import signal


def signal_handler(signal, frame):
    """
    Handle signal received
    """
    speech_listener.stop()
    sys.exit(0)
    
    
if __name__ == '__main__':
  
    # Catch possible SIGINT signals
    signal.signal(signal.SIGINT, signal_handler)
    
    try:
        print "Starting speech listener"
        SpeechManager()
    except LagartoException as ex:
        ex.display()
        
    signal.pause()

