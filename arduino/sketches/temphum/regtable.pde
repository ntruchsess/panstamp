/**
 * regtable.pde
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
#include "regtable.h"

/**
 * Register setup
 */
// Product code
static byte dtProductCode[8] = {SWAP_MANUFACT_ID >> 24, SWAP_MANUFACT_ID >> 16 , SWAP_MANUFACT_ID >> 8, SWAP_MANUFACT_ID,
                       SWAP_PRODUCT_ID >> 24, SWAP_PRODUCT_ID >> 16 , SWAP_PRODUCT_ID >> 8, SWAP_PRODUCT_ID};
REGISTER regProductCode(dtProductCode, sizeof(dtProductCode), NULL, NULL);
// Hardware version
static byte dtHwVersion[4] = {HARDWARE_VERSION >> 24, HARDWARE_VERSION >> 16 , HARDWARE_VERSION >> 8, HARDWARE_VERSION};
REGISTER regHwVersion(dtHwVersion, sizeof(dtHwVersion), NULL, NULL);
// Firmware version
static byte dtFwVersion[4] = {FIRMWARE_VERSION >> 24, FIRMWARE_VERSION >> 16 , FIRMWARE_VERSION >> 8, FIRMWARE_VERSION};
REGISTER regFwVersion(dtFwVersion, sizeof(dtFwVersion), NULL, NULL);
// System state
static byte dtSysState[1] = {SYSTATE_RUNNING};
REGISTER regSysState(dtSysState, sizeof(dtSysState), NULL, &setSysState);
// Frequency channel
REGISTER regFreqChannel(&panstamp.cc1101.channel, sizeof(panstamp.cc1101.channel), NULL, &setFreqChannel);
// Security option
REGISTER regSecuOption(&panstamp.security, sizeof(panstamp.security), NULL, &setSecuOption);
// Security nonce
REGISTER regSecuNonce(&panstamp.nonce, sizeof(panstamp.nonce), NULL, NULL);
// Network Id
REGISTER regNetworkId(&panstamp.cc1101.syncWord[0], sizeof(panstamp.cc1101.syncWord), NULL, &setNetworkId);
// Device address
REGISTER regDevAddress(&panstamp.cc1101.devAddress, sizeof(panstamp.cc1101.devAddress), NULL, &setDevAddress);
/*
 * Add here your custom registers
 */
// Voltage supply
static byte dtVoltSupply[2];
REGISTER regVoltSupply(dtVoltSupply, sizeof(dtVoltSupply), &updtVoltSupply, NULL);
// Temperature and humidity from the DHT11 sensor
static byte dtTempHum[2];
REGISTER regTempHum(dtTempHum, sizeof(dtTempHum), &updtTempHum, NULL);

/**
 * Initialize table of registers
 */
REGISTER *regTable[] = {
        &regProductCode,
        &regHwVersion,
	&regFwVersion,
        &regSysState,
	&regFreqChannel,
	&regSecuOption,
	&regSecuNonce,
	&regNetworkId,
	&regDevAddress,
  // Add here your custom registers
  	&regVoltSupply,
        &regTempHum
}; 

/**
 * getRegister
 *
 * Return pointer to register with ID = regId
 *
 * 'regId'  Register ID
 */
REGISTER * getRegister(byte regId)
{
  if (regId >= sizeof(regTable))
    return NULL;

  return regTable[regId]; 
}

/**
 * "Update/Set" handling functions
 */
/**
 * setSysState
 *
 * Set system state
 *
 * 'id'     Register ID
 * 'state'  New system state
 */
const void setSysState(byte id, byte *state)
{ 
  switch(state[0])
  {
    case SYSTATE_RESTART:
      // Send info message before restarting the mote
      regSysState.sendPriorSwapInfo(state);
      panstamp.reset();
      break;
    default:
      break;
  }
}

/**
 * setFreqChannel
 *
 * Set frequency channel
 *
 * 'id'       Register ID
 * 'channel'  New channel
 */
const void setFreqChannel(byte id, byte *channel)
{
  // Send info message before entering the new frequency channel
  regFreqChannel.sendPriorSwapInfo(channel);
  // Update register value
  panstamp.cc1101.setChannel(channel[0]);
  // Save in EEPROM
  EEPROM.write(EEPROM_FREQ_CHANNEL, regFreqChannel.value[0]);
}

/**
 * setSecuOption
 *
 * Set security option
 *
 * 'id'    Register ID
 * 'secu'  New security option
 */
const void setSecuOption(byte id, byte *secu)
{
  // Send info message before applying the new security option
  regSecuOption.sendPriorSwapInfo(secu);
  // Update register value
  panstamp.security = secu[0] & 0x0F;
  // Save in EEPROM
  EEPROM.write(EEPROM_SECU_OPTION, regSecuOption.value[0]);
}

/**
 * setDevAddress
 *
 * Set device address
 *
 * 'id'    Register ID
 * 'addr'  New device address
 */
const void setDevAddress(byte id, byte *addr)
{
  if (addr[0] > 0)
  {
    // Send info before taking the new address
    regDevAddress.sendPriorSwapInfo(addr);
    // Update register value
    panstamp.cc1101.setDevAddress(addr[0]);
    // Save in EEPROM
    EEPROM.write(EEPROM_DEVICE_ADDR, regDevAddress.value[0]);
    // Restart device
    panstamp.reset();
  }
}

/**
 * setNetworkId
 *
 * Set network id
 *
 * 'rId' Register ID
 * 'nId'  New network id
 */
const void setNetworkId(byte rId, byte *nId)
{
  // Send info before taking the new network ID
  regNetworkId.sendPriorSwapInfo(nId);
  // Update register value
  panstamp.cc1101.setSyncWord(nId);
  // Save in EEPROM
  EEPROM.write(EEPROM_NETWORK_ID, regNetworkId.value[0]);
  EEPROM.write(EEPROM_NETWORK_ID + 1, regNetworkId.value[1]);
}

/**
 * updtVoltSupply
 *
 * Measure voltage supply and update register
 *
 * 'eId'  Register ID
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
   * register[eId]->member can be replaced by regVoltSupply.member in this case since
   * no other register is going to use "updtVoltSupply" as "updater" function
   */

  // Update register value
  regTable[eId]->value[0] = (result >> 8) & 0xFF;
  regTable[eId]->value[1] = result & 0xFF;
}

/**
 * updtTempHum
 *
 * Measure humidity and temperature and update register
 *
 * 'eId'  Register ID
 */
const void updtTempHum(byte eId)
{
  int result;
  
  if ((result = dht11_ReadTempHum()) < 0)
    return;
    
  // Update register value
  regTempHum.value[0] = (result >> 8) & 0xFF;
  regTempHum.value[1] = result & 0xFF;
}
