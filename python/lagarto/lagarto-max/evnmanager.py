#########################################################################
#
# evnmanager
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
__date__  ="$Jan 23, 2012$"
#########################################################################

import os
import sys
import threading
import time
import inspect

working_dir = os.path.dirname(__file__)
lagarto_dir = os.path.split(working_dir)[0]
lagarto_dir = os.path.join(lagarto_dir, "lagarto")
sys.path.append(lagarto_dir) 
from lagartocomms import LagartoClient
from lagartoresources import LagartoEndpoint

from api import TimeAPI, NetworkAPI
import webscripts
from webevents import WebEvent
from scripts.events import event_handler


class PeriodicTrigger(threading.Thread):
    """
    Periodic trigger class
    """
    def run(self):
        """
        Start timer
        """
        """
        tm_year = time.localtime()[0]
        tm_mon = time.localtime()[1]
        tm_mday = time.localtime()[2]
        tm_hour = time.localtime()[3]
        tm_min = time.localtime()[4]
        tm_sec = time.localtime()[5]
        """

        while True:
            tm_sec = time.localtime()[5]
            time.sleep(60.0 - tm_sec)
            TimeEvent()
    
    
    def __init__(self):
        """
        Constructor
        """
        threading.Thread.__init__(self)
        self.start()


class TimeEvent(threading.Thread):
    """
    Time-based event
    """
    def run(self):
        """
        Run event
        """
        reload(webscripts)
        attributes = dir(webscripts.WebScripts)
        TimeAPI.event = True
        for attr in attributes:
            if attr.startswith("evn_"):
                event = getattr(webscripts.WebScripts, attr)
                #print "Event 1 :", time.strftime("%A %d/%m/%Y %H:%M:%S", TimeAPI.current_time)
                event()
        TimeAPI.event = False

        
    def __init__(self):
        """
        Constructor
        """
        threading.Thread.__init__(self)
        NetworkAPI.reset_event()
        TimeAPI.update_time()
        
        # Run event script
        evnscript = EventScript("clock", TimeAPI.current_time)
        
        # Run web script
        self.start()

    
class EvnManager(LagartoClient):
    """
    Lagarto event management class
    """

    def notify_status(self, event):
        """
        Notify status to the master application (callback)
        To be implemented by subclass
        
        @param event: message received from publisher in JSON format
        """
        reload(webscripts)
        attributes = dir(webscripts.WebScripts)
               
        for endp in event["status"]:
            # Create lagarto endpoint
            lagarto_endp = LagartoEndpoint(endpstr=endp, procname=event["procname"])
            # Run event script
            evnscript = EventScript("network", lagarto_endp)
            # Update network event in API
            NetworkAPI.event = [event["procname"] + "." + endp["location"]  + "." + endp["name"], endp["value"]]
        
            # Wait if time event currently running
            while TimeAPI.event:
                time.sleep(0.1)

            # Run web script
            for attr in attributes:
                if attr.startswith("evn_"):
                    event_func = getattr(webscripts.WebScripts, attr)
                    event_func()


    def http_command_received(self, command, params):
        """
        Process command sent from HTTP server. Method to be overrided by data consumer.
        Method required by LagartoClient
        
        @param command: command string
        @param params: dictionary of parameters
        
        @return True if command successfukky processed by server.
        Return False otherwise
        """
        if command == "get_server_list":
            return self.get_servers()
        
        elif command == "get_endpoint_list":
            return self.get_endpoints(params["server"])

        elif command == "set_endpoint_value":
            location = None
            name = None
            endp_id = None
            
            if "id" in params:
                endp_id = params["id"]
            if "location" in params:
                location = params["location"]
                if "name" in params:
                    name = params["name"]
            try:
                endpoint = LagartoEndpoint(endp_id = endp_id, location=location, name=name, value=params["value"], procname=params["procname"])
            except:
                return None
            
            return self.set_endpoint(endpoint)
    
        elif command == "get_event_list":
            return WebEvent.get_events()
        
        elif command == "get_event":
            if "id" in params:
                try:
                    event = WebEvent(params["id"])
                    return event.dumps()
                except:
                    pass
            
        elif command == "delete_event":
            if "id" in params:
                try:
                    event = WebEvent(params["id"])
                    event.delete()
                    return "event_panel.html"
                except:
                    pass

        elif command == "config_event_name":
            if "id" in params:
                try:
                    event = WebEvent(params["id"])
                    event.name = params["name"]
                    event.save()
                    return True
                except:
                    pass
                
        elif command == "set_event_line":
            if "id" in params:
                try:
                    event = WebEvent(params["id"])
                    linenb = params["linenb"]
                    event.set_line(params["line"], linenb, params["type"])
                    event.save()
                    return "edit_event.html"
                except:
                    pass

        elif command == "delete_event_line":
            if "id" in params:
                try:
                    event = WebEvent(params["id"])
                    linenb = params["linenb"]
                    event.delete_line(linenb)
                    event.save()
                    return "edit_event.html"
                except:
                    pass

        return False


    def __init__(self):
        """
        Constructor
        """
        # Lagarto client constructor
        LagartoClient.__init__(self, os.path.dirname(__file__))
        NetworkAPI.lagarto_client = self

        # Start periodic trigger thread
        PeriodicTrigger()
        
        # Start Lagarto client
        self.start()


class EventScript(threading.Thread):
    """
    Class used to run event handler on independednt thread
    """
    def run(self):
        """
        Run thread
        """
        event_handler(self.evnsrc, self.evnobj)

        
    def __init__(self, evnsrc, evnobj):
        """
        Constructor
        
        @param evnsrc: event source ("network", "clock", "startup")
        @param evnobj: event object
        """
        threading.Thread.__init__(self)
        
        # Event source
        self.evnsrc = evnsrc
        
        # Event object
        self.evnobj = evnobj
        
        # Run event handler
        self.start()
