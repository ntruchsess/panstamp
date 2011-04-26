/**
 * SwapMote.java
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
 * Creation date: 04/01/2011
 */
package swap;

import device.Settings;
import xmltools.XmlDevice;
import ccexception.CcException;
import xmltools.XmlException;

import java.io.File;

/**
 * Class: SwapMote
 * 
 * Description:
 * 
 * Basic SWAP mote class
 */
public class SwapMote
{
  /**
   * Manufacturer id
   */
  private long manufactId = 0;

  /**
   * Product identifier
   */
  private long productId = 0;

  /**
   * Device address
   */
  private int address;

  /**
   * Cyclic nonce
   */
  private int nonce = 0;

  /**
   * Mote definition
   */
  private XmlDevice definition;

  /**
   * Pending packet to be sent to the mote
   */
  private SwapPacket pendingPacket = null;

  /**
   * SwapMote
   * 
   * Class constructor
   * 
   * 'productCode'	Product code (Manufact ID + Product ID)
   * 'address'	Device address
   */
  public SwapMote(int[] productCode, int address) throws XmlException
  {
    int i;
    for(i=0 ; i<4 ; i++)
      manufactId |= productCode[i] << 8*(3-i);
    for(i=0 ; i<4 ; i++)
      productId |= productCode[i+4] << 8*(3-i);

    this.address = address;
    this.definition = new XmlDevice(Settings.getDeviceDir() + File.separator + Long.toHexString(manufactId) + File.separator + Long.toHexString(productId) + ".xml");
  }

  /**
   * getPwrDownMode
   * 
   * Return power-down flag
   */
  public boolean getPwrDownMode()
  {
    return definition.getPwrDownMode();
  }

  /**
   * getManufacturer
   * 
   * Return manufacturer string
   */
  public String getManufacturer() 
  {
    return definition.getManufacturer();
  }

  /**
   * getProduct
   * 
   * Return product string
   */
  public String getProduct() 
  {
    return definition.getProduct();
  }

  /**
   * getManufactId
   *
   * Get manufacturer id
   */
  public final long getManufactId()
  {
    return manufactId;
  }

  /**
   * getProductId
   *
   * Get product id
   */
  public final long getProductId()
  {
    return productId;
  }

  /**
   * getAddress
   *
   * Get device address
   */
  public final int getAddress()
  {
    return address;
  }

  /**
   * setAddress
   *
   * Set device address
   *
   * 'value'	Device address
   */
  public void setAddress(int value)
  {
    address = value;
  }

  /**
   * cmdAddress
   *
   * Send command to mote in order to change its address
   *
   * 'address'	New device address
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket cmdAddress(int address) throws CcException
  {
    SwapValue val = new SwapValue(address, 1);
    return cmdRegister(SwapDefs.ID_DEVICE_ADDR, val);
  }

  /**
   * getNonce
   *
   * Get current cyclic nonce
   */
  public final int getNonce()
  {
    return nonce;
  }

  /**
   * setNonce
   *
   * Set cyclic nonce value
   */
  public void setNonce(int value)
  {
    nonce = value;
  }
  
  /**
   * incrementNonce
   *
   * Increment cyclic nmonce by one
   */
  public void incrementNonce()
  {
    nonce++;
  }

  /**
   * cmdCarrierFreq
   *
   * Send command to mote in order to change its carrier frequency
   *
   * 'carFreq'	New carrier frequency
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket cmdCarrierFreq(int carFreq) throws CcException
  {
    SwapValue val = new SwapValue(carFreq, 1);
    return cmdRegister(SwapDefs.ID_CARRIER_FREQ, val);
  }

  /**
   * cmdFreqChannel
   *
   * Send command to mote in order to change its frequency channel
   *
   * 'freqChannel'	New carrier frequency
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket cmdFreqChannel(int freqChannel) throws CcException
  {
    SwapValue val = new SwapValue(freqChannel, 1);
    return cmdRegister(SwapDefs.ID_FREQ_CHANNEL, val);
  }

  /**
   * cmdNetworkId
   *
   * Send command to mote in order to change its network id
   *
   * 'netId'	New carrier frequency
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket cmdNetworkId(int netId) throws CcException
  {
    SwapValue val = new SwapValue(netId, 2);
    return cmdRegister(SwapDefs.ID_NETWORK_ID, val);
  }

  /**
   * cmdSecurity
   *
   * Send command to mote in order to change its security option
   *
   * 'secu'	New carrier frequency
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket cmdSecurity(int secu) throws CcException
  {
    SwapValue val = new SwapValue(secu, 1);
    return cmdRegister(SwapDefs.ID_SECU_OPTION, val);
  }

  /**
   * cmdRestart
   *
   * Restart wireless mote
   */
  public SwapInfoPacket cmdRestart() throws CcException
  {
    SwapValue val = new SwapValue(SwapDefs.SYSTATE_RESTART, 1);
    return cmdRegister(SwapDefs.ID_SYSTEM_STATE, val);
  }
  
  /**
   * cmdRegister
   *
   * Send command to register
   *
   * 'id'   Register ID
   * 'val'	New endpoint value
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket cmdRegister(int id, SwapValue val) throws CcException
  {
    SwapInfoPacket infPacket = new SwapInfoPacket(this.getAddress(), id, val);
    SwapCommandPacket cmdPacket = new SwapCommandPacket(this.nonce, this.getAddress(), id, val);

    // The mote may be sleeping at this moment
    if (this.getPwrDownMode())
      pendingPacket = cmdPacket; // Place the message for later transmission
    else
      cmdPacket.send();

    return infPacket;
  }

  /**
   * qryRegister
   *
   * Send query to register
   *
   * 'id'	Register ID
   */
  public void qryRegister(int id) throws CcException
  {
    SwapQueryPacket qryPacket = new SwapQueryPacket(this.getAddress(), id);

    // The mote may be sleeping at this moment
    if (this.getPwrDownMode())
      pendingPacket = qryPacket; // Place the message for later transmission
    else
      qryPacket.send();
  }
  
  /**
   * sendPending
   *
   * Send pending SWAP message to mote
   */
  public void sendPending() throws CcException
  {
    if (pendingPacket != null)
    {
      pendingPacket.send();
      pendingPacket = null;
    }
  }
}
