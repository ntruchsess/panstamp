/**
 * panstamp.cpp
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

#include "panstamp.h"
#include "nvolat.h"

#define enableIRQ_GDO0()        attachInterrupt(0, isrGDO0event, FALLING);
#define disableIRQ_GDO0()       detachInterrupt(0);

/**
 * Register getter from the global array regTable
 */
extern REGISTER * getRegister(byte regId);
extern byte regTableSize;

/**
 * PANSTAMP
 *
 * Class constructor
 */
PANSTAMP::PANSTAMP(void)
{
  infoReceived = NULL;
}

/**
 * getRegister
 *
 * Return pointer to register with ID = regId
 *
 * 'regId'  Register ID
 */
REGISTER * getRegister(byte regId)
{
  if (regId >= regTableSize)
    return NULL;

  return regTable[regId]; 
}

/**
 * isrGDO0event
 *
 * Event on GDO0 pin (INT0)
 */
void isrGDO0event(void)
{
  CCPACKET ccPacket;
  SWPACKET swPacket;
  REGISTER *ptrReg;
  
  // Disable interrupt
  disableIRQ_GDO0();

  if (panstamp.cc1101.receiveData(&ccPacket) > 0)
  {
    if (ccPacket.crc_ok)
    {
      swPacket = SWPACKET(ccPacket);

      // Function
      switch(swPacket.function)
      {
        case SWAPFUNCT_CMD:
          if (swPacket.destAddr != 0)   // Broadcasted commands are not allowed
          {
            if ((ptrReg = getRegister(swPacket.regId)) != NULL)
              ptrReg->setData(swPacket.value.data);
          }
          break;
        case SWAPFUNCT_QRY:
          if ((ptrReg = getRegister(swPacket.regId)) != NULL)
            ptrReg->getData();
          break;
        case SWAPFUNCT_INF:
          // User callback function declared?
          if (panstamp.infoReceived != NULL)
            panstamp.infoReceived(&swPacket);
          break;
        default:
          break;
      }
    }
  }
  
  // Enable interrupt
  enableIRQ_GDO0();
}

/**
 * ISR(WDT_vect)
 *
 * Watchdog ISR. Called whenever a watchdog interrupt occurs
 */
ISR(WDT_vect)
{
}

/**
 * setup_watchdog
 * 
 * 'time'	Watchdog timer value
 */
void PANSTAMP::setup_watchdog(byte time) 
{
  byte bb;

  bb = time & 7;
  if (time > 7)
    bb|= (1<<5);

  bb|= (1<<WDCE);

  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCSR = bb;
  WDTCSR |= _BV(WDIE);    // Enable Watchdog interrupt
}

/**
 * init
 * 
 * Initialize panStamp board
 */
void PANSTAMP::init() 
{
  byte bVal;
  byte arrV[2];
  
  // Setup CC1101
  cc1101.init();

//EEPROM.write(EEPROM_SETUP_FLAG, 0xFF);
  bVal = EEPROM.read(EEPROM_SETUP_FLAG);
//Serial.println(bVal, HEX);
  if (bVal == EEFLAG_STORED)
  { 
    // Read RF channel from EEPROM
    bVal = EEPROM.read(EEPROM_FREQ_CHANNEL);
    // Set RF channel
    cc1101.setChannel(bVal);

    // Read security option byte from EEPROM
    security = EEPROM.read(EEPROM_SECU_OPTION);

    // Read network id from EEPROM
    arrV[0] = EEPROM.read(EEPROM_NETWORK_ID);
    arrV[1] = EEPROM.read(EEPROM_NETWORK_ID + 1);
    // Set Sync word
    cc1101.setSyncWord(arrV);
    
    // Read device address from EEPROM
    bVal = EEPROM.read(EEPROM_DEVICE_ADDR);
    // Set device address
    cc1101.setDevAddress(bVal);
  }
  else  // Save current settings in EEPROM
  {
    security = 0;

    EEPROM.write(EEPROM_SETUP_FLAG, EEFLAG_STORED);
    EEPROM.write(EEPROM_FREQ_CHANNEL, cc1101.channel);
    EEPROM.write(EEPROM_SECU_OPTION, security);
    EEPROM.write(EEPROM_NETWORK_ID, cc1101.syncWord[0]);
    EEPROM.write(EEPROM_NETWORK_ID+1, cc1101.syncWord[1]);
    EEPROM.write(EEPROM_DEVICE_ADDR, cc1101.devAddress);
  }

// Read device address from EEPROM
bVal = EEPROM.read(EEPROM_DEVICE_ADDR);
// Set device address
cc1101.setDevAddress(bVal);

  delayMicroseconds(50);  

  // Enter RX state
  cc1101.setRxState();

  // Attach callback function for GDO0 (INT0)
  enableIRQ_GDO0();

  // Default values
  nonce = 0xFF;
}

/**
 * reset
 * 
 * Reset panStamp
 */
void PANSTAMP::reset() 
{
  // Tell the network that our panStamp is restarting
  byte state[] = {SYSTATE_RESTART};
  getRegister(3)->sendPriorSwapInfo(state);

  // Reset panStamp
  wdt_disable();  
  wdt_enable(WDTO_15MS);
  while (1) {}
}

/**
 * sleepFor
 * 
 * Put panStamp into Power-down state during "time".
 * This function uses the internal watchdog timer in order to exit (interrupt)
 * from the power-down state
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
void PANSTAMP::sleepFor(byte time) 
{
  // Power-down CC1101
  cc1101.setPowerDownState();

  // Power-down panStamp
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();
  setup_watchdog(time);
  delayMicroseconds(10);
  // Disable ADC
  ADCSRA &= ~(1 << ADEN);
  // Unpower functions
  PRR = 0xFF;
  //power_all_disable();
  //clock_prescale_set(clock_div_8);
  // Enter sleep mode
  sleep_mode();

  // ZZZZZZZZ...

  // Exit from sleep
  sleep_disable();
  wdt_disable();
  // Re-enable functions
  //clock_prescale_set(clock_div_1);
  power_all_enable();
  // Enable ADC
  ADCSRA |= (1 << ADEN);
  // Reset CC1101
  cc1101.reset();
}

/**
 * getInternalTemp
 * 
 * Read internal (ATMEGA328 only) temperature sensor
 * 
 * Return:
 * 	Temperature in milli-degrees Celsius
 */
long PANSTAMP::getInternalTemp(void) 
{
  long result;

  // Read temperature sensor against 1.1V reference
  ADMUX = _BV(REFS1) | _BV(REFS0) | _BV(MUX3);
  delay(2); // Wait for Vref to settle
  ADCSRA |= _BV(ADSC); // Convert
  while (bit_is_set(ADCSRA,ADSC));
  result = ADCL;
  result |= ADCH<<8;
  result = (result - 125) * 1075;

  return result;
}

/**
 * setSecurity
 * 
 * Set security option
 * 
 * 'secu'	New option
 * 'save' If TRUE, save parameter in EEPROM
 */
void PANSTAMP::setSecurity(byte secu, bool save)
{
  if (security != secu)
  {
    security = secu;
    // Save in EEPROM
    if (save)
      EEPROM.write(EEPROM_SECU_OPTION, secu);
  }
}

/**
 * Pre-instantiate PANSTAMP object
 */
PANSTAMP panstamp;

