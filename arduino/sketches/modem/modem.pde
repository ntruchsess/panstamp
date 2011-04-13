/*
 * modem.pde
 *
 * Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
 * 
 * This file is part of the panStamp project.
 * 
 * panLoader  is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
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
 * Creation date: 15/02/2011
 */

#include "modem.h"
#include "cc1101.h"
#include "TimerOne.h"
#include "EEPROM.h"

#define enableIRQ()    attachInterrupt(0, isrINT0event, FALLING);
#define disableIRQ()   detachInterrupt(0);

char strSerial[SERIAL_BUF_LEN];          // Serial buffer
byte ch;
int len = 0;
SERMODE serMode = SERMODE_DATA;          // Serial mode (data or command mode)
byte t1Ticks = 0;                        // Timer 1 ticks
boolean t1Timeout = false;               // True when T1 times out

/**
 * CC1101 object
 */
CC1101 cc1101;

/**
 * isrINT0event
 *
 * Event on GDO0 pin (INT0)
 */
void isrINT0event(void)
{
  byte i;
  CCPACKET packet;
  
  // Disable interrupt
  disableIRQ();
  
  if (cc1101.receiveData(&packet) > 0)
  {
    if (packet.crc_ok && serMode == SERMODE_DATA)
    {
      Serial.print("(");
      if (packet.rssi < 0x10)
        Serial.print("0");
      Serial.print(packet.rssi, HEX);
      if (packet.lqi < 0x10)
        Serial.print("0");
      Serial.print(packet.lqi, HEX);
      Serial.print(")");
      for(i=0 ; i<packet.length ; i++)
      {
        if (packet.data[i] < 0x10)
          Serial.print(0, HEX);    // Leading zero
        Serial.print(packet.data[i], HEX);
      }
      Serial.println("");
    }
  }
  
  // Enable interrupt
  enableIRQ();
}

/*
 * isrT1event
 *
 * Timer1 interrupt routine
 */
void isrT1event(void)
{
  if (t1Ticks == MAX_SERIAL_SILENCE_TK)
  {
    Timer1.stop();
    t1Ticks = 0;
    // Pending "+++" command?
    if (!strcmp(strSerial, AT_GOTO_CMDMODE))
    {
      Serial.println("OK-Command mode");
      serMode = SERMODE_COMMAND;
    }
    memset(strSerial, 0, sizeof(strSerial));
    len = 0;
    Timer1.start();
  }
  else
    t1Ticks++;
}

/*
 * handleSerialCmd
 *
 * Handle serial command received
 *
 * 'command'  AT command received
 */
