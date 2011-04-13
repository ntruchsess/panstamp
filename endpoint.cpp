/**
 * endpoint.cpp
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
 * Creation date: 03/03/2011
 */

#include "endpoint.h"
#include "swinfo.h"

byte epIndex = 0;

/**
 * getData
 * 
 * Update and get endpoint value
 */
void ENDPOINT::getData(void) 
{
  // Update endpoint value
  if (updateValue != NULL)
    updateValue(id);
  // Send SWAP information message about the new value
  sendSwapInfo();
}

/**
 * setData
 * 
 * Set endpoint value
 * 
 * 'data'	New endpoint value
 */
void ENDPOINT::setData(byte *data) 
{
  // Update endpoint value
  if (setValue != NULL)
    setValue(data);

  // Send SWAP information message
  sendSwapInfo();
}

/**
 * sendSwapInfo
 * 
 * Send SWAP information message
 */
void ENDPOINT::sendSwapInfo(void) 
{
  SWINFO packet = SWINFO(id, value, length);

  packet.send();
}

/**
 * sendPriorSwapInfo
 * 
 * Send SWAP information message before applying teh new value
 *
 * 'newVal'  New value
 */
void ENDPOINT::sendPriorSwapInfo(byte *newVal) 
{
  SWINFO packet = SWINFO(id, newVal, length);

  packet.send();
}
