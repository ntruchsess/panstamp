#include <panstamp.h>
#include <EEPROM.h>
//#include <Firmata.h>
#include <PanStream.h>
//#include "HardwareSerial.h"
//#include <Wire.h>  // remove this after first compile
//#include <Servo.h> // remove this after first compile

/**
 * LED pin
 */
#define LEDPIN 4

#include "regtable.h"
PanStreamClass PanStream(REGI_STREAM);

void setup()
{
  pinMode(LEDPIN, OUTPUT);

  Serial.begin(9600);
  Serial.println("startup");
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
      Serial.println("available");
      Serial.println( bytes );
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
