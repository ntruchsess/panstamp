#########################################################################
#
# storage
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
import datetime
import os.path


def now():
    return datetime.datetime.now()


class DatabaseManager:
    """
    Database with SQL Alchemy interface to store network events
    """

    ## Stores the unique Singleton instance-
    _iInstance = None
 
    ## Class used with this Python singleton design pattern
    #  @todo Add all variables, and methods needed for the Singleton class below
    class Singleton:
        __db=None
        __db_name=None
        __metadata=None
        __file_event=None
        __file_path="info.db"
        def __init__(self):
            """
            Create database file if not present or open the existing one
            """
            working_dir = os.path.dirname(__file__)
            lagarto_dir = os.path.split(working_dir)[0]
            lagarto_dir = os.path.join(lagarto_dir, "lagarto")
            self.__file_path= os.path.join(lagarto_dir, "database", "events.db")
            present=os.path.exists(self.__file_path)
            self.__db= create_engine('sqlite:///'+self.__file_path)
            #self.__db.echo = False 
            self.__metadata= MetaData(self.__db)
            #self.__tables=self.__metadata.tables.keys()
            #TODO tables are not listed because of a bug in SQL Alchemy needs a workaround
            #for t in self.__metadata.sorted_tables:
            #    print t.name
            #if database was already full
            if present: self.AutoLoad()
            else: self.InitIndex()
     
        def AutoLoad(self):
            """
            Load all the necessary tables
            """
            #print "Loading database "+self.__file_path
            self.__file_event=Table('network', self.__metadata, autoload=True)
        def InitIndex(self):
            #print "Creating database "+self.__file_path
            self.__file_event = Table('network', self.__metadata,
                Column('event_id', Integer, primary_key=True),
                Column('name', String),
                Column('location', String),
                Column('type', String,default="NUM"),
                Column('direction', String,default="INP"), 
                Column('value', String,default="0"), 
                Column('time',  TIMESTAMP(), default=now())
            )
            self.__file_event.create()

        def addEntry(self, location,name,value,type):
            #print "Adding entry"
            operation = self.__file_event.insert()
            result=operation.execute(name=name, value=value,location=location,type=type,time=now())
            
        def getAll(self):
            operation = self.__file_event.select()
            result = operation.execute()
            row = result.fetchone()
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
 
 
    ## Delegate access to implementation.
    #  @param self The object pointer.
    #  @param attr Attribute wanted.
    #  @return Attribute
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
    test1 = DatabaseManager()    
            
