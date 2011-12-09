#########################################################################
#
# XmlDevice
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
__xmldirfile__ = "devices.xml"
#########################################################################

from xmltools.XmlSettings import XmlSettings
from swap.SwapParam import SwapCfgParam, SwapEndpoint
from swap.SwapRegister import SwapRegister
from swap.SwapValue import SwapValue
from swap.SwapDefs import SwapType
from SwapException import SwapException

import os
import xml.etree.ElementTree as xml


class DeviceEntry:
    """
    Class representing a device entry in a device directory
    """
    def __init__(self, id, option, label):
        """
        Class constructor
        
        @param id: Product ID
        @param option: Command-line alias
        @param label: GUI label
        """
        ## Product ID
        self.id = id
        ## Command-line alias
        self.option = option
        ## GUI label
        self.label = label


class DeveloperEntry:
    """
    Class representing a device directory for a given developer
    """
    def addDevice(self, device):
        """
        Add device entry to the list for the current developer
        
        @param device: Device or mote to be added to the list
        """
        self.devices.append(device)
        
    def __init__(self, id, name):
        """
        Class constructor
        
        @param id: Developer ID
        @param name: Name of the developer or manufacturer
        """
        ## Developer ID
        self.id = id
        ## Developer or manufacturer name
        self.name = name
        ## List of device entries for the current developer
        self.devices = []


class XmlDeviceDir(object):
    """
    Class implementing directory files linking device names with
    its corresponding description files
    """

    def read(self):
        """
        Read configuration file
        """
        # Parse XML file
        tree = xml.parse(self.fileName)
        if tree is None:
            return
        # Get the root node
        root = tree.getroot()
        # List of developers
        lstElemDevel = root.findall("developer")
        if lstElemDevel is not None:
            for devel in lstElemDevel:
                # Get developer id
                strDevelId = devel.get("id")
                if strDevelId is None:
                    raise SwapException("Developer section needs a valid ID in " + __xmldirfile__)
                    return
                develId = int(strDevelId)
                # Get developer name
                strDevelName = devel.get("name")
                if strDevelName is None:
                    raise SwapException("Developer section needs a name in " + __xmldirfile__)
                    return
                # Create developer entry
                developer = DeveloperEntry(develId, strDevelName)

                # Parse devices belonging to this developer
                lstDevs = devel.findall("dev")
                if lstDevs is not None:
                    for dev in lstDevs:
                        # Get product id
                        strProdId = dev.get("id")
                        if strProdId is None:
                            raise SwapException("Device section needs a valid ID in " + __xmldirfile__)
                            return
                        prodId = int(strProdId)
                        # Get command-line option
                        strOption = dev.get("option")
                        if strOption is None:
                            raise SwapException("Device section needs a comman-line option in " + __xmldirfile__)
                            return
                        # Get GUI label
                        strLabel = dev.get("label")
                        if strLabel is None:
                            raise SwapException("Device section needs a label in " + __xmldirfile__)
                            return
                        # Create device entry
                        device = DeviceEntry(prodId, strOption, strLabel)
                        # Add device to the developer entry
                        developer.addDevice(device)
                # Append developer to the list
                self.developers.append(developer)


    def getDeviceDef(self, option):
        """
        Return mote definition data (XmlDevice object) given a
        command-line option passed as argument
        
        @param option: Command-line option string
        
        @return Device definition object
        """
        for devel in self.developers:
            for dev in devel.devices:
                if option.lower() == dev.option:
                    return XmlDevice(manufId=devel.id, prodId=dev.id)
        return None


    def __init__(self):
        """
        Class constructor
        """
        ## Path to the configuration file
        self.fileName = XmlSettings.deviceDir + os.sep + __xmldirfile__
        ## List of devices
        self.developers = []
        # Parse document
        self.read()

        
class XmlUnit:
    """
    Endpoint units appearing in any XmlDevice object
    """
    def __init__(self, name="", factor=1, offset=0):
        """
        Class constructor
        
        @param name: Name of the unit
        @param factor: Factor conversion operand
        @param offset: Offset conversion operand
        """
        ## Unit name
        self.name = name
        # Factor operator
        try:
            ## Factor operand
            self.factor = int(factor)
        except ValueError:
            self.factor = float(factor)
        # Offset operator
        try:
            ## Offset operand
            self.offset = int(offset)
        except ValueError:
            self.offset = float(offset)
      

