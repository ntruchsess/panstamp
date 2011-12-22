#########################################################################
#
# XmlDevices
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
__date__ ="$Nov 4, 2011 12:26:00 PM$"
#########################################################################

import xml.etree.ElementTree as xml
     

class XmlDevices:
    """
    User config parameters for every value being managed by HouseAgent
    """

    def read(self):
        """
        Read list of values being accepted by HouseAgent from config file
        """
        # List of values
        self.values = {}

        # Parse XML file
        tree = xml.parse(self.filename)
        if tree is None:
            return None
        # Get the root node
        root = tree.getroot()

        # List of register elements belonging to the device
        lstdevs = root.findall("dev")
        if lstdevs is not None:
            for dev in lstdevs:
                # Get device address
                straddr = dev.get("address")
                if straddr is not None:
                    addr = int(straddr)
                    # List of endpoints belonging to the device
                    lstendp = dev.findall("value")
                    value = {}                    
                    for endp in lstendp:
                        # measurement unit
                        elem = endp.find("unit")
                        if elem is not None:
                            unit = elem.text
                        else:
                            unit = ""
                        # endpoint name     
                        value[endp.get("name")] = unit
                                                                   
                    self.values[addr] = value


    def save(self):
        """
        Save list of values being accepted by HouseAgent to config file
        """
        f = open(self.filename, 'w')
        f.write("<?xml version=\"1.0\"?>\n")
        f.write("<devices>\n")

        for addr, values in self.values.items():
            f.write("\t<dev address=\"" + str(addr) + "\">\n")
            for name, unit in values.items():
                f.write("\t\t<value name=\"" + name + "\">\n")
                if unit != "":
                    f.write("\t\t\t<unit>" + unit + "</unit>\n")
                f.write("\t\t</value>\n")
            f.write("\t</dev>\n")
        f.write("</devices>\n")
        f.close()            

    
    def getValues(self, addr):
        """
        Get values from dictionary for a given address
        
        @param addr: device address
        
        @return list of value:unit tuples
        """
        return self.values[addr]
    
    
    def setValues(self, addr, values):
        """
        Set/Add values in dictionary for a given address
        
        @param addr: device address
        @param values: list of value:unit tuples
        """        
        self.values[addr] = values

        
    def __init__(self, filename=None):
        """
        Class constructor
        
        @param filename: Name fo the config file
        """
        ## File name
        self.filename = filename
        if self.filename is None:
            self.filename = "devices.xml"
            
        ## List of values
        self.values = {}
        
        # Read config file
        try:
            self.read()
        except:
            pass
