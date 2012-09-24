#########################################################################
#
# SwapManager
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
__date__  ="$Aug 21, 2011 4:30:47 PM$"
#########################################################################

from XmlDevices import XmlDevices

from SwapInterface import SwapInterface
from swap.SwapDefs import SwapState, SwapType

from plugins.pluginapi import PluginAPI
from twisted.internet import reactor, defer

import datetime, ConfigParser


class SwapManager(SwapInterface):
    """
    SWAP Management Class
    """
    def newMoteDetected(self, mote):
        """
        New mote detected by SWAP server
        
        @param mote: Mote detected
        """
        if self._printSWAP == True:
            print "New mote with address " + str(mote.address) + " : " + mote.definition.product + \
            " (by " + mote.definition.manufacturer + ")"


    def newEndpointDetected(self, endpoint):
        """
        New endpoint detected by SWAP server
        
        @param endpoint: Endpoint detected
        """
        if self._printSWAP == True:
            print "New endpoint with Reg ID = " + str(endpoint.getRegId()) + " : " + endpoint.name

        # Set param units for this endpoint
        values = self.cfgdevices.getValues(endpoint.getRegAddress())
        if endpoint.name in values:
            endpoint.display = True
            if values[endpoint.name] != "":
                endpoint.setUnit(values[endpoint.name])


    def moteStateChanged(self, mote):
        """
        Mote state changed
        
        @param mote: Mote having changed
        """
        if self._printSWAP == True:
            print "Mote with address " + str(mote.address) + " switched to \"" + \
            SwapState.toString(mote.state) + "\""
        # SYNC mode entered?
        if mote.state == SwapState.SYNC:
            self._addrInSyncMode = mote.address        


    def moteAddressChanged(self, mote):
        """
        Mote address changed
        
        @param mote: Mote having changed
        """
        if self._printSWAP == True:
            print "Mote changed address to " + str(mote.address)


    def registerValueChanged(self, register):
        """
        Register value changed
        
        @param register: register object having changed
        """
        if self._printSWAP == True:
            print  "Register addr= " + str(register.getAddress()) + " id=" + str(register.id) + " changed to " + register.value.toAsciiHex()
        # Empty dictionary
        values = {}
        # For every endpoint contained in this register
        for endp in register.lstItems:
            strVal = endp.getValueInAscii()
            if endp.valueChanged:
                if self._printSWAP:
                    print endp.name + " in address " + str(endp.getRegAddress()) + " changed to " + strVal
                               
                if endp.display == True:
                    values[endp.name] = strVal
        
        if len(values) > 0:
            if self._pluginapi is not None:
                self._pluginapi.value_update(register.getAddress(), values)


    def cb_poweron(self, address):
        """
        This function is called when a poweron request has been received from the network.
        
        @param address: Address of the mote to be powered-on
        """
        addr = int(address)
        d = defer.Deferred()
        #self.manager.setNodeOn(self.home_id, node_id)
        d.callback('done!')
        return d

    def cb_poweroff(self, address):
        """
        This function is called when a poweroff request has been received from the network.
        
        @param address: Address of the mote to be powered-off
        """
        addr = int(address)
        d = defer.Deferred()
        #self.manager.setNodeOff(self.home_id, node_id)
        d.callback('done!')
        return d


    def cb_thermostat(self, address, setpoint):
        '''
        This callback function handles setting of thermostat setpoints.

        @param address: Address of the mote
        @param setpoint: the setpoint to set (float)
        '''
        d = defer.Deferred()

        """        
        node = self.get_node(self.home_id, int(node_id))
        if not isinstance(node, ZwaveNode):
            d.callback('error1') # Specified node not available
        else:
            for val in node.values:
                if val.value_data['commandClass'] == 'COMMAND_CLASS_THERMOSTAT_SETPOINT':
                    value_id = int(val.value_data['id'])
                    self.manager.setValue(value_id, float(setpoint))
                    d.callback('ok')
        """
        return d
    
    
    def cb_custom(self, action, parameters):
        """
        Handles several custom actions used througout the plugin.
        
        @param command: Custom command
        @param parameters: Custom command parameters
        
        @return Object requested
        """ 
        if action == 'get_networkinfo':
            motes = {}
            
            for index, mote in enumerate(self.server.lstMotes):
                moteInfo = {"address": mote.address,
                            "manufacturer": mote.definition.manufacturer,
                            "product": mote.definition.product,
                            "sleeping": mote.definition.pwrdownmode,
                            "lastupdate": datetime.datetime.fromtimestamp(mote.timestamp).strftime("%d-%m-%Y %H:%M:%S")}
                
                motes[index] = moteInfo
           
            d = defer.Deferred()
            d.callback(motes)
            return d
            
        
        elif action == "get_motevalues":
            values = {}
            
            devaddress = int(parameters["mote"])
            mote = self.server.getMote(address=devaddress)
            i = 0
            for reg in mote.lstregregs:
                for endp in reg.lstItems:                               
                    valueinfo = {"type": endp.type + " " + SwapType.toString(endp.direction),
                                 "name": endp.name,
                                 "value": endp.getValueInAscii(),
                                 "units": [],
                                 "unit": endp.unit.name }
                    if endp.lstunits is not None and len(endp.lstunits) > 0:
                        for unit in endp.lstunits:
                            valueinfo["units"].append(unit.name)
                
                    values[i] = valueinfo
                    i += 1
            
            d = defer.Deferred()
            d.callback(values)
            return d
            
        elif action == "track_values":
            '''
            With this command you can set certain SWAP values to be tracked, and send them to the master node.
            '''           
            address = parameters['mote']
            values = parameters['values']
                     
            self.cfgdevices.setValues(address, values)
            # Save config file
            self.cfgdevices.save()
            
            # Set units
            mote = self.getMote(address=address)
            for name, unit in values.items():
                if unit != "":           
                    param = mote.getParameter(name)
                    if param is not None:
                        param.display = True                      
                        param.setUnit(unit)
                                  
            # Update specified values right now
            report_values = {}
            i = 0
            mote = self.getMote(address=address)
            for reg in mote.lstregregs:
                for endp in reg.lstItems:
                    if endp.name in values:
                        report_values[endp.name] = endp.getValueInAscii()
                    i += 1
            
            self._pluginapi.value_update(address, report_values)
    
            # Return something anyway, even though we return nothing.
            d = defer.Deferred()
            d.callback('')
            return d
      

    def _readPluginConfig(self):
        """
        Read configuration parameters of the SWAP plugin
        """      
        config = ConfigParser.RawConfigParser()
        config.read('plugin.conf')
        
        self.broker_host = config.get('broker', 'host')
        self.broker_port = config.getint('broker', 'port')

        self.pluginId = config.get('general', 'id')
        self.loglevel = config.get('general', 'loglevel')
        
        # Read devices config file
        self.cfgdevices = XmlDevices()


    def __init__(self, settings=None, verbose=False, monitor=False):
        """
        Class constructor
        
        @param settings: path to the main configuration file
        @param verbose: Print out SWAP frames or not
        @param monitor: Print out network events or not
        """
        try:
            # Superclass call
            SwapInterface.__init__(self, settings, verbose)
        except:
            raise

        # Print SWAP activity
        self._printSWAP = monitor
        # Mote address in SYNC mode
        self._addrInSyncMode = None
        
        # Read plugin config
        self._readPluginConfig()
        
        # Declare HouseAgent callbacks
        callbacks = {'poweron': self.cb_poweron,
                     'poweroff': self.cb_poweroff,
                     'custom': self.cb_custom,
                     'thermostat_setpoint': self.cb_thermostat}
        
        # Start plugin
        self._pluginapi = PluginAPI(guid=self.pluginId, plugintype="SWAP", broker_host=self.broker_host, broker_port=self.broker_port, **callbacks)
        self._pluginapi.ready()
        reactor.run()
