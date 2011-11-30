/*
 * temphum.pde
 *
 * Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
 * 
 * This file is part of the panStamp project.
 * 
 * panLoader  is free software; you can redistribute it and/or modify
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
 * Creation date: 03/31/2011
 */
 
#include "regtable.h"
#include "panstamp.h"

#define enableIRQ_SYNC()        attachInterrupt(1, isrSYNCevent, FALLING);
#define disableIRQ_SYNC()       detachInterrupt(1);
#define SYNCPIN                 3
#define LEDPIN                  4

/**
 * SYNC mode flag
 */
boolean inSync = false;
 
/**
 * isrSYNCevent
 *
 * Event on INT1 pin. SYNC button pressed
 */
void isrSYNCevent(void)
{
  // Check that SYNC button is really pressed
  if (digitalRead(SYNCPIN) == HIGH)
  {
    int i;
    
    // Wake up
    panstamp.wakeUp();
    // Blink LED
    for(i=0 ; i<3 ; i++)
    {
      digitalWrite(LEDPIN, HIGH);
      delay(50);
    }
    // Enter SYNC mode (full Rx mode)
    panstamp.enterSystemState(SYSTATE_SYNC);
  }
}

/**
 * goToSleep
 *
 * Sleep whilst in power-down mode
 */
unsigned int goToSleep(void)
{
  // Get the amount of seconds to sleep from the internal register
  byte *arrInterval = getRegister(REGI_TXINTERVAL)->value;
  int intInterval = arrInterval[0] * 0x100 + arrInterval[1];
  
  int loops = intInterval/8;  // This will give us a granularity of 8 sec
  
  int i;
  // Sleep
  for (i=0 ; i<loops ; i++)
    panstamp.sleepFor(WDTO_8S);
    
  // Wake-up!!
  panstamp.wakeUp();
}

/**
 * setup
 *
 * Arduino setup function
 */
void setup()
{
  pinMode(LEDPIN, OUTPUT);
  pinMode(SYNCPIN, INPUT);
  
  // Init panStamp
  panstamp.init();
  
  // Transmit product code
  getRegister(REGI_PRODUCTCODE)->getData();
}

/**
 * loop
 *
 * Arduino main loop
 */
void loop()
{
  if (!inSync)
  {
    getRegister(REGI_VOLTSUPPLY)->getData();
    getRegister(REGI_HUMIDTEMP)->getData();
    goToSleep();
  }
}

