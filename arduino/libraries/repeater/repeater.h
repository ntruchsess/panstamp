/**
 * repeater.h
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
 * Creation date: 10/01/2012
 */

#ifndef _REPEATER_H
#define _REPEATER_H

#include "swpacket.h"
#include "panstamp.h"

/**
 * Definitions
 */
#define REPEATER_TABLE_DEPTH  10

/**
 * Macros
 */
#define enableRepeater()    enable = true
#define disableRepeater()   enable = false

/**
 * Cñass declaration
 */
class REPEATER
{
  public:
    /**
     * Enable flag
     */
    bool enable;

    /**
     * PANSTAMP object
     */
    PANSTAMP panstamp;

    /**
     * Maximum hop
     */
    byte maxHopCount;

    /**
     * Last repeated packets
     */
    SWPACKET repeatedPacket[REPEATER_TABLE_DEPTH];


    /**
     * init
     *
     * Initialize repeater
     *
     * 'panstamp': PANSTAMP object
     * 'maxHop': maximum hop count
     */
    void init(PANSTAMP panstamp, byte maxHop);

    /**
     * start
     *
     * Start repeater
     */
    void start(void);

    /**
     * stop
     *
     * Stop repeater
     */
    void stop(void);

    /**
     * Class constructor
     */
    REPEATER(void);

    /**
     * savePacket
     *
     * Save SWA^àcket in global array
     *
     * 'packet': SWAP packet to be saved
     */
    void savePacket(SWPACKET packet);
};

/**
 * Global REPEATER object
 */
extern REPEATER repeater;

#endif

