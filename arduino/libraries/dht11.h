/**
 * dht11.h
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

#ifndef DHT11_H
#define DHT11_H

#include "Arduino.h"

/**
 * Pin definitions
 */
#define PORTW_DHT11_DATA  PORTD
#define PORTR_DHT11_DATA  PIND
#define PORTD_DHT11_DATA  DDRD
#define BIT_DHT11_DATA    6

/**
 * Library version
 */
#define DHT11_LIB_VERSION   0.1.0

class DHT11
{
  private:
    /**
     * readByte
     *
     * Read data byte from DHT11 sensor
     *
     * Return byte read or -1 in case of error
     */
    int readByte(void);

  public:
    /**
     * Humidity value
     */
	  int humidity;

    /**
     * Temperature value

     */
	  int temperature;

    /**
     * read
     *
     * Read temperature and humidity values
     *
     * Return -1 in case of CRC error. Return 0 otherwise.
     */
    int read(void);
};

#endif

