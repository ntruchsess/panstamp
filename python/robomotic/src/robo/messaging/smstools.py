#########################################################################
#
# Copyright (c) 2012 Paolo Di Prodi <paolo@robomotic.com>
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
__author__="Paolo Di Prodi"
__date__  ="$Sept 13, 2012$"
#########################################################################

import xml.etree.ElementTree as xml
import os


class MessagingSettings(object):
    """
    Main configuration settings: config files and directories
    """
    ## Name/path of the current configuration file
    file_name = "messaging.xml"
    ## Debug level (0: no debug, 1: print protocol events )
    debug = 0
    ## list of providers
    providers={}
    ## username of provider
    username="user"
    ## password of provider
    password = "password"
    ## default identity of sender can be a name or a telephone number
    defaultidentity = "lagarto"
    ## default destination of message, must contain international prefix
    defaultdestination="4412345678"
    ## use a proxy flag
    useproxy=False
    ##default web proxy if necessary
    gateway="http://wwwcache.network.local"
    ## Name/path of the error log file
    error_file = "smserror.log"

    def read(self):
        """
        Read configuration file file
        """
        # Parse XML file
        tree = xml.parse(MessagingSettings.file_name)
        if tree is None:
            return
        # Get the root node
        root = tree.getroot()
        # Debug flag
        elem = root.find("debug")
        if elem is not None:
            MessagingSettings.debug = int(elem.text)
        # Get username
        elem = root.find("username")
        if elem is not None:
            MessagingSettings.username = elem.text
        # Get password
        elem = root.find("password")
        if elem is not None:
            MessagingSettings.password = elem.text
        # Get dafault sender
        elem = root.find("defaultidentity")
        if elem is not None:
            MessagingSettings.defaultidentity = elem.text
        # Get password
        elem = root.find("defaultdestination")
        if elem is not None:
            MessagingSettings.defaultdestination = elem.text       
        # Get proxy flag
        elem = root.find("useproxy")            
        if elem is not None:
            MessagingSettings.useproxy = elem.text.lower() in ["1", "true", "enable"]
        else:
            MessagingSettings.useproxy = False
        if MessagingSettings.useproxy:
            elem = root.find("proxy")            
            if elem is not None:
                MessagingSettings.proxy = elem.text.lower() in ["1", "true", "enable"]
            else:
                MessagingSettings.proxy = False
            # Get path name of the error log file
            elem = root.find("errlog")
            if elem is not None:
                MessagingSettings.error_file = elem.text


    def save(self):
        """
        Save messaging settings to disk
        """
        f = open(MessagingSettings.file_name, 'w')
        f.write("<?xml version=\"1.0\"?>\n")
        f.write("<providers>\n")
        f.write("\t<debug>" + str(MessagingSettings.debug) + "</debug>\n")
        f.write("\t<username>" + str(MessagingSettings.username) + "</username>\n")
        f.write("</providers>\n")
        f.close()


    def __init__(self, file_name=None):
        """
        Class constructor
        
        @param filename: Path to the configuration file
        """
        # Name/path of the current configuration file
        if file_name is None:
            file_name = "settings.xml"

        MessagingSettings.file_name = file_name
        # Read XML file
        self.read()
        
        direc = os.path.dirname(MessagingSettings.file_name)

        # Convert to absolute paths
        MessagingSettings.error_file = os.path.join(direc, MessagingSettings.error_file)
