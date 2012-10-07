/**
 * repeater.cpp
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
 * Creation date: 10/02/2012
 */

#include "repeater.h"


void handlePacket(SWPACKET *packet);

/**
 * init
 *
 * Initialize repeater
 *
 * 'panstamp': PANSTAMP object
 * 'maxHop': maximum hop count
 */
void REPEATER::init(PANSTAMP panstamp, byte maxHop)
{
  this->panstamp = panstamp;
  maxHopCount = maxHop;
  start();
}

/**
 * start
 *
 * Start repeater
 */
void REPEATER::start(void)
{
  enableRepeater();
  panstamp.cc1101.disableAddressCheck();
}

/**
 * stop
 *
 * Stop repeater
 */
void REPEATER::stop(void)
{
  disableRepeater();
  panstamp.cc1101.enableAddressCheck();
}

/**
 * Class constructor
 */
REPEATER::REPEATER(void)
{
  enable = false;
  panstamp.packetHandler = handlePacket;
}

/**
 * handlePacket
 *
 * Handle incoming packet. Repeat if necessary
 *
 * 'packet': Pointer to the SWAP packet received
 */
void handlePacket(SWPACKET *packet)
{
  // Repeater enabled?
  if (repeater.enable)
  {
    // Don't repeat packets addressed to our device
    if (packet->destAddr != repeater.panstamp.cc1101.devAddress)
    {
      // Don't repeat beyond the maximum hop count
      if (packet->hop < repeater.maxHopCount)
      {
        byte i;        

        // Check received packet against the latest packets repeated
        for(i=0 ; i<REPEATER_TABLE_DEPTH ; i++)
        {       
          if (packet->equals(repeater.repeatedPacket[i]))
            return;
        }

        packet->hop++;                  // Increment hop counter
        delay(SWAP_TX_DELAY);           // Delay before sending
        if (packet->send())             // Repeat packet
          repeater.savePacket(*packet); // Update last packet repeated
      }
    }
  }
}

/**
 * savePacket
 *
 * Save SWA^àcket in global array
 *
 * 'packet': SWAP packet to be saved
 */
void REPEATER::savePacket(SWPACKET packet)
{
  byte i;

  // Move all packets one position forward
  for(i=REPEATER_TABLE_DEPTH-1 ; i>0 ; i--)
    repeatedPacket[i] = repeatedPacket[i-1];

  // Save packet in first position
  repeatedPacket[0] = packet;
}

/**
 * Pre-instantiate REPEATER object
 */
REPEATER repeater;

