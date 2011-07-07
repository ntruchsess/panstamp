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
import device.SwapGateway;
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
   * Serial gateway
   */
  private static SwapGateway gateway;

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
   * System state
   */
  private int state = SwapDefs.SYSTATE_RUNNING;

  /**
   * Mote definition
   */
  private XmlDevice definition;

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
    // Read general settings from XML file
    Settings.read();
    
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
   * sendFreqChannelWack
   *
   * Send frequency channel value and wait for response from the mote
   *
   * 'freqChannel'	New frequency channel
   *
   * Return true if the mote confirmed (ACK'ed) the new frequency channel
   */
  public boolean sendFreqChannelWack(int freqChannel) throws ccexception.CcException
  {
    SwapValue val = new SwapValue(freqChannel, 1);
    return gateway.setMoteRegister(this, SwapDefs.ID_FREQ_CHANNEL, val);
  }

  /**
   * sendNetworkIdWack
   *
   * Send network id value and wait for response from the mote
   *
   * 'netId'	New network id
   *
   * Return true if the mote confirmed (ACK'ed) the new network id
   */
  public boolean sendNetworkIdWack(int netId) throws CcException
  {
    SwapValue val = new SwapValue(netId, 2);
    return gateway.setMoteRegister(this, SwapDefs.ID_NETWORK_ID, val);
  }

  /**
   * sendSecurityWack
   *
   * Send security option value and wait for response from the mote
   *
   * 'secu'	Security option
   *
   * Return true if the mote confirmed (ACK'ed) the new security option
   */
  public boolean sendSecurityWack(int secu) throws CcException
  {
    SwapValue val = new SwapValue(secu, 1);
    return gateway.setMoteRegister(this, SwapDefs.ID_SECU_OPTION, val);
  }

  /**
   * sendAddressWack
   *
   * Send address value and wait for response from the mote
   *
   * 'addr'	New device address
   *
   * Return true if the mote confirmed (ACK'ed) the new device address
   */
  public boolean sendAddressWack(int addr) throws CcException
  {
    SwapValue val = new SwapValue(addr, 1);
    return gateway.setMoteRegister(this, SwapDefs.ID_DEVICE_ADDR, val);
  }

  /**
   * restart
   *
   * Restart wireless mote
   *
   * Return true if the mote confirmed (ACK'ed) the command
   */
  public boolean restart() throws CcException
  {
    SwapValue val = new SwapValue(SwapDefs.SYSTATE_RESTART, 1);
    return gateway.setMoteRegister(this, SwapDefs.ID_SYSTEM_STATE, val);
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
    qryPacket.send();
  }
  
  /**
   * getState
   *
   * Return system state
   */
  public final int getState()
  {
    return state;
  }

  /**
   * setState
   *
   * Set new system state
   */
  public void setState(int value)
  {
    state = value;
  }

  /**
   * getGateway
   *
   * Return serial gateway
   */
  public final static SwapGateway getGateway()
  {
    return gateway;
  }

  /**
   * setGateway
   *
   * Set serial gateway attribute
   */
  public static void setGateway(SwapGateway value)
  {
    gateway = value;
  }
}