class XmlDevice(object):
    """
    Device configuration settings
    """

    def getDefinition(self):
        """
        Read current configuration file
        """
        # Parse XML file
        tree = xml.parse(self.fileName)
        if tree is None:
            raise IOError(self.fileName  + " does not exist")
        # Get the root node
        root = tree.getroot()
        # Get manufacturer
        elem = root.find("developer")
        if elem is not None:
            self.manufacturer = elem.text
        # Get product name
        elem = root.find("product")
        if elem is not None:
            self.product = elem.text
        # Get Power Down flag
        elem = root.find("pwrdownmode")
        if elem is not None:
            self.pwrdownmode = (elem.text.lower() == "true")
        # Get periodic tx interval
        elem = root.find("txinterval")
        if elem is not None:
            self.txinterval = int(elem.text)


    def getRegList(self, config=False):
        """
        Return list of registers

        @param config: Set to True if Configuration register are required. False for regular ones

        @return List of registers
        """
        # List of config registers belonging to the current device
        lstRegs = []

        # Parse XML file
        tree = xml.parse(self.fileName)
        if tree is None:
            return None
        # Get the root node
        root = tree.getroot()
        # Get manufacturer

        # List of register elements belonging to the device
        regtype = "regular"
        if config == True:
            regtype = "config"
        lstElemReg = root.findall(regtype + "/reg")
        if lstElemReg is not None:
            for reg in lstElemReg:
                # Get register id
                strRegId = reg.get("id")
                if strRegId is not None:
                    regId = int(strRegId)
                    # Get register name
                    regName = reg.get("name", default="")
                    # Create register from id and mote
                    swRegister = SwapRegister(self.mote, regId, regName)

                    # List of endpoints belonging to the register
                    if config == True:
                        elementName = "param"
                    else:
                        elementName = "endpoint"
                    lstElemParam = reg.findall(elementName)
                    for param in lstElemParam:
                        # Read XML fields
                        paramType = param.get("type", default="num")
                        paramDir = param.get("dir", default="inp")
                        paramName = param.get("name", default="")
                        paramPos = "0"
                        elem = param.find("position")
                        if elem is not None:
                            paramPos = elem.text
                        paramSize = "1"
                        elem = param.find("size")
                        if elem is not None:
                            paramSize = elem.text
                        paramDef = "0"
                        elem = param.find("default")
                        if elem is not None:
                            paramDef = elem.text
                        if paramType in [SwapType.NUMBER, SwapType.BINARY]:
                            try:
                                defVal = int(paramDef)
                            except ValueError:
                                raise SwapException("Default value " + str(paramDef) + " is not an integer")
                                return
                        else:
                            defVal = paramDef
                        verif = None
                        elem = param.find("verif")
                        if elem is not None:
                            verif = elem.text
                        # Get list of units
                        units = param.findall("units/unit")
                        lstUnits = None
                        if units is not None:
                            lstUnits = []
                            for unit in units:
                                name = unit.get("name", default=None)
                                factor = unit.get("factor", default=1)
                                offset = unit.get("offset", default=0)
                                xmlUnit = XmlUnit(name, factor, offset)
                                lstUnits.append(xmlUnit)

                        if config == True:
                            # Create SWAP config parameter
                            swParam = SwapCfgParam(register=swRegister, pType=paramType, name=paramName,
                                            position=paramPos, size=paramSize, default=defVal, verif=verif)
                        else:                          
                            # Create SWAP endpoint
                            swParam = SwapEndpoint(register=swRegister, pType=paramType, direction=paramDir, name=paramName,
                                            position=paramPos, size=paramSize, default=defVal, verif=verif, units=lstUnits)

                        # Add current parameter to the register
                        swRegister.add(swParam)

                    # Create empty value for the register
                    swRegister.value = SwapValue([0] * swRegister.getLength())
                    swRegister.update()                    
                    # Add endpoint to the list
                    lstRegs.append(swRegister)

        if len(lstRegs) == 0:
            return None
        else:
            return lstRegs


    def __init__(self, mote=None, manufId=None, prodId=None):
        """
        Class constructor
        
        @param mote: Real mote object
        @param manufId: Manufacturer ID
        @param prodId: Product ID
        """
        ## Device (mote)
        self.mote = mote
        ## Name/path of the current configuration file
        self.fileName = None
        if manufId is not None and prodId is not None:
            self.fileName = XmlSettings.deviceDir + os.sep + "{0:X}".format(manufId) + os.sep + "{0:X}".format(prodId) + ".xml"
        ## Name of the Manufacturer
        self.manufacturer = None
        ## Name of the Product
        self.product = None
        ## Power down mode (True or False). If True, the mote sleeps most of the times
        self.pwrdownmode = False
        ## Interval (in sec) between periodic transmissions. 0 for disabled
        self.txinterval = 0

        if self.mote is not None:
            self.fileName = XmlSettings.deviceDir + os.sep + "{0:X}".format(self.mote.manufacturerId) + os.sep + "{0:X}".format(self.mote.productId) + ".xml"

        # Read definition parameters from XML file
        self.getDefinition()
