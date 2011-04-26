/**
 * SwapRegister.java
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

import ccexception.CcException;

/**
 * Class: SwapRegister
 * 
 * Description:
 * 
 * SWAP register class
 */
public class SwapRegister
{
  /**
   * Mote owner of the register
   */
  private SwapMote mote;

  /**
   * Register value
   */
  private SwapValue value;

  /**
   * Register ID
   */
  private int id;

  /**
   * SwapRegister
   * 
   * Class constructor
   * 
   * 'mote'	Parent mote
   * 'id'	Register ID
   */
  public SwapRegister(SwapMote mote, int id) 
  {
    this.mote = mote;
    this.id = id;
  }

  /**
   * getValue
   * 
   * REturn register value
   */
  public final SwapValue getValue() 
  {
    return value;
  }

  /**
   * setValue
   * 
   * Set register value
   */
  public void setValue(SwapValue new_value) 
  {
    value = new_value;
  }

  /**
   * getMote
   *
   * Return parent mote
   */
  public final SwapMote getMote()
  {
    return mote;
  }

  /**
   * getAddress
   *
   * Return mote address
   */
  public int getAddress()
  {
    return mote.getAddress();
  }

  /**
   * getId
   *
   * Return register ID
   */
  public final int getId()
  {
    return id;
  }

  /**
   * sendSwaoCmd
   *
   * Send SWAP command
   *
   * 'val'	New register value
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket sendSwaoCmd(SwapValue val) throws CcException
  {
    return mote.cmdRegister(id, val);
  }

  /**
   * sendSwaoQuery
   *
   * Send SWAP query
   */
  public void sendSwaoQuery() throws CcException
  {
    mote.qryRegister(id);
  }

  /**
   * sendSwapInfo
   *
   * Send SWAP information message
   */
  public void sendSwapInfo() throws CcException
  {
  }
}
