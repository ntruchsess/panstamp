/**
 * endpoint.h
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

#ifndef _ENDPOINT_H
#define _ENDPOINT_H

#include "WProgram.h"

extern byte epIndex;

/**
 * Class: ENDPOINT
 * 
 * Description:
 * Endpoint class
 */
class ENDPOINT
{
  private:
    /**
     * Pointer to the endpoint "updater" function
     *
     *  'eId'  Endpoint ID     
     */
    const void (*updateValue)(byte eId);

    /**
     * Pointer to the endpoint "setter" function
     *
     *  'v'  New endpoint value
     */
    const void (*setValue)(byte *v);

  public:
    /**
     * Endpoint id
     */
    const byte id;
    
    /**
     * Endpoint value
     */
    byte *value;
    
    /**
     * Data length
     */
    const byte length;

    /**
     * ENDPOINT
     * 
     * Constructor
     * 
     * 'val'	    Pointer to the endpoint value
     * 'len'	    Length of the endpoint value
     * 'getValH'    Pointer to the getter function
     * 'setValH'    Pointer to the setter function
     */
    ENDPOINT(byte *val, const byte len, const void (*updateValH)(byte eId), const void (*setValH)(byte *v)):id(epIndex++), value(val), length(len), updateValue(updateValH), setValue(setValH) {};

    /**
     * getData
     * 
     * Update and get endpoint value
     * 
     */
    void getData();

    /**
     * setData
     * 
     * Set endpoint value
     * 
     * 'data'	New endpoint value
     */
    void setData(byte *data);

    /**
     * sendSwapInfo
     * 
     * Send SWAP information message
     */
    void sendSwapInfo(void);

    /**
     * sendPriorSwapInfo
     * 
     * Send SWAP information message before applying teh new value
     *
     * 'newVal'  New value
     */
    void sendPriorSwapInfo(byte *newVal);
};

/**
 * Array of endpoints
 */
extern ENDPOINT* endpoint[];

/**
 * Extern global functions
 */
extern void setupEndpoints(void);

#endif

