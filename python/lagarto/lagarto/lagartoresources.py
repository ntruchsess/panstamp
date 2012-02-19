#########################################################################
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
# along with panLoader; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
# USA
#
#########################################################################
__author__="Daniel Berenguer"
__date__  ="$Feb 6, 2012$"
#########################################################################

import time
import datetime


class LagartoMessage:
    """
    Lagarto message class
    """
    def dumps(self):
        """
        Serialize message in form of JSON string
        """       
        data = {}
        data["procname"] = self.proc_name
        if self.http_server is not None:
            data["httpserver"] = self.http_server   
        
        if self.status is not None:
            endp_data = []
            for endp in self.status:
                endp_data.append(endp)
                
            data["status"] = endp_data
            
        return {"lagarto" : data}

        
    def __init__(self, msg=None, proc_name=None, http_server=None, status=None):
        """
        Constructor
        
        @param msg: serialized message string
        @param proc_name: process name
        @param http_server: HTTP server address
        @param status: list of endpoint data
        """
        ## Process name
        self.proc_name = proc_name
        ## HTTP server address
        self.http_server = http_server
        ## List of endpoint data
        self.status = status
        
        if msg is not None:
            if "lagarto" not in msg:
                raise LagartoException("Incorrect packet header")
            
            data = msg["lagarto-status"]
            
            if "procname" not in data:
                raise LagartoException("Status message must contain a proces name")
            
            self.proc_name = data["procname"]
            
            if "httpserver" in data:
                self.http_server = data["httpserver"]
            
            if "status" in data:
                self.status = []
                for endp_data in data["status"]:
                    endp = LagartoEndpoint(endp_data)
                    self.status.append(endp)

        
class LagartoEndpoint:
    """
    Lagarto endpoint class
    """
    def dumps(self):
        """
        Serialize address in form of JSON string
        """
        endpoint = {}
        endpoint["id"] = self.endp_id
        endpoint["name"] = self.name
        endpoint["location"] = self.location
        endpoint["direction"] = self.direction
        if self.value is not None:
            endpoint["value"] = self.value
            if self.unit is not None:
                endpoint["unit"] = self.unit
                
        return endpoint

        
    def __init__(self, endpstr=None, endp_id=None, location=None, name=None, direction=None, value=None, unit=None):
        """
        Constructor
        
        @param enspstr: endpoint in string format
        @param endp_id: endpoint unique id
        @param location: endpoint location
        @param name: endpoint name
        @param direction: endpoint direction
        @param value: endpoint value
        @param unit: optional unit
        """
        
        ## Endpoint id
        self.endp_id = endp_id
        ## Endpoint name
        self.name = name
        ## Endpoint location
        self.location = location
        ## Direction (input or output)
        self.direction = direction
        ## Endpoint value
        self.value = value
        ## Unit
        self.unit = unit
        
        if endpstr is not None:
            if "id" not in endpstr:
                raise LagartoException("Lacking id information in endpoint")
            if "location" not in endpstr:
                raise LagartoException("Lacking location information in endpoint")
            if "name" not in endpstr:
                raise LagartoException("Lacking name information in endpoint")
            
            self.endp_id = endpstr["id"]
            self.location = endpstr["location"]
            self.name = endpstr["name"]
            
            if "value" in endpstr:
                self.value = endpstr["value"]
                
            if "unit" in endpstr:
                self.unit = endpstr["unit"]

            if "direction" in endpstr:
                self.direction = endpstr["direction"]


class LagartoException(Exception):
    """
    Main exception class for lagarto comms
    """
    def display(self):
        """
        Print exception description
        """
        print datetime.datetime.fromtimestamp(self.timestamp).strftime("%d-%m-%Y %H:%M:%S"), self.description
              
                  
    def __str__(self):
        """
        String representation of the exception
        """
        return repr(self.description)


    def __init__(self, value):
        """
        Class constructor
        
        @param value: Description about the error
        """
        self.timestamp = time.time()
        # Exception description
        self.description = "LagartoException occurred: " + value
