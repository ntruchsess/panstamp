## @mainpage SWAP Device Management Tool (Command line version)
# @section intro_sec Introduction
# SWAPdmt is management tool created to configure and monitor SWAP networks. This tool is entirely based on pyswap, our Python
# SWAP library. SWAPdmt can be used in different manners:
#
# - As a network sniffer: SWAPdmt lets you monitor wireless traffic in your SWAP network. This functionality is specially useful
# when developing new SWAP devices.
# - As an event monitor: SWAPdmt continuously listens the network and notifies the user about any new event occurred (new mote
# detected, endpoint value change, etc).
# - As a configuration tool for wireless motes. SWAPdmt can be used to change network addresses, frequency channels and any custom
# parameter related to any physical device in the network
#
# @section requi_sec Requirements
# SWAPdmt needs at least Python 2.6 to work. You will also have to configure settings.xml, serial.xml and network.xml before
# running this tool
#
# @section howto_sec How to use SWAPdmt
# You can run <em>python pyswapdmt.py -h</em> anytime in order to get a short description about the available working options. In general,
# you'll maybe want to fully monitor your SWAP network as follows:
#
# <em>python pyswapdmt.py --sniff --monitor</em>
#
# Or maybe change a mote address given its current address:
#
# <em>python pyswapdmt.py -a 25 -n 35</em>
#
# Or simply configure every custom parameter defined for a given product type (ex: chronos):
#
# <em>python pyswapdmt.py --config --device=chronos</em>
#
# Visit our wiki for more information: @link http://code.google.com/p/panstamp/wiki/SWAPdmt

