"""
python module which can be used to send SMS messages via the Clickatell HTTP/S API
Interface on https://api.clickatell.com/


Changes by Arne Brodowski, 2008:

 * Removed dependency to pycurl
 * added an require_auth decorator
 * moved the api urls to kwargs with default values
 * changed the auth and curl methods to raise an Exception
   instead of printing or failing silently.


See U{the Clickatell HTTP/S API documentation<http://www.clickatell.com/downloads/http/Clickatell_http_2.2.7.pdf>}
for more information on how their HTTP/S API interface works

*** WARNING *** DANGER WILL ROBINSON *** THIS CODE IS UNDERGOING MAJOR CHANGES AND THE INTERFACES MAY CHANGE AT ANYTIME PRIOR TO AN INITIAL RELEASE BEING MADE ***

$Id: clickatell.py 714 2006-09-19 23:10:36Z jacques $
"""

import urllib, urllib2

try:
    from cStringIO import StringIO
except ImportError:
    from StringIO import StringIO

__author__      = "Jacques Marneweck <jacques@php.net>, Arne Brodowski <mail@arnebrodowski.de>"
__version__     = "0.1.1-alpha"
__copyright__   = "Copyright (c) 2006 Jacques Marneweck, 2008 Arne Brodowski. All rights reserved."
__license__     = "The MIT License"


def require_auth(func):
    """
    decorator to ensure that the Clickatell object is authed before proceeding
    """
    def inner(self, *args, **kwargs):
        if not self.has_authed:
            self.auth()
        return func(self, *args, **kwargs)
    return inner

class ClickatellError(Exception):
    """
    Base class for Clickatell errors
    """

class ClickatellAuthenticationError(ClickatellError):
    pass

class Clickatell(object):
    """
    Provides a wrapper around the Clickatell HTTP/S API interface
    """

    def __init__ (self, username, password, api_id):
        """
        Initialise the Clickatell class

        Expects:
         - username - your Clickatell Central username
         - password - your Clickatell Central password
         - api_id - your Clickatell Central HTTP API identifier
        """
        self.has_authed = False

        self.username = username
        self.password = password
        self.api_id = api_id

        self.session_id = None


    def auth(self, url='https://api.clickatell.com/http/auth'):
        """
        Authenticate against the Clickatell API server
        """
        post = [
            ('user', self.username),
            ('password', self.password),
            ('api_id', self.api_id),
        ]

        result = self.curl(url, post)

        if result[0] == 'OK':
            assert (32 == len(result[1]))
            self.session_id = result[1]
            self.has_authed = True
            return True
        else:
            raise ClickatellAuthenticationError, ': '.join(result)

    @require_auth        
    def getbalance(self, url='https://api.clickatell.com/http/getbalance'):
        """
        Get the number of credits remaining at Clickatell
        """
        post = [
            ('session_id', self.session_id),
        ]

        result = self.curl(url, post)
        if result[0] == 'Credit':
            assert (0 <= result[1])
            return result[1]
        else:
            return False

    @require_auth        
    def getmsgcharge(self, apimsgid, url='https://api.clickatell.com/http/getmsgcharge'):
        """
        Get the message charge for a previous sent message
        """
        assert (32 == len(apimsgid))
        post = [
            ('session_id', self.session_id),
            ('apimsgid', apimsgid),
        ]

        result = self.curl(url, post)
        result = ' '.join(result).split(' ')

        if result[0] == 'apiMsgId':
            assert (apimsgid == result[1])
            assert (0 <= result[3])
            return result[3]
        else:
            return False

    @require_auth        
    def ping(self, url='https://api.clickatell.com/http/ping'):
        """
        Ping the Clickatell API interface to keep the session open
        """
        post = [
            ('session_id', self.session_id),
        ]

        result = self.curl(url, post)

        if result[0] == 'OK':
            return True
        else:
            self.has_authed = False
            return False

    @require_auth
    def sendmsg(self, message, url = 'https://api.clickatell.com/http/sendmsg'):
        """
        Send a mesage via the Clickatell API server

        Takes a message in the following format:
        
        message = {
            'to': 'to_msisdn',
            'text': 'This is a test message',
        }

        Return a tuple. The first entry is a boolean indicating if the message
        was send successfully, the second entry is an optional message-id.
        
        Example usage::
        
            result, uid = clickatell.sendmsg(message)
            if result == True:
                print "Message was sent successfully"
                print "Clickatell returned %s" % uid
            else:
                print "Message was not sent"

        """
        if not (message.has_key('to') or message.has_key('text')):
            raise ClickatellError, "A message must have a 'to' and a 'text' value"
            
        post = [
            ('session_id', self.session_id),
            ('to', message['to']),
            ('text', message['text']),
        ]
        
        result = self.curl(url, post)

        if result[0] == 'ID':
            assert (result[1])
            return (True, result[1])
        else:
            return (False, None)

    @require_auth
    def tokenpay(self, voucher, url='https://api.clickatell.com/http/token_pay'):
        """
        Redeem a voucher via the Clickatell API interface
        """
        assert (16 == len(voucher))
        post = [
            ('session_id', self.session_id),
            ('token', voucher),
        ]

        result = self.curl(url, post)

        if result[0] == 'OK':
            return True
        else:
            return False


    def curl(self, url, post):
        """
        Inteface for sending web requests to the Clickatell API Server
        """
        try:
            data = urllib2.urlopen(url, urllib.urlencode(post))
        except urllib2.URLError, v:
            raise ClickatellError, v
                
        return data.read().split(": ")

