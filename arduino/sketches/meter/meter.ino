/*
 * meter
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
 * panStamp is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with panStamp; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
 * USA
 * 
 * Author: Daniel Berenguer
 * Creation date: 09/02/2012
 *
 * Device:
 * Binary input + counter module
 *
 * Description:
 * Energy meter providing the following inputs:
 *
 * 1 x Input for voltage transformer: pin 4
 * 6 x Inputs for current transformers: pins 5, 6, 8, 9, 10 and 11
 * 3 x Inputs for pulse counters: pins 20, 21 and 22
 *
 * Associated Device Definition File, defining registers, endpoints and
 * configuration parameters:
 * meter.xml (Energy meter)
 */

#include "TimerOne.h"
#include "meter.h"

/**
 * Auxiliary variables
 */
byte channelNb;

SIGNAL(PCINT2_vect)
{
  pcIRQ = true;
}


/**
 * updateCounters
 *
 * Update counters
 *
 * Return:
 * bit 0 set -> Counter 0 changed
 * bit 1 set -> Counter 1 changed
 * bit 2 set -> Counter 2 changed
 */
byte updateCounters(void)
{
  byte i, res = 0;
  int state;

  for(i=0 ; i<sizeof(counterPin) ; i++)
  {
    state = bitRead(*counterPort[i], counterPin[i]);
    if (lastStateCount[i] != state)
    {      
      lastStateCount[i] = state;
    
      if (state == HIGH)
      {
        counters[i]++;
        res |= (1 << i);
      }
    }
  }

  return res;
}

/**
 * readVoltageSupply
 *
 * Read voltage supply (Vcc)
 *
 * Return voltage in mV
 */
unsigned int readVoltSupply(void)
{
  unsigned int result;
   
  // Read 1.1V reference against AVcc
  ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1);
  delay(2); // Wait for Vref to settle
  ADCSRA |= _BV(ADSC); // Convert
  while (bit_is_set(ADCSRA,ADSC));
  result = ADCL;
  result |= ADCH << 8;
  result = 1126400L / result; // Back-calculate AVcc in mV

  return result;
}

/**
 * isrT1event
 *
 * Timer1 interrupt routine
 */
void isrT1event(void)
{
  t1Ticks++;

  if (t1Ticks == txInterval)
  {
    t1Ticks = 0;
    transmit = true;
  }
}

/**
 * readInitValues
 *
 * Read initial values from EEPROM
 */
void readInitValues(void)
{
  byte val, i, j;
  byte channelConfig[CONFIG_CHANNEL_SIZE];
  byte pulseConfig[CONFIG_PULSEINPL_SIZE];
   
  // Read configuration for the energy channels
  for(i=0 ; i < (sizeof(channels)/sizeof(*channels)) ; i++)
  {
    for(j=0 ; j<CONFIG_CHANNEL_SIZE ; j++)
      channelConfig[j] = EEPROM.read(EEPROM_CONFIG_CHANNEL0 + CONFIG_CHANNEL_SIZE * i + j);
    getRegister(REGI_CHANNEL_CONFIG_0 + i)->setData(channelConfig);
  }

  // Read configuration for the pulse inputs
  for(i=0 ; i < (sizeof(counters)/sizeof(*counters)) ; i++)
  {
    for(j=0 ; j<CONFIG_PULSEINPL_SIZE ; j++)
      pulseConfig[j] = EEPROM.read(EEPROM_CONFIG_PULSE0 + CONFIG_PULSEINPL_SIZE * i + j);
    getRegister(REGI_PULSE_CONFIG_0 + i)->setData(pulseConfig);
  }

}

/**
 * setup
 *
 * Arduino setup function
 */
void setup()
{
  Serial.begin(38400);
  Serial.flush();
  Serial.println("Power meter ready!");

  // Read Vcc
  voltageSupply = readVoltSupply();
 
  // Create energy channel objects
  CHANNEL channel0(voltageSupply, PIN_ACVOLTAGE, 6, 17, 5);
  channels[0] = channel0;
  CHANNEL channel1(voltageSupply, PIN_ACVOLTAGE, 5, 17, 5);
  channels[1] = channel1;
  CHANNEL channel2(voltageSupply, PIN_ACVOLTAGE, 4, 17, 5);
  channels[2] = channel2;
  CHANNEL channel3(voltageSupply, PIN_ACVOLTAGE, 3, 17, 5);
  channels[3] = channel3;
  CHANNEL channel4(voltageSupply, PIN_ACVOLTAGE, 2, 17, 5);
  channels[4] = channel4;
  CHANNEL channel5(voltageSupply, PIN_ACVOLTAGE, 1, 17, 5);
  channels[5] = channel5;

  // Pulse inputs
  // Set pins as inputs
  DDRD &= ~PCINTMASK;

  // Set PC interrupt mask
  PCMSK0 = 0;
  PCMSK1 = 0;
  PCMSK2 = PCINTMASK;

  // Init panStamp
  panstamp.init();

  // Wireless transmission interval
  txInterval = panstamp.txInterval[0];
  txInterval = txInterval << 8 | panstamp.txInterval[1];

  // Transmit product code
  getRegister(REGI_PRODUCTCODE)->getData();

  // Enter SYNC state
  panstamp.enterSystemState(SYSTATE_RXON);
  
  // Read initial configuration settings from EEPROM
  readInitValues();
  
  // Initialize Timer1
  Timer1.initialize(TIMER1_TICK_PERIOD_US);
  Timer1.attachInterrupt(isrT1event);
  
  // Enable PCINT interrupt on counter pins
  pcEnableInterrupt();
}

/**
 * loop
 *
 * Arduino main loop
 */
void loop()
{
  // Measure energy data
  for(channelNb=0 ; channelNb < (sizeof(channels)/sizeof(*channels)) ; channelNb++)
  {
    if (channels[channelNb].enable)
    {
      // Read power data
      channels[channelNb].run();
    }
  }

  // Transmit energy data
  if (transmit)
  {
    transmit = false;
    for(channelNb=0 ; channelNb < (sizeof(channels)/sizeof(*channels)) ; channelNb++)
    {
      if (channels[channelNb].enable)
      {
        // Transmit channel data?
        getRegister(REGI_CHANNEL_ENERGY_0 + channelNb)->getData();
      }
    }
  }
  
  // Read pulses
  if (pcIRQ)
  {
    byte res = updateCounters();
    byte mask;
    if (res)
    {
      for(channelNb=0 ; channelNb<sizeof(counterPin) ; channelNb++)
      {
        mask = 1 << channelNb;
        // Input changed?
        if (res & mask)
        {
          // Transmit counter value
          getRegister(REGI_PULSE_COUNT_0 + channelNb)->getData();
        }
      }
    }
    //Ready to receive new PC interrupts
    pcIRQ = false;
  }
}
