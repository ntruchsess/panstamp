#########################################################################
#
# XmlSettings
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

class XmlSettings(object):
    """
    Main configuration settings: config files and directories
    """
    ## Name/path of the current configuration file
    file_name = "settings.xml"
    ## Name/path of the serial configuration file
    serial_file = "serial.xml"
    ## Name/path of the wireless network configuration file
    network_file = "network.xml"
    ## Directory where all device config files are stored
    deviceDir = "devices"
    ## Name/path of the error log file
    error_file = "error.log"

    def read(self):
        """
        Read configuration file file
        """
        # Parse XML file
        tree = xml.parse(XmlSettings.file_name)
        if tree is None:
            return
        # Get the root node
        root = tree.getroot()
        # Get "devices" folder
        elem = root.find("devices")
        if elem is not None:
            XmlSettings.deviceDir = elem.text
        # Get serial config file
        elem = root.find("serial")
        if elem is not None:
            XmlSettings.serial_file = elem.text
        # Get serial config file
        elem = root.find("network")
        if elem is not None:
            XmlSettings.network_file = elem.text
        # Get path name of the error log file
        elem = root.find("errlog")
        if elem is not None:
            XmlSettings.error_file = elem.text


    def save(self):
        """
        Save current configuration file in disk
        """
        # XML root
        root = xml.Element("settings")
        # "devices" element
        elem = xml.Element("devices", text=XmlSettings.deviceDir)
        root.append(elem)
        # "serial" element
        elem = xml.Element("serial", text=XmlSettings.serial_file)
        root.append(elem)
        # "network" element
        elem = xml.Element("network", text=XmlSettings.network_file)
        root.append(elem)
        # "network" element
        elem = xml.Element("errlog", text=XmlSettings.error_file)
        root.append(elem)
        # XML doc
        doc = xml.ElementTree(root)
        # Write XML doc
        file = open(XmlSettings.file_name, 'w')
        doc.write(file)
        file.close()
        
    def __init__(self, file_name="settings.xml"):
        """
        Class constructor
        
        @param filename: Path to the configuration file
        """
        # Name/path of the current configuration file
        XmlSettings.file_name = file_name
        # Read XML file
        self.read()

  
