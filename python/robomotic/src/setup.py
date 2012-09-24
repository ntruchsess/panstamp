#!/usr/bin/env python
#########################################################################
#
# Copyright (c) 2011 Paolo Di Prodi <paolo@robomotic.com>
# 
# This file is part of the panStamp project.
# 
# panStamp  is free software; you can redistribute it and/or modify
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
__date__ ="$Feb 24, 2012"
#########################################################################
from distutils.core import setup

setup(name='robo',
      version='0.1.1',
      description='Python Libraries for Robomotic modules',
      author='Paolo Di Prodi',
      author_email='paolo@robomotic.com',
      url='www.robomotic.com',
      packages=['robo', 'robo.messaging', 'robo.database', 'robo.gsm'],
     )