void handleSerialCmd(char* command)
{
  byte i, len;
  //unsigned short val = 0;
  byte arrV[2];
  CCPACKET packet;
  ATQUERY atQuery = ATQUERY_REQUEST;  
 
  // Data mode?
  if (serMode == SERMODE_DATA)
  {
    packet.length = strlen(command)/2;
    // Convert ASCII string into array of bytes
    for(i=0 ; i<packet.length ; i++)
    {     
      packet.data[i] = charToHex(command[i*2]) << 4;
      packet.data[i] |= charToHex(command[i*2 + 1]);
    }
    // Send packet via RF
    cc1101.sendData(packet);
  }
  // Command mode?
  else  // serMode = SERMODE_COMMAND
  {
    len = strlen(command);
    
    if (len < 5)
    {
      // Basic attention command
      if (!strcmp(strSerial, AT_ATTENTION))
        Serial.println("OK");
      // Reset modem
      else if (!strcmp(strSerial, AT_RESET))
      {
        Serial.println("OK");
        swReset();
      }
      // Go to serial data mode
      else if (!strcmp(strSerial, AT_GOTO_DATAMODE))
      {
        serMode = SERMODE_DATA;
        Serial.println("OK-Data mode");
      }
    }
    // Set new value
    else 
    {
      if ((strSerial[4] == '=') && (len >= 6))
      {
        // Get new value
        i = (charToHex(strSerial[5]) << 4) & 0xF0;
        i |= charToHex(strSerial[6]) & 0x0F;
        atQuery = ATQUERY_COMMAND;
      }
      // Hardware version
      if (!strncmp(strSerial, AT_HVERSION, 4))
      {
        if (atQuery == ATQUERY_REQUEST)
          Serial.println(HARDWARE_VERSION, HEX);
      }
      // Firmware version
      else if (!strncmp(strSerial, AT_FVERSION, 4))
      {
        if (atQuery == ATQUERY_REQUEST)
          Serial.println(FIRMWARE_VERSION, HEX);
      }
      // Carrier frequency
      else if (!strncmp(strSerial, AT_CARRIERFREQ, 4))
      {
        if (atQuery == ATQUERY_COMMAND)
        {
          if (i < CFREQ_LAST)
          {
            cc1101.setCarrierFreq((CARRIER_FREQ)i);
            Serial.println("OK");
          }
          else
            Serial.println("ERROR");
        }
        else
          Serial.println(cc1101.carrierFreq, HEX);   
      }
      // Frequency channel
      else if (!strncmp(strSerial, AT_FREQCHANNEL, 4))
      {
        if (atQuery == ATQUERY_COMMAND)
        {
          cc1101.setChannel(i);
          Serial.println("OK");
        }
        else
          Serial.println(cc1101.channel, HEX);
      }
      // Synchronization word
      else if (!strncmp(strSerial, AT_SYNCWORD, 4))
      {
        if (atQuery == ATQUERY_COMMAND)
        {
           if ((len-5) == 4)
          {
            arrV[0] = charToHex(strSerial[5]) << 4;
            arrV[0] |= charToHex(strSerial[6]);
            arrV[1] = charToHex(strSerial[7]) << 4;
            arrV[1] |= charToHex(strSerial[8]);
            cc1101.setSyncWord(arrV);
            Serial.println("OK");
          }
          else
            Serial.println("ERROR");
        }
        else
        {
          Serial.print(cc1101.syncWord[0], HEX);
          Serial.println(cc1101.syncWord[1], HEX);
        }
      }
      // Device address
      else if (!strncmp(strSerial, AT_DEVADDRESS, 4))
      {
        if (atQuery == ATQUERY_COMMAND)
        {
          cc1101.setDevAddress(i);
          Serial.println("OK");
        }
        else
          Serial.println(cc1101.devAddress, HEX);
      }
      else
        Serial.println("ERROR");
    }
  }
}

/**
 * setup
 *
 * Arduino setup function
 */
void setup()
{ 
  Serial.begin(9600);
  Serial.flush();

  // Reset serial buffer
  memset(strSerial, 0, sizeof(strSerial));
  
  // Init Timer1
  Timer1.initialize(TIMER1_TICK_PERIOD_US);
  // Attach interrupt function to Timer1
  Timer1.attachInterrupt(isrT1event);

  Serial.println("Let's go modem!");
   
  // Setup CC1101
  cc1101.init();

  delayMicroseconds(50);  

  // Enter RX state
  cc1101.setRxState();

  // Attach callback function for GDO0 (INT0)
  enableIRQ();
}

/**
 * loop
 *
 * Arduino main loop
 */
void loop()
{
  // Read serial command
  while (Serial.available() > 0)
  {
    resetTimer();
    ch = Serial.read();

    if (len >= SERIAL_BUF_LEN-1)
    {
      memset(strSerial, 0, sizeof(strSerial));
      len = 0;
    }
    else if (ch == 0x0D) 
    {
      strSerial[len] = 0;
      handleSerialCmd(strSerial);
      memset(strSerial, 0, sizeof(strSerial));
      len = 0;
    }
    else
    {
      strSerial[len] = ch; 
      len++;    
    }
  }
}

