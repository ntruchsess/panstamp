/**
 * eptable.pde
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

#include <EEPROM.h>
#include "product.h"
#include "panstamp.h"
#include "eptable.h"

/**
 * Endpoint setup
 */
// Product code
static byte dtProductCode[8] = {SWAP_MANUFACT_ID >> 24, SWAP_MANUFACT_ID >> 16 , SWAP_MANUFACT_ID >> 8, SWAP_MANUFACT_ID,
                       SWAP_PRODUCT_ID >> 24, SWAP_PRODUCT_ID >> 16 , SWAP_PRODUCT_ID >> 8, SWAP_PRODUCT_ID};
ENDPOINT epProductCode(dtProductCode, sizeof(dtProductCode), NULL, NULL);
// Hardware version
static byte dtHwVersion[4] = {HARDWARE_VERSION >> 24, HARDWARE_VERSION >> 16 , HARDWARE_VERSION >> 8, HARDWARE_VERSION};
ENDPOINT epHwVersion(dtHwVersion, sizeof(dtHwVersion), NULL, NULL);
// Firmware version
static byte dtFwVersion[4] = {FIRMWARE_VERSION >> 24, FIRMWARE_VERSION >> 16 , FIRMWARE_VERSION >> 8, FIRMWARE_VERSION};
ENDPOINT epFwVersion(dtFwVersion, sizeof(dtFwVersion), NULL, NULL);
// System state
static byte dtSysState[1] = {SYSTATE_RUNNING};
ENDPOINT epSysState(dtSysState, sizeof(dtSysState), NULL, &setSysState);
// Carrier frequency
ENDPOINT epCarrierFreq((byte*)(&panstamp.cc1101.carrierFreq), sizeof(panstamp.cc1101.carrierFreq), NULL, &setCarrierFreq);
// Frequency channel
ENDPOINT epFreqChannel(&panstamp.cc1101.channel, sizeof(panstamp.cc1101.channel), NULL, &setFreqChannel);
// Security option
ENDPOINT epSecuOption(&panstamp.security, sizeof(panstamp.security), NULL, &setSecuOption);
// Security nonce
ENDPOINT epSecuNonce(&panstamp.nonce, sizeof(panstamp.nonce), NULL, NULL);
// Network Id
ENDPOINT epNetworkId(&panstamp.cc1101.syncWord[0], sizeof(panstamp.cc1101.syncWord), NULL, &setNetworkId);
// Device address
ENDPOINT epDevAddress(&panstamp.cc1101.devAddress, sizeof(panstamp.cc1101.devAddress), NULL, &setDevAddress);
/*
 * Add here your custom endpoints
 */
// Voltage supply
static byte dtVoltSupply[2];
ENDPOINT epVoltSupply(dtVoltSupply, sizeof(dtVoltSupply), &updtVoltSupply, NULL);
// Temperature and humidity from the DHT11 sensor
static byte dtTempHum[2];
ENDPOINT epTempHum(dtTempHum, sizeof(dtTempHum), &updtTempHum, NULL);

/**
 * Initialize table of endpoints
 */
ENDPOINT *epTable[] = {
        &epProductCode,
	&epHwVersion,
	&epFwVersion,
        &epSysState,
	&epCarrierFreq,
	&epFreqChannel,
	&epSecuOption,
	&epSecuNonce,
	&epNetworkId,
	&epDevAddress,
  // Add here your custom endpoints
  	&epVoltSupply,
        &epTempHum
}; 

/**
 * "Update/Set" handling functions
 */

/**
 * setSysState
 *
 * Set system state
 *
 * 'state'  New system state
 */
const void setSysState(byte *state)
{ 
  switch(state[0])
  {
    case SYSTATE_RESTART:
      // Send info message before restarting the mote
      epSysState.sendPriorSwapInfo(state);
      panstamp.reset();
      break;
    default:
      epSysState.value[0] = state[0];
      break;
  }
}

