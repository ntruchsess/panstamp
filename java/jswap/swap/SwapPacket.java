/**
 * SwapPacket.java
 * 
 * Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
 *  
 * This file is part of the panStamp project.
 *  
 * panStamp  is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
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

import ccmodem.CcPacket;
import ccexception.CcException;

/**
 * Class: SwapPacket
 * 
 * Description:
 * 
 * Standard SWAP packet class
 */
public class SwapPacket extends CcPacket
{
  /**
   * SWAP function codes
   */
  public static final int FINFO = 0x00;
  public static final int FQUERY = 0x01;
  public static final int FCOMMAND = 0x02;

  /**
   * Broadcast address
   */
  public static int BROADCAST_ADDR = 0x00;

  /**
   * Destination address
   */
  public int destAddress;

  /**
   * Source address
   */
  public int srcAddress;

  /**
   * Hop counter for repeating purposes
   */
  public int hop;

  /**
   * Security option
   */
  public int security;

  /**
   * Security nonce
   */
  public int nonce;

  /**
   * SWAP function byte
   */
  public int function;

  /**
   * Register address
   */
  public int regAddress;

  /**
   * Register identifier
   */
  public int regId;

  /**
   * Register value
   */
  public SwapValue value;

  /**
   * SwapPacket
   * 
   * Class constructor
   * 
   * 'packet'	Raw CC11xx packet
   */
  public SwapPacket(CcPacket packet) throws CcException
  {
    super();
    
    // Superclass members
    length = packet.length;
    data = packet.data;
    rssi = packet.rssi;
    lqi = packet.lqi;

    // Class members
    destAddress = packet.data[0];
    srcAddress = packet.data[1];
    hop = (packet.data[2] >> 4) & 0x0F;
    security = packet.data[2] & 0x0F;
    nonce = packet.data[3];
    function = packet.data[4];
    regAddress = packet.data[5];
    regId = packet.data[6];
    
    int i;
    int[] val = new int[packet.data.length-7];
    for(i=0 ; i<val.length ; i++)
      val[i] = packet.data[i+7];
    value = new SwapValue(val);
  }

  /**
   * SwapPacket
   * 
   * Class constructor
   */
  public SwapPacket(int destAddr, int hop, int nonce, int function, int regAddr, int regId, SwapValue val)
  {
    int i;
    // Class members
    this.destAddress = destAddr;
    this.srcAddress = SwapMote.getGateway().getAddress();
    this.hop = hop;
    this.security = SwapMote.getGateway().getSecurity();
    this.nonce = nonce;
    this.function = function;
    this.regAddress = regAddr;
    this.regId = regId;
    this.value = val;

    // Superclass members
    if (val == null)
      length = 7;
    else
      length = this.value.getLength() + 7;

    data = new int[length];
    data[0] = this.destAddress;
    data[1] = this.srcAddress;
    data[2] = (this.hop << 4) & 0xF0;
    data[2] |= this.security & 0x0F;
    data[3] = this.nonce;
    data[4] = this.function;
    data[5] = this.regAddress;
    data[6] = this.regId;

    if (val != null)
    {
      for(i=0 ; i<this.value.getLength() ; i++)
        data[i+7] = this.value.toArray()[i];
    }
  }

  /**
   * SwapPacket
   *
   * Class constructor
   */
  public SwapPacket()
  {
  }
}
