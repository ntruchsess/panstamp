/**
 * regtable
 *
 * Copyright (c) 2012 Daniel Berenguer <dberenguer@usapiens.com>
 * 
 * This file is part of the panStamp project.
 * 
 * panStamp  is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * any later version.
 * 
 * panLoader is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with panLoader; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 
 * USA
 * 
 * Author: Daniel Berenguer
 * Creation date: 01/19/2012
 */

#include <EEPROM.h>
#include "product.h"
#include "panstamp.h"
#include "regtable.h"

/**
 * Declaration of common callback functions
 */
DECLARE_COMMON_CALLBACKS()

/**
 * Definition of common registers
 */
DEFINE_COMMON_REGISTERS()

/*
 * Definition of custom registers
 */
// Voltage supply
static byte dtVoltSupply[2];
REGISTER regVoltSupply(dtVoltSupply, sizeof(dtVoltSupply), &updtVoltSupply, NULL);
// Binary input register
static byte dtBinInputs[2];
REGISTER regBinInputs(dtBinInputs, sizeof(dtBinInputs), &updtBinInputs, NULL);

/**
 * Initialize table of registers
 */
DECLARE_REGISTERS_START()
  &regVoltSupply,
  &regBinInputs,
DECLARE_REGISTERS_END()

/**
 * Definition of common getter/setter callback functions
 */
DEFINE_COMMON_CALLBACKS()

/**
 * Definition of custom getter/setter callback functions
 */
 
/**
 * updtVoltSupply
 *
 * Measure voltage supply and update register
 *
 * 'rId'  Register ID
 */
const void updtVoltSupply(byte rId)
{
  unsigned short result;
  
  // Read 1.1V reference against AVcc
  ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1);
  delay(2); // Wait for Vref to settle
  ADCSRA |= _BV(ADSC); // Convert
  while (bit_is_set(ADCSRA,ADSC));
  result = ADCL;
  result |= ADCH << 8;
  result = 1126400L / result; // Back-calculate AVcc in mV

  /**
   * register[eId]->member can be replaced by regVoltSupply in this case since
   * no other register is going to use "updtVoltSupply" as "updater" function
   */

  // Update register value
  regTable[rId]->value[0] = (result >> 8) & 0xFF;
  regTable[rId]->value[1] = result & 0xFF;
}

/**
 * updtBinInputs
 *
 * Read binary inputs
 *
 * 'rId'  Register ID
 */
const void updtBinInputs(byte rId)
{
  byte highByte = 0, lowByte = 0;

  lowByte = bitRead(PINB, 0);
  lowByte |= bitRead(PINB, 1) << 1;
  lowByte |= bitRead(PINC, 0) << 2;
  lowByte |= bitRead(PINC, 1) << 3;
  lowByte |= bitRead(PINC, 2) << 4;
  lowByte |= bitRead(PINC, 3) << 5;
  lowByte |= bitRead(PINC, 4) << 6;
  lowByte |= bitRead(PINC, 5) << 7;

  highByte |= bitRead(PIND, 3);
  highByte |= bitRead(PIND, 5) << 1;
  highByte |= bitRead(PIND, 6) << 2;
  highByte |= bitRead(PIND, 7) << 3;

  dtBinInputs[0] = highByte;
  dtBinInputs[1] = lowByte;
}

