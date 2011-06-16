/**
 * dht11.pde
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

#include "WProgram.h"

/**
 * Pin definitions
 */
/*
#define PORTW_DHT11_DATA  PORTC
#define PORTR_DHT11_DATA  PINC
#define PORTD_DHT11_DATA  DDRC
#define PORTW_DHT11_PWR   PORTB
#define PORTD_DHT11_PWR   DDRB
*/
#define PORTW_DHT11_DATA  PORTD
#define PORTR_DHT11_DATA  PIND
#define PORTD_DHT11_DATA  DDRD
#define PORTW_DHT11_PWR   PORTD
#define PORTD_DHT11_PWR   DDRD
#define BIT_DHT11_DATA    7
//#define BIT_DHT11_PWR     1
#define BIT_DHT11_PWR     6
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
byte dht11_ReadByte(void);

/**
 * dht11_ReadByte
 *
 * Read data byte from DHT11 sensor
 */
byte dht11_ReadByte(void)
{
  byte i, result = 0;
  
  for(i=0; i< 8; i++)
  {
    while(!getDataPin());
    delayMicroseconds(30);
		
    if (getDataPin())
      result |=(1<<(7-i));
    while(getDataPin());
  }
  return result;
}

/**
 * dht11_ReadTempHum
 *
 * Read temperature and humidity values
 *
 * Return integer with the following containing hum(1 byte):temp(1 byte)
 */
int dht11_ReadTempHum(void)
{
  byte dht11Data[5];
  byte dht11_in, i, dht11Crc;
  int result;
  
  // Power ON sensor
  setPwrOutput();
  sensorON();
  delay(200);
  
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

  // now ready for data reception
  for (i=0; i<5; i++)
    dht11Data[i] = dht11_ReadByte();

  setDataOutput();
  setDataPin();
  
  // Power OFF sensor
  sensorOFF();
  
  dht11Crc = dht11Data[0] + dht11Data[1] + dht11Data[2] + dht11Data[3];
  // check check_sum
  if(dht11Data[4]!= dht11Crc)
    return -1;  // CRC error

  result = ((dht11Data[0] << 8) & 0xFF00) | (dht11Data[2] & 0xFF);
  
  return result;
}

