#########################################################################
#
# storage.py
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

from sqlalchemy import *
from sqlalchemy import event, DDL
import datetime
import os.path
import time

def now():
    return datetime.datetime.now()


class DatabaseManager:
    """
    Database with SQL Alchemy interface to store network events
    """

    ## Stores the unique Singleton instance-
    _iInstance = None
  
    ## Class used with this Python singleton design pattern
    ## Add all variables, and methods needed for the Singleton class below
    class Singleton:
        """
        Singleton model to hold only 1 object connected to the database
        """
        ## Connection handle to the database
        __db=None
        ## Default name for the database file
        __db_name=None
        ## Metadata object for database information
        __metadata=None
        ## Handle to table holding round robin keys
        __file_rrd=None
        ## Handle to table holding SWAP network events
        __file_event=None
        ## Handle to table holding EMMA motion informations
        __file_motion=None
        ## Default database name
        __file_path="info.db"
        ## MAX ROWS for every table, must make sure it doesn't overflow the disk space
        LIMIT_ROW=10;
        ## key of the round robin network database
        network_id=None;
        ## key of the round robin motion database
        motion_id=None;
        __connection=None
        session=None
        _rrd_keys={}
        def __init__(self):
            """
            Create database file if not present or open the existing one
            """
            working_dir = os.path.dirname(__file__)
            lagarto_dir = os.path.split(working_dir)[0]
            lagarto_dir = os.path.join(lagarto_dir, "lagarto-max")
            self.__file_path= os.path.join(lagarto_dir, "database", "events.db")
            present=os.path.exists(self.__file_path)
            self.__db= create_engine('sqlite:///'+self.__file_path)
            #self.__db.echo = False 
            self.__metadata= MetaData(bind=self.__db)

            #self.__tables=self.__metadata.tables.keys()
            #TODO tables are not listed because of a bug in SQL Alchemy needs a workaround
            #for t in self.__metadata.sorted_tables:
             #   print t.name
            #if database was already full
            if present: self.AutoLoad()
            else: self.CreateTables()
            
        def __del__(self):
            """
            Save the round robin keys in the database when destructor is called
            """
            self.SaveRRDKeys()

        def AutoLoad(self):
            """
            Load all the necessary tables from the existing database
            """
            self.__file_event=Table('network', self.__metadata, autoload=True)
            self.__file_rrd=Table('rrdkeys', self.__metadata, autoload=True)
            self.LoadRRDKeys()
            ##print "RRD Keys "
            ##print self._rrd_keys['network_id']
            
        def LoadRRDKeys(self): 
            """
            Load the round robin keys from the tables
            """
            operation = self.__file_rrd.select()
            result = operation.execute()
            row = result.fetchone()
            for row in result:
                self._rrd_keys['network_id']=row['network_id']
            
        def SaveRRDKeys(self):
            """
            Save the round robin keys into the tables
            """
            operation = self.__file_rrd.insert()
            ## attempt an insert
            result=operation.execute(network_id=self._rrd_keys['network_id']);   
            
        def CreateTables(self):
            """
            Creates all the tables necessary one for the network swap events and one for the motion
            """
            ##create the table to stor the network events as in the json format
            self.__file_event = Table('network', self.__metadata,
                Column('event_id', Integer,  primary_key=True),
                Column('id', String),
                Column('name', String, default="NONAME"),
                Column('location', String, default="NOWHERE"),
                Column('type', String,default="NUM"),
                Column('direction', String,default="INP"), 
                Column('value', String,default="0"), 
                Column('time',  TIMESTAMP(), default=now())
            )
            self.__file_event.create()
            ## create the round robin key database
            self.__file_rrd = Table('rrdkeys', self.__metadata,
                Column('network_id', Integer)
            )
            self.__file_rrd.create()    
            
            operation = self.__file_rrd.insert()
            ## the first time we are creating the keys put it to 0
            result=operation.execute(network_id=0);
            self._rrd_keys['network_id']=0;
            
            
        def loopTest(self):
            """
            A loop test to see if the round robin mechanism works
            """
            for i in range(0, 100):
                self.addEntry(i,"CASA","PARAM",i,"TYPE")
                print "Added entry ", i

            print "Network dump"
            self.printAllNetwork()   
            #print "RRD dump"
            #self.printAllRRD()
            
        def addEntry(self, id, location,name,value,type):
            """
            Add a network entry in the round robin database
            
            @param id: SWAP id of the device
            @param location: SWAP location of the device
            @param name: SWAP name of the device
            @param value: SWAP value of the device
            @param type: SWAP type of the device
            
            @return: boolean with true if insert or update was performed
            """
            #if(self._rrd_keys['network_id'] is None):
               # self._rrd_keys['network_id']=0
            #else:
            #print "Inserting key ", self._rrd_keys['network_id']
            self.__connection = self.__db.connect()
            self._rrd_keys['network_id']=self._rrd_keys['network_id'] % self.LIMIT_ROW
            t = text("INSERT OR REPLACE INTO network (event_id,id,location,name,value,type,time) VALUES (:id,:deviceid,:location,:name,:value,:type,:time)")
            result=self.__connection.execute(t,id=self._rrd_keys['network_id'], deviceid=id,  location=location, name=name, value=value, type=type, time=now())        
            self._rrd_keys['network_id']+=1
            self.__connection.close()
                
        def getByTime(self, days, hours, minutes,seconds ):
            """
            Retrieve the latest days+hours+minutes+seconds events
            
            @param days: days
            @param hours: hours
            @param minutes: minutes
            @param seconds: seconds
            
            @return: dictionary with column and values
            """
            network = self.__file_event
            s = select([network.c.name, network.c.location, network.c.value, network.c.time], network.c.time.between(now()- datetime.timedelta(days=days, hours=hours, minutes=minutes, seconds=seconds), now()))
            result = self.__connection.execute(s)  

            return result    

        def FindCorrelation(self, interval, conditions):
            """
            Find a correlation in a time interval with one condition
            
            @param interval: a datetime.datedelta object
            @param conditions: a dictionary of where conditions 
            
            @return: array of rows with column values
            """
            if isinstance(interval, datetime.timedelta):
                network = self.__file_event
                query = select([network.c.name, network.c.location, network.c.value, network.c.time], network.c.time.between(now()- interval, now()))
                for k in conditions.keys():
                    #currently only the '==' condition is supported we should expand this
                    query=query.where(network.c[k]==conditions[k]);
 
                result = self.__connection.execute(query)  

                
        def FindCorrelations(self, interval, conditions1, conditions2):
            """
            Find a correlation in a time interval with two conditions with AND operation
            
            @param interval: a datetime.datedelta object
            @param conditions1: a dictionary of where conditions 
            @param conditions2: a dictionary of where conditions  
            
            @return: true if a correlation was found, false if viceversa
            """
            if isinstance(interval, datetime.timedelta):

                network = self.__file_event
                query = select([func.count(network.c.event_id)], network.c.time.between(now()- interval, now()))
                for k in conditions1.keys():
                    #query=query.where(network.c.location=="SWAP");
                    query=query.where(network.c[k]==conditions1[k]);
 
                result1 = self.__connection.execute(query).fetchone()[0]  

                query = select([func.count(network.c.event_id)], network.c.time.between(now()- interval, now()))
                for k in conditions2.keys():
                    #query=query.where(network.c.location=="SWAP");
                    query=query.where(network.c[k]==conditions2[k]);
 
                result2 = self.__connection.execute(query).fetchone()[0]  
                
                if result1>0 and result2>0:
                    return True;
                else:
                    return False;
                
        def printAllNetwork(self):
            """
            Print all the network table of events
            
            """
            operation = self.__file_event.select()
            result = operation.execute()
            row = result.fetchone()
            for row in result:
                print row
        
        def printAllRRD(self):
            """
            Print all the round robin keys
            
            """            
            operation = self.__file_rrd.select()
            result = operation.execute()
            row =result.fetchone()
            for row in result:
                print row
        

    ## The constructor
    #  @param self The object pointer.
    def __init__( self ):
        # Check whether we already have an instance
        if DatabaseManager._iInstance is None:
            # Create and remember instanc
            DatabaseManager._iInstance = DatabaseManager.Singleton()
 
        # Store instance reference as the only member in the handle
        self._EventHandler_instance = DatabaseManager._iInstance
 
    #  @param self The object pointer.
    def __del__( self ): 
    ## Delegate access to implementation.
    #  @param self The object pointer.
    #  @param attr Attribute wanted.
    #  @return Attribute
        # Check whether we already have an instance
        if DatabaseManager._iInstance is not None:
            # Create and remember instanc
            DatabaseManager._iInstance.__del__()
        
    def __getattr__(self, aAttr):
        return getattr(self._iInstance, aAttr)
 
 
    ## Delegate access to implementation.
    #  @param self The object pointer.
    #  @param attr Attribute wanted.
    #  @param value Vaule to be set.
    #  @return Result of operation.
    def __setattr__(self, aAttr, aValue):
        return setattr(self._iInstance, aAttr, aValue)

            
if __name__ == "__main__":
    ''' Some test routines here ''' 
    test1 = DatabaseManager()    
    #put events ....
    test1.loopTest()
    test1.getByTime(days=1, hours=0, minutes=0, seconds=0)
    interval=datetime.timedelta(days=0)
    conditions1={"name":"Temperature", "value":"26.0"}
    conditions2={"name":"Alarm", "value":"2"}
    print test1.FindCorrelations(interval, conditions1, conditions2)
