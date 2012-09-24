#!/usr/bin/python
#########################################################################
#
# pluginSwap
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
__author__ = "Daniel Berenguer"
__date__ = "$Sep 6, 2011 2:53:32 PM$"
__appname__ = "pluginSwap"
__version__ = "1.0"
#########################################################################

from SwapManager import SwapManager
from SwapException import SwapException

import sys

if __name__ == "__main__":
    """
    Run SWAP daemon for HouseAgent"
    """
    
    settings_file = None
    
    if len(sys.argv) > 1:
        if sys.argv[1] == '-f':
            settings_file = sys.argv[2]
    
    # SWAP stuff here...
    try:
        # Start SWAP manager tool
        manager = SwapManager(settings_file, True, True)
    except SwapException as ex:
        ex.display()
        ex.log()
