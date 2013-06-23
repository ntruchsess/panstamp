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

void onStatusReceived(SWPACKET *status_pkt);

/**
 * SWSTATUS
 *
 * Class constructor
 *
 * 'rId'        Register id
 * 'dest'       Destination address
 * '*val'       New value
 * 'len'        Buffer length
 */
SWSTREAM::SWSTREAM(byte rId, byte dest, byte *val, byte len) {
  destAddr = dest;
  srcAddr = panstamp.cc1101.devAddress;
  hop = 0;
  security = panstamp.security & 0x0F;
  nonce = ++panstamp.nonce;
  function = SWAPFUNCT_STA;
  regAddr = panstamp.cc1101.devAddress;
  regId = rId;
  value.length = len;
  value.data = val;
}

PanStreamClass::PanStreamClass(byte reg) : reg(reg) {
  send_len = 0;
  receive_pos = 0;
  receive_len = 0;
  master_id = 0;
  id = 0;
}

void PanStreamClass::init() {
  panstamp.statusReceived = &onStatusReceived;
};

size_t PanStreamClass::write(uint8_t c) {

  while (send_len == PANSTREAM_BUFFERSIZE) {
    delay(1); //wait for the buffer to clear (by receiving the matching acknowledge-packet)
  }
  noInterrupts();
  send_message.send_buffer[send_len++] = c;
  interrupts();
  if (send_len >= PANSTREAM_MAXDATASIZE || (config.autoflush_time_ms>0 && next_transmit-millis()<0)) {
    flush();
  }
  return 1;
};

int PanStreamClass::available() {

  return receive_len;
};

int PanStreamClass::read() {

  if (receive_len == 0) return -1;
  noInterrupts();
  byte ret = receive_buffer[receive_pos++];
  if (receive_pos == PANSTREAM_BUFFERSIZE) receive_pos=0;
  receive_len--;
  noInterrupts();
  return ret;
};

int PanStreamClass::peek() {
  if (receive_len == 0) return -1;
  return receive_buffer[receive_pos];
};

void PanStreamClass::flush() {
  // send new packet only if there's no outstanding acknowledge
  noInterrupts();
  if (send_message.send_id==0 && send_len > 0) {
    id++;
    if (id==0) {
      id++;
    }
    send_message.send_id = id;
    send_message.num_bytes = send_len > PANSTREAM_MAXDATASIZE ? PANSTREAM_MAXDATASIZE : send_len;
    sendSwapStatus();
  }
  interrupts();
};

void PanStreamClass::receiveMessage(PanStreamReceivedMessage* received) {
  noInterrupts();
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
  interrupts();
};

void PanStreamClass::sendSwapStatus() {
  SWSTREAM packet = SWSTREAM(reg, config.destAddr, (byte*)&send_message, send_message.num_bytes+3);
  next_transmit = config.autoflush_time_ms+millis();
  packet.send();
};

void onStatusReceived(SWPACKET *status_pkt) {
  if( status_pkt->destAddr != panstamp.cc1101.devAddress ) { // ignore packets not for this device
    return;
  }
  if( status_pkt->regId != PanStream.reg ) {                // ignore packets not for the stream register
    return;
  }
  PanStreamReceivedMessage message;
  byte *data = status_pkt->value.data;
  message.received_bytes = data[0];
  message.received_id = data[1];
  message.send_id = data[2];
  message.num_bytes = status_pkt->value.length-3;
  message.data = data+3;
  PanStream.receiveMessage(&message);
};
