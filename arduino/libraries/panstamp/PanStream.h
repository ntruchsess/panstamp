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
//#define PANSTREAM_MAXDATASIZE 16-4

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

struct PanStreamRegister {
  volatile unsigned long autoflush_time_ms;
};

class PanStreamClass : public Stream

{
public:

  PanStreamClass(byte reg);
  
  size_t write(uint8_t c);
  int available();
  int read();
  int peek();
  void flush();
  void init();

  PanStreamRegister status;
  PanStreamStatusMessage send_message;
  void receiveMessage(PanStreamReceivedMessage *v);
  byte reg;

private:
  byte receive_buffer[PANSTREAM_BUFFERSIZE];
  volatile unsigned long next_transmit;
  volatile uint8_t send_len;
  volatile uint8_t receive_pos;
  volatile uint8_t receive_len;
  volatile uint8_t master_id;
  volatile uint8_t id;
  void sendSwapStatus();
};

extern PanStreamClass PanStream;

#endif

