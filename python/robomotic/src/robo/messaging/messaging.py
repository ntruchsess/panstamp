#########################################################################
#
# messaging providers at the moment just one
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
__author__="Paolo Di Prodi"
__date__  ="$Sept 10, 2012$"
#########################################################################
from smstools import MessagingSettings
from datetime import datetime
import time
import os
import logging
import urllib
class IntelliSMS(object):
    """
    A class for sending SMS messages from IntelliSoftware.co.uk
    """
    def __init__(self, config_path):
        """
        Init all variables from messaging.xml file
        
        """
        self.settings=MessagingSettings(config_path)
        self.username=self.settings.username
        self.password=self.settings.password
        self.sender=self.settings.defaultidentity
        self.to=self.settings.defaultdestination
        self.url1="http://www.intellisoftware.co.uk"
        self.url2="http://www.intellisoftware2.co.uk"
        self.pushpage="/smsgateway/sendmsg.aspx"
        self.UseProxies=self.settings.useproxy
        if self.UseProxies:
            self.proxies = {self.settings.gateway}
        else:
            self.proxies={}
        self.MaxConCatMsgs=1
        self.status=""

        self.last_sms=datetime.now()
        self.min_period=3
        self.sent=0

    def EnableProxy(self,flag):
        if(flag):
            self.UseProxies=1;
        else:
            self.UseProxies=0;
            
    def SetProxy(self,url):
        if len(url)>0:
            self.proxies=url
            self.UseProxies=1
        else:
            self.UseProxies=0	
        
    def SendSms(self,text="Default text message"):

        deltaT=datetime.now()-self.last_sms
        if  deltaT.seconds>self.min_period or self.sent==0:
            if self.settings.debug>0:
                logging.info("Debug SMS sent %s " %time.strftime("%I:%M:%S %p", time.localtime()))
                self.sent=1
                return 1
            else:
                self.last_sms=datetime.now()
                self.config={}
                self.config['username']=self.username
                self.config['password']=self.password
                #needs to be changed with international prefix what an hassle!
                self.config['to']=self.to
                self.config['from']=self.sender
                self.config['text']=text
                self.config['maxconcat']=self.MaxConCatMsgs
                query = urllib.urlencode(self.config)
                try:
                    if self.UseProxies>0 :
                        file = urllib.urlopen(self.url1+self.pushpage, query,proxies=self.proxies)
                    else:
                        file = urllib.urlopen(self.url1+self.pushpage, query,proxies=None)
                except IOError, (errno):
                    logging.error ("Error delivering online SMS %s " %errno) 
                    return 0
                self.sent=1
                self.output = file.read()
                file.close()
                logging.info("Message sent to %s from %s" % (self.to, self.sender)) 
                #return self.ParseRequest()
                return 1
        else:
            logging.info("Minimum SMS delay exceeded!")
        
    def SendFakeSms(self,to="447508456016",text="Alarm",fromID="Robomotic"):
        self.output="ID:10011000000018633309"
        return self.ParseRequest()
        
    def ParseRequest(self):
        SendStatusCollection = {}
        msgresponses = self.output.split("\n")
        for msgresponse in msgresponses:
                msgresponse.strip()
                if ( len(msgresponse) > 0 ):
                    msgresponseparts = msgresponse.split(":")
                    if msgresponseparts[0]=="ID":
                        return 1
                    else:
                        return 0
                    
                else:
                    return 0    
