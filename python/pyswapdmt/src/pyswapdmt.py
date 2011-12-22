#########################################################################
#
# pyswapdmt
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
__date__ = "$Aug 20, 2011 10:36:00 AM$"
__appname__ = "SWAPdmt (command line version)"
__version__ = "1.0"
#########################################################################

from SwapManager import SwapManager
from SwapException import SwapException
from xmltools.XmlDevice import XmlDeviceDir

from optik import OptionParser


def _quit():
    """ Quit application """
    print __appname__ + " terminated"
    # Stop SWAP manager
    manager.stop()
    # Exit application
    raise SystemExit


if __name__ == "__main__":
    """ Command-line SWAP Device Management Tool """
    print __appname__

    parser = OptionParser()
    # Print version
    parser.add_option("--version", action="store_true", default="False", dest="version",
                      help="Print version number")
    # Monitor network activity
    parser.add_option("--monitor", action="store_true", default="False", dest="monitor",
                      help="Monitor SWAP network activity")
    # Sniff SWAP network
    parser.add_option("--sniff", action="store_true", default="False", dest="sniff",
                      help="Sniff SWAP network")
    # Configure device
    parser.add_option("-c", "--config", action="store_true", default="False", dest="config",
                      help="Configure SWAP device")
    parser.add_option("-d", "--device", type="string", dest="device",
                      help="Product name")

    # Address of the target device
    parser.add_option("-a", "--address", type="int", dest="devAddr",
                      help="Address of the target device (1-255). Ommit for sync mode")

    # Access standard parameters
    # New address
    parser.add_option("-n", "--newaddr", type="int", dest="newAddr",
                      help="Set new address (1-255)")
    # Network id
    parser.add_option("-i", "--netid", type="string", dest="netId",
                      help="Network ID (2-byte hexadecimal)")
    # Frequency channel
    parser.add_option("-f", "--freqchannel", type="int", dest="freq_channel",
                      help="Frequency channel")
    # Security option
    parser.add_option("-x", "--secoption", type="int", dest="security",
                      help="Security option (0 for no security)")
    # Periodic Tx interval
    parser.add_option("-p", "--interval", type="int", dest="txinterval",
                      help="Periodic Tx interval")

    # Or address unitary registers
    # Register id
    parser.add_option("-r", "--regid", type="int", dest="regId",
                      help="Register ID")
    # Register value
    parser.add_option("-v", "--value", type="string", dest="value",
                      help="Register value)")

    (options, args) = parser.parse_args()   

    # Dispatch commands
    if options.version == True:
        print __version__
        raise SystemExit

    try:
        # Start SWAP manager tool
        manager = SwapManager(options.sniff, options.monitor)

        # Configuration commands
        if options.config == True:
            listCfgRegs = None
            setCustomReg = False
            # Device passed as argument?
            if options.device is not None:
                # Custom registers
                #-------------------
                # Get Develoepr/device directory from devices.xml
                devicedir = XmlDeviceDir()
                # Find our mote within the directory
                xmlMote = devicedir.getDeviceDef(options.device)
                if xmlMote is None:
                    print "Unable to find device \"" + options.device + "\" in directory"
                    _quit()      # Quit application
                listCfgRegs = xmlMote.getRegList(True)
                if listCfgRegs is None:
                    print "Unable to retrieve configuration parameters from mote"
                    _quit()      # Quit application

                for cfgReg in listCfgRegs:
                    print "-----------------------------------------------"
                    print cfgReg.name
                    print "-----------------------------------------------"
                    if cfgReg.lstItems is not None:
                        for cfgParam in cfgReg.lstItems:
                            print cfgParam.name + ": [" + str(cfgParam.default) + "]"
                            data = raw_input(">")
                            if data != "":
                                cfgParam.setValue(data)
                    # All parameters have been set
                    setCustomReg = True

            # Standard registers
            #--------------------
            # Device address
            devaddress = options.devAddr
            if devaddress is not None:
                # Get mote from address
                mote = manager.getMote(address=devaddress)
                # Is this mote a Power-Down device?
                if mote.definition.pwrdownmode:
                    devaddress = None   # Ask for SYNC
                    print "Device with address " + str(devaddress) + " is surely sleeping"

            inSyncMode = False
            if devaddress is None:
                # Address not specified. Ask for symc mode
                print "Put the device into SYNC mode..."
                while manager.getAddressInSync() is None:
                    pass
                devaddress = manager.getAddressInSync()
                manager.resetAddressInSync()
                inSyncMode = True

            # Get mote from address
            mote = manager.getMote(address=devaddress)
            if mote is None:
                print "Device with address " + str(devaddress) + " can't be found"
                _quit()      # Quit application

            # OK, we have now a valid mote

            # Frequency channel
            if options.freq_channel is not None:
                if options.freq_channel < 0:
                    print "Only positive channels please"
                if mote.setFreqChannel(options.freq_channel):
                    print "New frequency channel correctly set"

            # Security option
            if options.security is not None:
                if options.security < 0:
                    print "Only positive options please"
                if mote.setSecurity(options.security):
                    print "New security option correctly set"
                    
            # Periodic Tx interval
            if options.txinterval is not None:
                if options.txinterval < 0:
                    print "Only positive intervals please"
                if mote.setTxInterval(options.interval):
                    print "New periodic Tx interval correctly set"

            # Network id
            if options.netId is not None:
                if options.netId < 0:
                    print "Only positive ID's please"
                if mote.setNetworkId(options.netId):
                    print "New network id correctly set"

            # New device address
            if options.newAddr is not None:
                if options.newAddr < 0:
                    print "Only positive addresses please"
                if mote.setAddress(options.newAddr):
                    print "New device address correctly set"

            # Register ID
            if options.regId is not None:
                if options.regId < 0:
                    print "Only positive registers please"
                # Register value
                if options.value is not None:
                    # Change register
                    if manager.setMoteRegister(mote, options.regId, options.value):
                        print "Register modified successfully"
                    else:
                        print "Unable to modify remote register"
                else:
                    # Query register
                    val = manager.queryMoteRegister(mote, options.regId)
                    if val is not None:
                        print "Register value = " + val.toAsciiHex
                    else:
                        print "Unable to get remote register"

            # Set custom registers?
            if setCustomReg == True:
                for reg in listCfgRegs:
                    if mote.cmdRegisterWack(reg.id, reg.value) == False:
                        print "Unable to set register \"" + reg.name + "\" in device " + str(reg.getAddress())
                        break

            # Configuration completed?
            if mote is not None:
                if inSyncMode == True:
                    # Ask target device to leave the SYNC mode
                    if mote.leaveSync() == True:
                        inSyncMode = False
                else:
                    # Restart mote
                    mote.restart()
                _quit()      # Quit application

        # Close server if no monitoring action is pending
        if options.sniff == False and options.monitor == False:
            _quit()      # Quit application

    except SwapException as ex:
        ex.display()