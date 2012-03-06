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
__date__  ="$Jan 26, 2012$"
#########################################################################

from lagartoconfig import XmlLagarto
from lagartohttp import LagartoHttpServer
from lagartoresources import LagartoException, LagartoMessage

import zmq
import httplib
import threading
import json
import socket
import os


class LagartoProcess(object):
    """
    Geenric Lagarto process class
    """
    def get_status(self, endpoints):
        """
        Return network status as a list of endpoints in JSON format
        Method to be overriden by subclass
        
        @param endpoints: list of endpoints being queried
        
        @return list of endpoints in JSON format
        """
        print "get_status needs to be overriden"
        return None


    def set_status(self, endpoints):
        """
        Set endpoint status
        Method to be overriden by subclass
        
        @param endpoints: list of endpoints in JSON format
        
        @return list of endpoints being controlled, with new values
        """
        print "set_status needs to be overriden"
        return None


    def http_command_received(self, command, params):
        """
        Process command sent from HTTP server. Method to be overrided by data server.
        Method to be overriden by subclass
        
        @param command: command string
        @param params: dictionary of parameters
        
        @return True if command successfukky processed by server.
        Return False otherwise
        """
        print "http_command_received needs to be overriden"
        return False
    

    def _get_local_ip_address(self):
        """
        Get local IP address
        
        @return local IP address
        """
        ipaddr = socket.gethostbyname(socket.gethostname())
        if ipaddr.startswith("127.0"):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.connect(("1.1.1.1", 8000))
                ipaddr = s.getsockname()[0]
                s.close()
            except:
                pass
 
        return ipaddr


    def __init__(self, working_dir):
        '''
        Constructor
        
        @param working_dir: Working directory
        '''
        cfg_path = os.path.join(working_dir, "config", "lagarto.xml")
        # Read configuration file       
        self.config = XmlLagarto(cfg_path)
        
        ## Local IP address
        address = self._get_local_ip_address()
        # Save IP address in config file
        if self.config.address != address:
            self.config.address = address
            self.config.save()

        # HTTP server
        http_server = LagartoHttpServer(self, self.config, working_dir)
        http_server.start()


class LagartoServer(LagartoProcess):
    """
    Lagarto server class
    """
    def publish_status(self, status_data):
        """
        Broadcast network status (collection of endpoint data)
        
        @param status_data network status to be transmitted
        """
        http_server = self.config.address + ":" + str(self.config.httpport)
        lagarto_msg = LagartoMessage(proc_name=self.config.procname, http_server=http_server, status=status_data)
        msg = json.dumps(lagarto_msg.dumps())
        self.pub_socket.send(msg)
                

    def __init__(self, working_dir):
        '''
        Constructor
        
        @param working_dir: Working directory
        '''
        LagartoProcess.__init__(self, working_dir)
        
        context = zmq.Context()
        
        # Publisher socket
        self.pub_socket = None
        if self.config.broadcast is not None:
            self.pub_socket = context.socket(zmq.PUB)
            
        # Bind socket
        if self.pub_socket.bind(self.config.broadcast) == -1:
            raise LagartoException("Unable to bind publisher socket")
        else:
            print "Publishing through", self.config.broadcast
                

class LagartoClient(threading.Thread, LagartoProcess):
    '''
    Lagarto client class
    ''' 
    def notify_status(self, event):
        """
        Notify status to the master application (callback)
        To be implemented by subclass
        
        @param event: message received from publisher in JSON format
        """
        pass
    
    
    def run(self):
        """
        Run server thread
        """
        while True:
            # Wait for broadcasted message from publisher
            event = self.sub_socket.recv()
            # Process event
            self._process_event(event)
            
            
    def _process_event(self, event):
        """
        Process lagarto event
        
        @param event: event packet to be processed
        """
        event_data = json.loads(event)
        if "lagarto" in event_data:
            event_data = event_data["lagarto"]
            if "httpserver" in event:
                # HTTP server not in list?
                if event_data["procname"] not in self.http_servers:
                    self.http_servers[event_data["procname"]] = event_data["httpserver"]
                
            if "status" in event_data:
                self.notify_status(event_data["status"])
                                             
        
    def request_status(self, procname, req):
        """
        Query/command network/endpoint status from server
        
        @param procname: name of the process to be queried
        @param req: queried/controlled endpoints
        
        @return status
        """        
        if len(req) > 0:
            control = False
            if "value" in req[0]:
                control = True
            
            cmd_list = []
            for endp in req:
                cmd = "location=" + endp["location"] + "&" + "name=" + endp["name"]
                if control:
                    cmd += "&value=" + endp["value"]
                cmd_list.append(cmd)

            if procname in self.http_servers:
                conn = httplib.HTTPConnection(self.http_servers["procname"], timeout=5)
                conn.request("GET", "&".join(cmd_list))
                response = conn.getresponse()
                if response.reason == "OK":
                    status_msg = LagartoMessage(response.read())
     
                    return status_msg.status

        return None

          
    def __init__(self, working_dir):
        '''
        Constructor
        
        @param working_dir: Working directory
        '''
        threading.Thread.__init__(self)
        LagartoProcess.__init__(self, working_dir)
               
        # ZMQ PULL socket
        self.sub_socket = None
        
        # Create ZeroMQ sockets
        self.context = zmq.Context()
        
        # PULL socket between consumer and coordinator
        if self.config.broadcast is not None:
            self.sub_socket = self.context.socket(zmq.SUB)
            if self.sub_socket.connect(self.config.broadcast) == -1:
                raise LagartoException("Unable to connect subscriber socket")
            else:
                self.sub_socket.setsockopt(zmq.SUBSCRIBE, "")
                print "Subscribed to", self.config.broadcast

        # List of HTTP servers
        self.http_servers = {}
