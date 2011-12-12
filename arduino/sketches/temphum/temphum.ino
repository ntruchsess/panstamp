/*
 * temphum
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
 * Creation date: 11/31/2011
 */
 
#include "regtable.h"
#include "panstamp.h"

/**
 * LED pin
 */
#define LEDPIN               4

/**
 * setup
 *
 * Arduino setup function
 */
void setup()
{
  int i;
  byte ledState = LOW;
  
  pinMode(LEDPIN, OUTPUT);

  // Init panStamp
  panstamp.init();
  
  // Transmit product code
  getRegister(REGI_PRODUCTCODE)->getData();

  // During 3 seconds, listen the network for possible commands whilst the LED blinks
  for(i=0 ; i<12 ; i++)
  {
    ledState = !ledState;
    digitalWrite(LEDPIN, ledState);
    delay(250);
  }
  // Switch to Rx OFF state
  panstamp.enterSystemState(SYSTATE_RXOFF);
}

/**
 * loop
 *
 * Arduino main loop
 */
void loop()
{
//  wdt_enable(WDTO_4S);
  getRegister(REGI_VOLTSUPPLY)->getData();
  digitalWrite(LEDPIN, HIGH);
  getRegister(REGI_TEMPHUM)->getData();
  digitalWrite(LEDPIN, LOW);
//  wdt_disable();
  panstamp.goToSleep();
}

