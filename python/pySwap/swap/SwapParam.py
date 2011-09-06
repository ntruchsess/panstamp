#########################################################################
#
# SwapParam
#
# Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
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
__author__="Daniel Berenguer"
__date__ ="$Aug 26, 2011 8:56:27 AM$"
#########################################################################

from swap.SwapDefs import SwapType
from swap.SwapValue import SwapValue

class SwapParam:
    """
    Generic SWAP parameter, integrated into a SWAP register
    """

    def update(self):
        """
        Update parameter's value, posibly after a change in its parent register
        """
        self.valueChanged = False
        if self.register is None:
            raise SwapException("Register not specified for current endpoint")
            return

        # Current register value converted to list
        lstRegVal = self.register.value.toList()
        # Total bits to be copied
        indexReg = self.bytePos
        shiftReg = 7 - self.bitPos
        bitsToCopy = self.byteSize * 8 + self.bitSize
        # Current parameter value in list format
        lstParamVal = self.value.toList()
        # Keep old value
        oldParamVal = self.value.clone()
        indexParam = 0
        shiftParam = self.bitSize - 1

        if shiftParam < 0:
            shiftParam = 7
        for i in range(bitsToCopy):
            if (lstRegVal[indexReg] >> shiftReg) & 0x01 == 0:
                mask = ~(1 << shiftParam)
                lstParamVal[indexParam] &= mask
            else:
                mask = 1 << shiftParam
                lstParamVal[indexParam] |= mask

            shiftReg -= 1
            shiftParam -= 1

            # Register byte over?
            if shiftReg < 0:
                indexReg += 1
                shiftReg = 7

            # Parameter byte over?
            if shiftParam < 0:
                indexParam += 1
                shiftParam = 7


        # Did the value change?
        if not self.value.isEqual(oldParamVal):
            self.valueChanged = True


    def setValue(self, value):
        """
        Set parameter value

        'value'  New parameter value
        """
        if value.__class__ is SwapValue:
            self.value = value
        elif type(value) is list:
            self.value = SwapValue(value)
        elif type(value) is str:
            if self.type in [SwapType.NUMBER, SwapType.BINARY]:
                try:
                    res = int(value)
                except ValueError:
                    # Possible decimal number
                    dot = value.find(".")
                    if dot > -1:
                        try:
                            # 32.56 is converted to 3256
                            integer = int(value[:dot])
                            numDec = len(value[dot+1:])
                            decimal = int(value[dot+1:])
                            res = integer * 10 ** numDec + decimal
                        except ValueError:
                            raise SwapException(value + " is not a valid value for " + self.description)
                    else:
                        raise SwapException(value + " is not a valid value for " + self.description)
            else:   # SwapType.STRING
                res = value
        else:
            res = value

        # Byte length
        length = self.byteSize
        if self.bitSize > 0:
            length += 1

        # Update current value
        self.value = SwapValue(res, length)

        # Update register value
        self.register.update()


    def __init__(self, register=None, pType=SwapType.NUMBER, direction=SwapType.INPUT, \
                description="", position="0", size="1", default=None):
        """
        Class constructor

        'register'      Register containing this parameter
        'pType'         Type of SWAP parameter (see SwapDefs.SwapType)
        'direction'     Input or output (see SwapDefs.SwapType)
        'description'   Short description about hte parameter
        'position'      Position in bytes.bits within the parent register
        'size'          Size in bytes.bits
        'default'       Default value in string format
        """
        # Parameter description
        self.description = description
        # Register where the current endpoint is taken from
        self.register = register
        # Data type
        self.type = pType
        # Direction
        self.direction = direction
        # Position (in bytes) of the parameter within the parent register
        self.bytePos = 0
        # Position (in bits) after bytePos
        self.bitPos = 0
        # Get true positions
        dot = position.find('.')
        if dot > -1:
            self.bytePos = int(position[:dot])
            self.bitPos = int(position[dot+1:])
        else:
            self.bytePos = int(position)

        # Size (in bytes) of the parameter value
        self.byteSize = 1
        # Size in bits of the parameter value after byteSize
        self.bitSize = 0
        # Get true sizes
        dot = size.find('.')
        if dot > -1:
            self.byteSize = int(size[:dot])
            self.bitSize = int(size[dot+1:])
        else:
            self.byteSize = int(size)

        # Current value
        self.value = None
        # Set initial value

        if default is not None:
            self.setValue(default)

        # Flag that tells us whether this parameter changed its value last time or not
        self.valueChanged = False
