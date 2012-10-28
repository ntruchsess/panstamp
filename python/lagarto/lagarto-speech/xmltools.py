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
__date__  ="$Oct 4, 2012$"
#########################################################################

import xml.etree.ElementTree as xml


class XmlSettings(object):
    """
    Main configuration settings
    """
    def read(self):
        """
        Read configuration file file
        """
        # Parse XML file
        tree = xml.parse(self.file_name)
        if tree is None:
            return
        # Get the root node
        root = tree.getroot()
        # Recording command
        elem = root.find("recordcmd")
        if elem is not None:
            self.record_command = elem.text
        # Playing command
        elem = root.find("playcmd")
        if elem is not None:
            self.play_command = elem.text
        # Speech recognition command
        elem = root.find("language")
        if elem is not None:
            self.language = elem.text
        # Keyword
        elem = root.find("keyword")
        if elem is not None:
            self.keyword = elem.text
        # Server reply
        elem = root.find("reply")
        if elem is not None:
            self.reply = elem.text
        # Welcome message
        elem = root.find("welcomemsg")
        if elem is not None:
            self.welcomemsg = elem.text

                              
    def save(self):
        """
        Save serial port settings in disk
        """
        f = open(self.file_name, 'w')
        f.write("<?xml version=\"1.0\"?>\n")
        f.write("<settings>\n")
        f.write("\t<recordcmd>" + self.record_command + "</recordcmd>\n")
        f.write("\t<playcmd>" + self.play_command + "</playcmd>\n")
        f.write("\t<language>" + self.language + "</language>\n")
        f.write("\t<keyword>" + self.keyword + "</keyword>\n")
        f.write("\t<reply>" + self.reply + "</reply>\n")
        f.write("\t<welcomemsg>" + self.welcomemsg + "</welcomemsg>\n")
        f.write("</settings>\n")
        f.close()


    def __init__(self, file_name=None):
        """
        Class constructor
        
        @param filename: Path to the configuration file
        """
        # Name/path of the current configuration file
        if file_name is None:
            file_name = "settings.xml"

        ## Name/path of the current configuration file
        self.file_name = file_name
        ## Recording command
        self.record_command = "sox -r 16000 -t alsa default ${audio_file} silence 1 0.1 5% 1 1.5 5%"
        ## Playing command
        self.play_command = "mplayer ${audio_file}"
        ## User language
        self.language = "en-us"
        ## Name of the recorded audio file
        self.record_file = "recording.flac"
        ## Name of the output audio file
        self.play_file = "output.mp3"
        ## Keyword string
        self.keyword = "lagarto"
        ## Server reply after receiving keyword
        self.reply = "Yes Sir"
        ## Welcome message
        self.welcomemsg = "Ready for your commands"
    
        # Read XML file
        self.read()
