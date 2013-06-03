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

#include "panstamp.h"
#include "PanStream.h"

/**
 * Declaration of common callback functions
 */
DECLARE_COMMON_CALLBACKS()

/**
 * Definition of common registers
 */
DEFINE_COMMON_REGISTERS()

/*
 * Definition of custom registers
 */
REGISTER panStream((byte*)&PanStream.send_message,(byte)PANSTREAM_MAXDATASIZE, NULL, NULL);

/**
 * 
 * Initialize table of registers
 * 
 */
DECLARE_REGISTERS_START()
&panStream
DECLARE_REGISTERS_END()

/**
 * 
 * Definition of common getter/setter callback functions
 * 
 */
DEFINE_COMMON_CALLBACKS()

void onStatusReceived(SWPACKET *status);

PanStreamClass::PanStreamClass() {
  panstamp.statusReceived = &onStatusReceived;
  send_len = 0;
  receive_pos = 0;
  receive_len = 0;
  master_id = 0;
  id = 0;
}

size_t PanStreamClass::write(uint8_t c) {

  if (send_len == PANSTREAM_BUFFERSIZE) {
    return 0;
  }
  send_message.send_buffer[send_len++] = c;
  if (send_len >= PANSTREAM_MAXDATASIZE) {
    flush();
  }
  return 1;
};

int PanStreamClass::available() {

  return receive_len;
};

int PanStreamClass::read() {

  if (receive_len == 0) return -1;
  byte ret = receive_buffer[receive_pos++];
  if (receive_pos == PANSTREAM_BUFFERSIZE) receive_pos=0;
  receive_len--;
  return ret;
};

int PanStreamClass::peek() {

  if (receive_len == 0) return -1;
  return receive_buffer[receive_pos];
};

void PanStreamClass::flush() {

  // send new packet only if there's no outstanding acknowledge
  if (send_message.send_id==0 && send_len > 0) {
    id++;
    if (id==0) {
      id++;
    }
    send_message.send_id = id;
    send_message.num_bytes = send_len > PANSTREAM_MAXDATASIZE ? PANSTREAM_MAXDATASIZE : send_len;
    sendSwapStatus();
  }
};

void PanStreamClass::receiveMessage(PanStreamReceivedMessage* received) {

  bool send = false;
  if (received->received_id==send_message.send_id) { //previous packet acknowledged by master -> prepare new packet send data
    // discard data of previous packet
    uint8_t remaining_bytes = send_len-received->received_bytes;
    for (uint8_t i = 0; i < remaining_bytes; i++) {
      send_message.send_buffer[i] = send_message.send_buffer[received->received_bytes+i];
    }
    send_len = remaining_bytes;
    send_message.num_bytes = remaining_bytes > PANSTREAM_MAXDATASIZE ? PANSTREAM_MAXDATASIZE : remaining_bytes;
    if (remaining_bytes > 0) {
      id++;
      if (id==0) {
        id++;
      }
      send_message.send_id = id;
      send = true;
    } else {
      send_message.send_id = 0;
    }
  } else {
    //last packet not acknowledged -> send last packet data unaltered.
    send = true;
  }
  if (received->send_id!=0) {
    if (received->send_id!=master_id) { //new packet received (not a retransmit of a previously retrieved packet)
      master_id = received->send_id;
      uint8_t receive_bytes = //acknowledge number of bytes transfered to receive_buffer
          (received->num_bytes + receive_len > PANSTREAM_BUFFERSIZE) ?
              PANSTREAM_BUFFERSIZE - receive_len : received->num_bytes;
      send_message.received_bytes = receive_bytes;
      for (uint8_t i = 0; i < receive_bytes; i++) {
        receive_buffer[(receive_pos + receive_len + i) % PANSTREAM_BUFFERSIZE] = received->data[i];
      }
      receive_len+=receive_bytes;
      send_message.received_id = master_id; //acknowledge package
    }
    // if packet data was received before (received->send_id==master_id), acknowledge again
    send = true;
  }
  if (send) {
    sendSwapStatus();
  }
};

void PanStreamClass::sendSwapStatus() {
  SWSTATUS packet = SWSTATUS(REGI_STREAM, (byte*)&send_message, send_message.num_bytes+3);
  packet.send();
};

void onStatusReceived(SWPACKET *status) {
  PanStreamReceivedMessage message;
  byte *data = status->value.data;
  message.received_bytes = data[0];
  message.received_id = data[1];
  message.send_id = data[2];
  message.num_bytes = status->value.length-3;
  message.data = data+3;
  PanStream.receiveMessage(&message);
};

PanStreamClass PanStream;
