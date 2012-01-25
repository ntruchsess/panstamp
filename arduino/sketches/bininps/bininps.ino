/*
 * bininps
 *
 * Copyright (c) 2012 Daniel Berenguer <dberenguer@usapiens.com>
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
 * Creation date: 01/18/2012
 *
 * Device:
 * Binary inputs
 *
 * Description:
 * Device that reports the binary state of 12 digital inputs.
 * This sketch can be used to detect key/switch presses, binary alarms or
 * any other binary sensor.
 * Inputs are not debounced in any way so the user may decide whether to
 * debounce them via software or simply add an external capacitor, depending
 * on the application and type of binary signal.
 *
 * This device is low-power enabled so it will enter low-power mode just
 * after reading the binary states and transmitting them over the SWAP
 * network.
 *
 * Associated Device Definition File, defining registers, endpoints and
 * configuration parameters:
 * bininp.xml (Binary input device)
 */
 
#include "regtable.h"
#include "panstamp.h"

/**
 * Interrupt masks
 */
#define PCINTMASK0    0x03  // PB[0:1]
#define PCINTMASK1    0x3F  // PC[0:5]
#define PCINTMASK2    0xE8  // PD[3], PD[5:7]

/**
 * Macros
 */
#define pcEnableInterrupt()     PCICR = 0x07    // Enable Pin Change interrupts on all ports
#define pcDisableInterrupt()    PCICR = 0x00    // Disable Pin Change interrupts

/**
 * LED pin
 */
#define LEDPIN               4

/**
 * Pin Change Interrupt flag
 */
boolean pcIRQ = false;

/**
 * Pin Change Interrupt vectors
 */
SIGNAL(PCINT0_vect)
{
  panstamp.wakeUp();
  pcIRQ = true;
}
SIGNAL(PCINT1_vect)
{
  panstamp.wakeUp();
  pcIRQ = true;
}
SIGNAL(PCINT2_vect)
{
  panstamp.wakeUp();
  pcIRQ = true;
}

/**
 * setup
 *
 * Arduino setup function
 */
void setup()
{
  int i;

  pinMode(LEDPIN, OUTPUT);
  digitalWrite(LEDPIN, LOW);

  // Init panStamp
  panstamp.init();

  // Transmit product code
  getRegister(REGI_PRODUCTCODE)->getData();

  // Enter SYNC state
  panstamp.enterSystemState(SYSTATE_SYNC);

  // During 3 seconds, listen the network for possible commands whilst the LED blinks
  for(i=0 ; i<6 ; i++)
  {
    digitalWrite(LEDPIN, HIGH);
    delay(100);
    digitalWrite(LEDPIN, LOW);
    delay(400);
  }
  // Transmit periodic Tx interval
  getRegister(REGI_TXINTERVAL)->getData();
  // Transmit power voltage
  getRegister(REGI_VOLTSUPPLY)->getData();
  // Switch to Rx OFF state
  panstamp.enterSystemState(SYSTATE_RXOFF);

  // PCINT2 group
  pinMode(3, INPUT);
  pinMode(5, INPUT);
  pinMode(6, INPUT);
  pinMode(7, INPUT);
  PCMSK2 = PCINTMASK2;

  // PCINT0 group
  pinMode(8, INPUT);
  pinMode(9, INPUT);
  PCMSK0 = PCINTMASK0;

  // PCINT1 group
  pinMode(14, INPUT);
  pinMode(15, INPUT);
  pinMode(16, INPUT);
  pinMode(17, INPUT);
  pinMode(18, INPUT);
  pinMode(19, INPUT);
  PCMSK1 = PCINTMASK1;

  // Enable Pin Change Interrupts
  pcEnableInterrupt();
}

/**
 * loop
 *
 * Arduino main loop
 */
void loop()
{
  // Sleep indefinitely
  panstamp.goToSleep(false);
  //panstamp.sleepWd(WDTO_8S);
  
  if (pcIRQ)
  {
    pcDisableInterrupt();
    // Transmit binary states
    getRegister(REGI_BININPUTS)->getData();
    //Ready to receive new PC interrupts
    pcIRQ = false;
    pcEnableInterrupt();
  }
}

