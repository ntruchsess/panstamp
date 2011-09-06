#########################################################################
#
# XmlNetwork
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

import xml.etree.ElementTree as xml

class XmlNetwork(object):
    """Wireless network configuration settings"""
    def read(self):
        """ Read config file"""
        # Parse XML file
        tree = xml.parse(self.fileName)
        if tree is None:
            return
        # Get the root node
        root = tree.getroot()
        # Get frequency channel
        elem = root.find("channel")
        if elem is not None:
            self.freqChannel = int(elem.text)
        # Get Network ID
        elem = root.find("netid")
        if elem is not None:
            self.NetworkId = int(elem.text, 16)
        # Get device address
        elem = root.find("address")
        if elem is not None:
            self.devAddress = int(elem.text)
        # Get device address
        elem = root.find("security")
        if elem is not None:
            self.security = int(elem.text)
    
    def save(self):
        """ Save network settings in file"""
        # XML root
        root = xml.Element("network")
        # "channel" element
        elem = xml.Element("channel", text=str(self.freqChannel))
        root.append(elem)
        # "netid" element
        elem = xml.Element("netid", text=str(self.NetworkId))
        root.append(elem)
        # "address" element
        elem = xml.Element("address", text=str(self.devAddress))
        root.append(elem)
        # "security" element
        elem = xml.Element("security", text=str(self.security))
        root.append(elem)
        # XML doc
        doc = xml.ElementTree(root)
        # Write XML doc
        file = open(XmlSettings.fileName, 'w')
        doc.write(file)
        file.close()
    
    def __init__(self, fileName="network.xml"):
        # Name/path of the current configuration file
        self.fileName = fileName
        # Frequency channel
        self.freqChannel = 0
        # Network identifier (synchronization word)
        self.NetworkId = 0xB547
        # Device address
        self.devAddress = 1
        # Security option
        self.security = 0
        # Read XML file
        self.read()
  
