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

#ifndef _PANSTREAM_H
#define _PANSTREAM_H

#include "Arduino.h"
#include "swpacket.h"
#include "register.h"
#include "commonregs.h"

#define PANSTREAM_BUFFERSIZE 64
#define PANSTREAM_MAXDATASIZE SWAP_REG_VAL_LEN-4

#define SWAP_MANUFACT_ID 0xFF
#define SWAP_PRODUCT_ID 0xFF
#define HARDWARE_VERSION 0xFF
#define FIRMWARE_VERSION 0xFF

/**
 * 
 * Register indexes
 * 
 */

DEFINE_REGINDEX_START()
REGI_STREAM
DEFINE_REGINDEX_END()

struct PanStreamReceivedMessage {
  uint8_t received_bytes;
  uint8_t received_id;
  uint8_t send_id;
  uint8_t num_bytes;
  byte *data;
};

struct PanStreamStatusMessage {
  uint8_t received_bytes;
  uint8_t received_id;
  uint8_t send_id;
  byte send_buffer[PANSTREAM_BUFFERSIZE];
  uint8_t num_bytes;
};

class PanStreamClass : public Stream

{
public:

  PanStreamClass();
  
  size_t write(uint8_t c);
  int available();
  int read();
  int peek();
  void flush();

  PanStreamStatusMessage send_message;
  void receiveMessage(PanStreamReceivedMessage *v);

protected:

private:
  byte receive_buffer[PANSTREAM_BUFFERSIZE];
  uint8_t send_len;
  uint8_t receive_pos;
  uint8_t receive_len;
  uint8_t master_id;
  uint8_t id;
  void sendSwapStatus();
};

extern PanStreamClass PanStream;

#endif

