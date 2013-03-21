/**
 * Copyright (c) 2011 panStamp <contact@panstamp.com>
 * 
 * This file is part of the panStamp project.
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
 * Author: Daniel Berenguer
 * Creation date: 10/02/2012
 */

#include "repeater.h"
#include "swpacket.h"
#include "panstamp.h"

/**
 * init
 *
 * Initialize repeater
 *
 * 'maxHop': maximum hop count
 */
void REPEATER::init(byte maxHop)
{
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
  panstamp.cc1101.disableAddressCheck();    // Disable address check
  panstamp.packetHandler = handlePacket;    // Set custom packet handler
  enable = true;                            // Enable repeater
}

/**
 * stop
 *
 * Stop repeater
 */
void REPEATER::stop(void)
{
  panstamp.cc1101.enableAddressCheck();     // Enable address check
  panstamp.packetHandler = NULL;            // Disable custom packet handler
  enable = false;                           // Disable repeater

}

/**
 * Class constructor
 */
REPEATER::REPEATER(void)
{
  byte i;
  enable = false;
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
  bool repeatPacket = true;
  unsigned long currentTime;

  // Repeater enabled?
  if (repeater.enable)
  {
    // Don't repeat packets addressed to our device
    if (packet->destAddr != panstamp.cc1101.devAddress)
    {
      // Don't repeat beyond the maximum hop count
      if (packet->hop < repeater.maxHopCount)
      {
        byte i;        

        // Check received packet against the latest transactions
        for(i=0 ; i<REPEATER_TABLE_DEPTH ; i++)
        {
          // Same source/destination node?
          if (repeater.transactions[i].regAddr == packet->regAddr)
          {
            // Same SWAP function?
            if (repeater.transactions[i].function == packet->function)
            {
              // Different source of transmission?
              if (repeater.transactions[i].srcAddr != packet->srcAddr)
              {
                // Same cyclic nonce?
                if (repeater.transactions[i].nonce == packet->nonce)
                {
                  currentTime = millis();
                  // Time stamp not expired?
                  if ((currentTime - repeater.transactions[i].timeStamp) < REPEATER_EXPIRATION_TIME)
                    repeatPacket = false;   //Don't repeat packet
                }
              }
            }
          }
        }

        // Repeat packet?
        if (repeatPacket)
        {
          packet->srcAddr = panstamp.cc1101.devAddress;   // Modify source address
          packet->hop++;                                  // Increment hop counter
          delay(SWAP_TX_DELAY);                           // Delay before sending
          if (packet->send())                             // Repeat packet
            repeater.saveTransaction(packet);             // Save transaction
        }
      }
    }
  }
}

/**
 * saveTransaction
 *
 * Save transaction in array
 *
 * 'packet': SWAP packet being repeated
 */
void REPEATER::saveTransaction(SWPACKET *packet)
{
  byte i;

  // Move all packets one position forward
  for(i=REPEATER_TABLE_DEPTH-1 ; i>0 ; i--)
    transactions[i] = transactions[i-1];

  // Save current transaction in first position
  transactions[0].timeStamp = millis();         // Current time stamp
  transactions[0].function = packet->function;  // SWAP function
  transactions[0].srcAddr = packet->srcAddr;    // Source address
  transactions[0].nonce = packet->nonce;        // Cyclic nonce
  transactions[0].regAddr = packet->regAddr;    // Register address
}

/**
 * Pre-instantiate REPEATER object
 */
REPEATER repeater;

