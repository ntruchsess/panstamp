/**
 * dht11.cpp
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
 * Creation date: 12/08/2011
 */

#include "dht11.h"

#define setDataPin()      bitSet(PORTW_DHT11_DATA, BIT_DHT11_DATA)
#define clearDataPin()    bitClear(PORTW_DHT11_DATA, BIT_DHT11_DATA)
#define getDataPin()      bitRead(PORTR_DHT11_DATA, BIT_DHT11_DATA)
#define setDataInput()    bitClear(PORTD_DHT11_DATA, BIT_DHT11_DATA)
#define setDataOutput()   bitSet(PORTD_DHT11_DATA, BIT_DHT11_DATA)

/**
 * readByte
 *
 * Read data byte from DHT11 sensor
 *
 * Return byte read or -1 in case of error
 */
int DHT11::readByte(void)
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
 * read
 *
 * Read temperature and humidity values
 *
 * Return -1 in case of CRC error. Return 0 otherwise.
 */
int DHT11::read(void)
{
  byte dht11Data[5];
  byte val, i, dht11Crc;
  int result;
   
  setDataOutput();
  setDataPin();
  
  // Start condition
  clearDataPin();
  delay(18);
  setDataPin();
  delayMicroseconds(40);	
  setDataInput();
  delayMicroseconds(40);
	
  if (getDataPin())
    return -1;  // Start condition not met
  delayMicroseconds(80);	
  if (!getDataPin())
    return -1;  // Start condition not met
  delayMicroseconds(80);

  // now ready for data reception
  for (i=0; i<5; i++)
  {
    if ((val = readByte()) < 0)
      return -1;
    dht11Data[i] = val;
  }

  setDataOutput();
  setDataPin();
   
  dht11Crc = dht11Data[0] + dht11Data[1] + dht11Data[2] + dht11Data[3];
  // check check_sum
  if(dht11Data[4]!= dht11Crc)
    return -1;  // CRC error

  humidity = dht11Data[0];
  temperature = dht11Data[2];

  return 0;
}

