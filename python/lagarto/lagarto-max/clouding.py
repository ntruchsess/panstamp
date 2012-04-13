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
__date__  ="$Mar 31, 2012$"
#########################################################################

import httplib
import urllib
import json


class PachubePacket:
    """
    Generic Pachube packet class
    """
    def push(self):
        """
        Push values to Pachube
        
        @return response from Pachube
        """
        header = {'X-PachubeApiKey': self.sharing_key}
        url = "api.pachube.com"
        res = None

        try:
            conn = httplib.HTTPConnection(url, timeout=8)
            conn.request('PUT', "/v2/feeds/" + self.feed_id, json.dumps(self.packet), header)
            response = conn.getresponse()
            res = response.reason
        except:
            pass
        
        conn.close()

        return res


    def __init__(self, sharing_key, feed_id, endpoints):
        """
        Constructor
        
        @param sharing_key: Pachube sharing key
        @param feed_id: Pachube feed ID
        @param endpoints: list of (datastream, value) pairs
        """
        # Sharing key
        self.sharing_key = sharing_key
        # Feed ID
        self.feed_id = feed_id
        
        datastreams = []
        for endp in endpoints:
            dstream = {"id": endp[0], "current_value": str(endp[1])}
            datastreams.append(dstream)
        
        self.packet = {"version": "1.0.0", "datastreams": datastreams}


class ThingSpeakPacket:
    """
    Generic ThingSpeak packet class
    """
    def push(self):
        """
        Push values to ThingSpeak
        
        @return response from ThingSpeak
        """
        headers = {"Content-type": "application/x-www-form-urlencoded","Accept": "text/plain"}
        url = "api.thingspeak.com"
        res = None
        
        try:
            conn = httplib.HTTPConnection(url, timeout=5)
            conn.request("POST", "/update", self.params, headers)       
            response = conn.getresponse()
            res = response.reason
        except:
            pass
        
        conn.close()

        return res


    def __init__(self, api_key, endpoints):
        """
        Constructor
        
        @param api_key: ThingSpeak write API key
        @param endpoints: list of (field ID, value) pairs
        """
        params_dict = {'key': api_key}
        
        for endp in endpoints:
            params_dict[endp[0]] = endp[1]
        
        # Parameters
        self.params = urllib.urlencode(params_dict)

