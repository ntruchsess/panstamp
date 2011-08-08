/**
 * CcPacket.java
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
package ccmodem;

import ccexception.CcException;

/**
 * Class: CcPacket
 * 
 * Description:
 * 
 * CC1101 packet structure
 */
public class CcPacket
{
  /**
   * Data length
   */
  public int length;

  /**
   * Data buffer
   */
  public int[] data;

  /**
   * Received Strength Signal Indication
   */
  public int rssi;

  /**
   * Link Quality Index
   */
  public int lqi;

  /**
   * Modem used for sending packets
   */
  private static CcModem modem = null;

  /**
   * CcPacket
   *
   * Class constructor
   */
  public CcPacket()
  {
  }
  
  /**
   * CcPacket
   *
   * Class constructor
   *
   * 'data'	Raw buffer to be transformed into a CcPacket object
   */
  public CcPacket(String data) throws CcException
  {
    int i;

    if (data.charAt(0) != '(' || data.charAt(5) != ')')
        throw new CcException("CcPacket: incorrect packet format: " + data);

    // RSSI and LQI bytes
    this.rssi = Integer.parseInt(data.substring(1, 3), 16);
    this.lqi = Integer.parseInt(data.substring(3, 5), 16);

    // Data fields:
    this.length = (data.length() - 6)/2;
    String strPacket = data.substring(6);

    this.data = new int[this.length];
    for(i=0 ; i<this.length ; i++)
      this.data[i] = Integer.parseInt(strPacket.substring(i*2, i*2+2), 16);
  }

  /**
   * send
   * 
   * Send current CC1101 packet
   */
  public void send() throws CcException
  {
    if (modem != null)
      modem.sendCcPacket(this);
    else
      throw new CcException("CcPacket: Unable to send packet. Modem not defined");
  }

  /**
   * toString
   *
   * Generate ASCII string
   */
  @Override
  public String toString()
  {
    int i, val;
    StringBuilder strBuf = new StringBuilder("");

    for(i=0 ; i<length ; i++)
    {
      if (data[i] < 0x10)
        strBuf.append('0');

      strBuf.append(Integer.toHexString(data[i]));
    }
 
    return strBuf.toString();
  }

  /**
   * setModem
   *
   * Set common modem for all CcPackets
   */
  public static void setModem(CcModem value)
  {
    modem = value;
  }
}
