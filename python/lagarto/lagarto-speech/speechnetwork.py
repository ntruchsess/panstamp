#########################################################################
#
# speechnetwork
#
# Copyright (c) 2012 Daniel Berenguer <dberenguer@usapiens.com>
# 
# This file is part of the panStamp project.
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
__date__ ="$Oct 17, 2012 22:56:00 PM$"
#########################################################################

import os
import sys

working_dir = os.path.dirname(__file__)
lagarto_dir = os.path.split(working_dir)[0]
lagarto_dir = os.path.join(lagarto_dir, "lagarto")
sys.path.append(lagarto_dir)
from lagartoresources import LagartoEndpoint, LagartoException

import json


class SpeechNetwork:
    """
    Container of SWAP network data
    """
    def get_endpoint(self, endp_id):
        """
        Get endpoint object
        
        @param id endpoint id
        
        @return endpoint object
        """
        for endp in self.endpoints:
            if endp.id == endp_id:
                return endp
        return None
        
        
    def read(self):
        """
        Read initial network data from file
        """
        # Clear current list of motes:
        self.clear()
        
        try:
            network_file = open(self.filepath)   
            network_data = json.load(network_file)["network"]
            network_file.close()
            
            # Initialize endpoints            
            
            for endp_data in network_data:
                for endp in self.endpoints:
                    if endp.id == endp_data["id"]:
                        endp.name = endp_data["name"]
                        endp.location = endp_data["location"]               
        except IOError:
            pass


    def save(self):
        """
        Save current network data into file
        """
        network = self.dumps()
        try:
            print "Saving", self.filepath
            network_file = open(self.filepath, 'w')     
            # Write network data into file
            json.dump(network, network_file, sort_keys=False, indent=2)
            network_file.close()
        except IOError:
            raise LagartoException("Unable to save speech recognition network data in file " + self.filepath)
  
      
    def dumps(self):
        """
        Serialize network data to a JSON formatted string
        """
        net_data = []
       
        for endp in self.endpoints:
            net_data.append(endp.dumps())

        data = {"network" : net_data}     
        return data
    
    
    def __init__(self, server):
        """
        Class constructor
        
        @param server: Speech recognition server
        """
        ## Speech recognition server
        self.server = server
        
        ## File name
        self.filepath = os.path.join(working_dir, "config", "speechnet.json")
        
        ## Speech recognition endpoint
        self.input = LagartoEndpoint(endp_id="sprinp",
                                     location="speech",
                                     name="input",
                                     vtype="str",
                                     direction="inp",
                                     value="")
        ## Text to speech endpoint
        self.output = LagartoEndpoint(endp_id="ttsout",
                                     location="speech",
                                     name="output",
                                     vtype="str",
                                     direction="out",
                                     value="")
        
        # List of endpoints
        self.endpoints = [self.input, self.output]
                
        # Read config file
        try:
            self.read()
        except:
            self.save()
            pass
