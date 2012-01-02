/**
 * sensor
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
 * Creation date: 03/31/2011
 */

#include "Arduino.h"
#include "regtable.h"

/**
 * Pin definitions
 */
#define PORTW_DHT11_DATA  PORTD
#define PORTR_DHT11_DATA  PIND
#define PORTD_DHT11_DATA  DDRD
#define PORTW_DHT11_PWR   PORTD
#define PORTD_DHT11_PWR   DDRD
#define BIT_DHT11_DATA    6
#define BIT_DHT11_PWR     5
#define setDataPin()      bitSet(PORTW_DHT11_DATA, BIT_DHT11_DATA)
#define clearDataPin()    bitClear(PORTW_DHT11_DATA, BIT_DHT11_DATA)
#define getDataPin()      bitRead(PORTR_DHT11_DATA, BIT_DHT11_DATA)
#define setDataInput()    bitClear(PORTD_DHT11_DATA, BIT_DHT11_DATA)
#define setDataOutput()   bitSet(PORTD_DHT11_DATA, BIT_DHT11_DATA)
#define sensorON()        bitSet(PORTW_DHT11_PWR, BIT_DHT11_PWR)
#define sensorOFF()       bitClear(PORTW_DHT11_PWR, BIT_DHT11_PWR)
#define setPwrOutput()    bitSet(PORTD_DHT11_PWR, BIT_DHT11_PWR)

/**
 * Local functions
 */
byte sensor_ReadByte(void);

/**
 * sensor_ReadByte
 *
 * Read data byte from DHT11 sensor
 */
byte sensor_ReadByte(void)
{
  byte i, result = 0;
  int count = 20000;

  for(i=0; i< 8; i++)
  {
    while(!getDataPin())
    {
      if (--count == 0)
        return -1;
    }
    delayMicroseconds(30);
		
    if (getDataPin())
      result |=(1<<(7-i));

    count = 20000;

    while(getDataPin())
    {
      if (--count == 0)
        return -1;
    }
  }
  return result;
}

/**
 * sensor_ReadTempHum
 *
 * Read temperature and humidity values from DHT11 sensor
 *
 * Return -1 in case of error. Return 0 otherwise
 */
int sensor_ReadTempHum(void)
{
  byte dht11Data[5];
  byte dht11_in, i, dht11Crc;
  int result, temperature, humidity;
  
  // Power ON sensor
  setPwrOutput();
  sensorON();
  delay(400);
  
  setDataOutput();
  setDataPin();
  
  // Start condition
  clearDataPin();
  delay(18);
  setDataPin();
  delayMicroseconds(40);	
  setDataInput();
  delayMicroseconds(40);
  
  if ((dht11_in = getDataPin()))
    return -1;  // Start condition not met

  delayMicroseconds(80);	
  if (!(dht11_in = getDataPin()))
    return -1;  // Start condition not met
  delayMicroseconds(80);

  // Now ready for data reception
  
  for (i=0; i<5; i++)
    dht11Data[i] = sensor_ReadByte();

  setDataOutput();
  setDataPin();
  
  // Power OFF sensor
  sensorOFF();
  
  dht11Crc = dht11Data[0] + dht11Data[1] + dht11Data[2] + dht11Data[3];
  // check check_sum
  if(dht11Data[4]!= dht11Crc)
    return -1;  // CRC error

  // Prepare values for 2-decimal format:
  temperature = dht11Data[2] * 100;  // Temperature
  humidity = dht11Data[0] * 100;     // Humidity
  
  dtTempHum[0] = (temperature >> 8) & 0xFF;
  dtTempHum[1] = temperature & 0xFF;
  dtTempHum[2] = (humidity >> 8) & 0xFF;
  dtTempHum[3] = humidity & 0xFF;
  
  return 0;
}
