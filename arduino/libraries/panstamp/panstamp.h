/**
 * panstamp.h
 *
 * Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
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
 * Creation date: 03/03/2011
 */

#ifndef _PANSTAMP_H
#define _PANSTAMP_H

#include "WProgram.h"
#include "EEPROM.h"
#include "cc1101.h"
#include "endpoint.h"
#include "swpacket.h"
#include <avr/wdt.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <avr/power.h>

/**
  * EEPROM addresses
  */
#define EEPROM_SETUP_FLAG        0x00
#define EEPROM_CARRIER_FREQ      0x01
#define EEPROM_FREQ_CHANNEL      0x02
#define EEPROM_SECU_OPTION       0x03
#define EEPROM_NETWORK_ID        0x04
#define EEPROM_DEVICE_ADDR       0x06

/**
 * EEPROM setup flag values
 */
#define EEFLAG_EMPTY             0xFF
#define EEFLAG_STORED            0x00

/**
 * Class: PANSTAMP
 * 
 * Description:
 * panStamp main class
 */
class PANSTAMP
{
  private:
    /**
     * setup_watchdog
     * 
     * 'time'	Watchdog timer value
     */
    void setup_watchdog(byte time);
   
  public:
    /**
     * CC1101 radio interface
     */
    CC1101 cc1101;
    
    /**
     * Security options
     */
    byte security;

    /**
     * Security cyclic nonce
     */
    byte nonce;
    
    /**
     * init
     * 
     * Initialize panStamp board
     */
    void init(void);

    /**
     * reset
     * 
     * Reset panStamp
     */
    void reset(void);

    /**
     * sleepFor
     * 
     * Put panStamp into Power-down state during "time".
     * This function uses the internal watchdog timer in order to exit (interrupt)
     * from the power-doen state
     * 
     * 'time'	Sleeping time:
     *  WDTO_15MS  = 15 ms
     *  WDTO_30MS  = 30 ms
     *  WDTO_60MS  = 60 ms
     *  WDTO_120MS  = 120 ms
     *  WDTO_250MS  = 250 ms
     *  WDTO_500MS  = 500 ms
     *  WDTO_1S = 1 s
     *  WDTO_2S = 2 s
     *  WDTO_4S = 4 s
     *  WDTO_8S = 8 s
     */
    void sleepFor(byte time);
    
    /**
     * getInternalTemp
     * 
     * Read internal (ATMEGA328 only) temperature sensor
     * 
     * Return:
     * 	Temperature in milli-degrees Celsius
     */
    long getInternalTemp(void);
};

extern PANSTAMP panstamp;

#endif

