/**
 * eptable.h
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

#ifndef _EPTABLE_H
#define _EPTABLE_H

#include "WProgram.h"
#include "endpoint.h"

/**
 * Endpoint indexes
 */

enum EPINDEX
{
  EPI_PRODUCTCODE = 0,
  EPI_HWVERSION,
  EPI_FWVERSION,
  EPI_SYSSTATE,
  EPI_CARRIERFREQ,
  EPI_FREQCHANNEL,
  EPI_SECUOPTION,
  EPI_SECUNONCE,
  EPI_NETWORKID,
  EPI_DEVADDRESS,
  EPI_VOLTSUPPLY,
  EPI_HUMIDTEMP
};

/**
 * System states
 */
enum SYSTATE
{
  SYSTATE_RESTART = 0,
  SYSTATE_RUNNING,
  SYSTATE_CONFIG
};

/**
 * Array of endpoints
 */
extern ENDPOINT* epTable[];

#endif

