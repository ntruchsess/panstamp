/**
 * Copyright (c) 2013 Norbert Truchsess
 *
 * This file is a contribution to the panStamp project.
 *
 * panStamp  is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * panStamp is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with panStamp; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
 * USA
 *
 * Author: Norbert Truchsess
 * Creation date: 05/30/2013
 */

#include <panstamp.h>
#include <EEPROM.h>
#include <PanStream.h>

/**
 * LED pin//#include <Firmata.h>
 * 
 */
#define LEDPIN 4

#include "regtable.h"
PanStreamClass PanStream(REGI_STREAM);

void setup()
{
  pinMode(LEDPIN, OUTPUT);

  //Serial.begin(9600);
  //Serial.println("startup");
  //delay(10000);
  // Init panStamp
  panstamp.init();

  PanStream.init();
  
  // Transmit product code
  getRegister(REGI_PRODUCTCODE)->getData();

  panstamp.enterSystemState(SYSTATE_RXON);
}

bool
isTime(unsigned long &timeMark, unsigned long timeInterval)
{
  if( millis() - timeMark >= timeInterval )
    {
      timeMark = millis();
      return true;
    }

  return false;
}

static unsigned long last_send_time = 0;
void loop()
{
  if( byte bytes = PanStream.available() )
    {
      //Serial.println("available");
      //Serial.println( bytes );
      char buff[64];

      bytes = PanStream.readBytes(buff, min(bytes,64));

      for( byte i = 0; i < bytes; ++i )
        {
          if( buff[i] >= 'a' && buff[i] <= 'z' )
            buff[i] -= 'a'-'A';
          else if( buff[i] >= 'A' && buff[i] <= 'Z' )
            buff[i] += 'a'-'A';

          PanStream.write(buff[i]);
        }
      PanStream.flush();

      //PanStream.write(buff,bytes);
    }
  else if( isTime( last_send_time, 60000 ) )
    {
      PanStream.print("abcdefghijklmnopqrstuvwxyz ");
      PanStream.print("Hello World: ");
      PanStream.println(last_send_time);

      int old_value = digitalRead(LEDPIN);
      digitalWrite(LEDPIN, old_value==LOW?HIGH:LOW);   // toggle led
    }
}
