/**
 * channel.cpp
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
 * Creation date: 08/24/2012
 */

#include "channel.h"

/**
 * CHANNEL
 * 
 * Class constructor
 */
CHANNEL::CHANNEL(void)
{
}

/**
 * CHANNEL
 * 
 * Class constructor
 *
 * 'vcc'     Voltage supply
 * 'vPin'    Arduino analog pin connected to the AC voltage signal
 * 'iPin'    Arduino analog pin connected to the AC current signal
 * 'vScale'  Scaling factor for the voltage signal
 * 'iScale'  Scaling factor for the current signal
 * 'pShift'  Power factor offset (obtained during calibration)
 */
CHANNEL::CHANNEL(unsigned int vcc, int vPin, int iPin, float vScale, float iScale, float pfShift)
{
  enable = true;
  voltageSupply = vcc;
  voltagePin = vPin;
  currentPin = iPin;
  voltageScale = vScale;
  currentScale = iScale;
  pfOffset = pfShift;
  peakVoltage = 0;
  peakCurrent = 0;
  kwh = 0;
  lastTime = 0;
}

/**
 * update
 * 
 * Update AC channel readings
 */
bool CHANNEL::update(void) 
{
  unsigned long adcV1, adcV2, adcI;
  float voltage, current;
  static double accumulated;
  static int i = 0;
  const float peakToRMS = 0.707106781;       // Peak to RMS conversion factor
  unsigned long currentTime, elapsedTime;
  double energy;
  bool getEnergy = false;
  const float scale = ACVOLT_SCALE;

   
  //Read voltage and current
  adcV1 = analogRead(voltagePin);    // First AC voltage reading
  adcI = analogRead(currentPin);     // AC current reading
  adcV2 = analogRead(voltagePin);    // Second AC current reading
  adcV1 += adcV2;
  adcV1 /= 2;                        // Average between both voltage readings. This should give us
                                     // an approximate value of the voltage at the moment of reading
                                     // the current value

  // Discard 0 and negative voltages since we are working with a rectified voltage signal
  if (adcV1 > 0)
  {
    // Process AC voltage
    adcV1 = adcV1 * voltageSupply;
    adcV1 *= scale;
    voltage = adcV1 / 1023;
    voltage += ACVOLT_OFFSET_DIODE;    // Apply offset
    voltage *= voltageScale;
    voltage /= 1000;                   // convert to volts
  
    //Process AC current
    adcI = adcI * voltageSupply;
    current = adcI / 1023;
    current -= voltageSupply/2;        // Apply offset
    current *= currentScale;
    current /= 1000;                   // Convert to amps
    // Update peak current
    if (current > peakCurrent)
      peakCurrent = current;

    // Update peak voltage
    if (voltage > peakVoltage)
      peakVoltage = voltage;

    // Prepare for active power calculation
    accumulated += voltage * current;
    i++;
    
    // When a given amount of samples is read
    if (i == NB_OF_SAMPLES)
    {
      // Read current time
      currentTime = millis();
      if (lastTime > 0)
      {
        // Elapsed time between readings
        elapsedTime = currentTime - lastTime;  
        // Calculate KWh this time
        getEnergy = true;
      }
      // Update last time
      lastTime = currentTime;
  
      // Active power (W)
      if (accumulated < 0)
        accumulated = 0;
      actPower = accumulated / (NB_OF_SAMPLES/2);
      accumulated = 0;
      // RMS voltage (V)
      rmsVoltage = peakVoltage * peakToRMS;
      peakVoltage = 0;
      // RMS current (A)
      rmsCurrent = peakCurrent * peakToRMS;
      peakCurrent = 0;
      // Apparent power (VA)
      appPower = rmsVoltage * rmsCurrent;
      // Power factor
      powerFactor = actPower / appPower;
      // Can't be greater than 1
      if (powerFactor > 1.0)
      {
        powerFactor = 1;
        actPower = appPower;
      }
      
      i = 0;

      // Power factor offset to be applied?
      if (pfOffset > 0 && powerFactor < 1)
      {
        // Correct power factor
        powerFactor += pfOffset;
        if (powerFactor > 1)
          powerFactor = 1;
          
        // Back calculate active power
        actPower = appPower * powerFactor;
      }

      if (getEnergy)
      {
        energy = actPower * elapsedTime;
        energy /= 3600000;        
        kwh += energy;
      }

      return true;    
    }
  }
  
  return false;
}

/**
 * run
 * 
 * Run channel readings and calculations
 */
void CHANNEL::run(void) 
{
  while(!update())
  {
  }

  /*
  Serial.print(rmsVoltage, DEC);
  Serial.print(" ");
  Serial.print(rmsCurrent, DEC);
  Serial.print(" ");
  Serial.print(appPower, DEC);
  Serial.print(" ");
  Serial.print(actPower, DEC);
  Serial.print(" ");
  Serial.print(powerFactor, DEC);
  Serial.print(" ");
  Serial.println(kwh, DEC);
  */
}