/**
 * setCarrierFreq
 *
 * Set carrier frequency
 *
 * 'freq'  New carrier frequency
 */
const void setCarrierFreq(byte *freq)
{
  // Send info message before entering the new carrier frequency
  epCarrierFreq.sendPriorSwapInfo(freq);
  // Update endpoint value
  panstamp.cc1101.setCarrierFreq((CARRIER_FREQ)freq[0]);
  // Save in EEPROM
  EEPROM.write(EEPROM_CARRIER_FREQ, epCarrierFreq.value[0]);
}

/**
 * setFreqChannel
 *
 * Set frequency channel
 *
 * 'channel'  New channel
 */
const void setFreqChannel(byte *channel)
{
  // Send info message before entering the new frequency channel
  epFreqChannel.sendPriorSwapInfo(channel);
  // Update endpoint value
  panstamp.cc1101.setChannel(channel[0]);
  // Save in EEPROM
  EEPROM.write(EEPROM_FREQ_CHANNEL, epFreqChannel.value[0]);
}

/**
 * setSecuOption
 *
 * Set security option
 *
 * 'secu'  New security option
 */
const void setSecuOption(byte *secu)
{
  // Send info message before applying the new security option
  epSecuOption.sendPriorSwapInfo(secu);
  // Update endpoint value
  panstamp.security = secu[0] & 0x0F;
  // Save in EEPROM
  EEPROM.write(EEPROM_SECU_OPTION, epSecuOption.value[0]);
}

/**
 * setDevAddress
 *
 * Set device address
 *
 * 'addr'  New device address
 */
const void setDevAddress(byte *addr)
{
  if (addr[0] > 0)
  {
    // Send info before taking the new address
    epDevAddress.sendPriorSwapInfo(addr);
    // Update endpoint value
    panstamp.cc1101.setDevAddress(addr[0]);
    // Save in EEPROM
    EEPROM.write(EEPROM_DEVICE_ADDR, epDevAddress.value[0]);
    // Restart device
    panstamp.reset();
  }
}

/**
 * setNetworkId
 *
 * Set network id
 *
 * 'id'  New network id
 */
const void setNetworkId(byte *id)
{
  // Send info before taking the new network ID
  epNetworkId.sendPriorSwapInfo(id);
  // Update endpoint value
  panstamp.cc1101.setSyncWord(id);
  // Save in EEPROM
  EEPROM.write(EEPROM_NETWORK_ID, epNetworkId.value[0]);
  EEPROM.write(EEPROM_NETWORK_ID + 1, epNetworkId.value[1]);
}

/**
 * updtVoltSupply
 *
 * Measure voltage supply and update endpoint
 *
 * 'eId'  Endpoint ID
 */
const void updtVoltSupply(byte eId)
{
  unsigned short result;
  
  // Read 1.1V reference against AVcc
  ADMUX = _BV(REFS0) | _BV(MUX3) | _BV(MUX2) | _BV(MUX1);
  delay(2); // Wait for Vref to settle
  ADCSRA |= _BV(ADSC); // Convert
  while (bit_is_set(ADCSRA,ADSC));
  result = ADCL;
  result |= ADCH << 8;
  result = 1126400L / result; // Back-calculate AVcc in mV

  /**
   * endpoint[eId]->member can be replaced by epVoltSupply.member in this case since
   * no other endpoint is going to use "updtVoltSupply" as "updater" function
   */

  // Update endpoint value
  epTable[eId]->value[0] = (result >> 8) & 0xFF;
  epTable[eId]->value[1] = result & 0xFF;
}

/**
 * updtTempHum
 *
 * Measure humidity and temperature and update endpoint
 *
 * 'eId'  Endpoint ID
 */
const void updtTempHum(byte eId)
{
  int result;
  
  if ((result = dht11_ReadTempHum()) < 0)
    return;
    
  // Update endpoint value
  epTempHum.value[0] = (result >> 8) & 0xFF;
  epTempHum.value[1] = result & 0xFF;
}
