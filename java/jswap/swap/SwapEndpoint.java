/**
 * SwapEndpoint.java
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
 * Creation date: #cdate#
 */
package swap;

import device.SwapGateway;
import ccexception.CcException;

/**
 * Class: SwapEndpoint
 * 
 * Description:
 * 
 * SWAP endpoint
 */
public class SwapEndpoint
{
  /**
   * Parent device
   */
  public static SwapGateway device;

  /**
   * Wireless node
   */
  private SwapMote mote;

  /**
   * Endpoint identifier
   */
  private int epID;

  /**
   * Endpoint value
   */
  private SwapValue value;

  /**
   * Type of endpoint
   */
  public enum Type
  {
    BINARY,
    ANALOG,
    VIRTUAL
  };
  private Type type;

  /**
   * Direction of the endpoint
   */
  public enum Direction
  {
    INPUT,
    OUTPUT
  };
  private Direction direction;

  /**
   * Factor operator
   */
  private float factor = 1;

  /**
   * Offset operator
   */
  private float offset = 0;

  /**
   * SwapEndpoint
   *
   * Class constructor
   *
   * 'node'	Wireless mote
   * 'id'	Endpoint id
   * 'type'	Type of endpoint
   * 'dir'	Direction
   */
  public SwapEndpoint(SwapMote mote, int id, Type type, Direction dir)
  {
    this.mote = mote;
    this.epID = id;
    this.type = type;
    this.direction = dir;
  }

  /**
   * sendSwapInfo
   *
   * Send SWAP information message
   */
  public void sendSwapInfo() throws CcException
  {
    SwapInfoPacket packet = new SwapInfoPacket(this);
    packet.send();
  }


  /**
   * sendSwapQuery
   *
   * Send SWAP query
   */
  public void sendSwapQuery() throws CcException
  {
    mote.qryEndpoint(this.epID);
  }

  /**
   * sendSwapCmd
   *
   * Send SWAP command
   *
   * 'val'	New endpoint value
   *
   * Return expected response to be received from the targeted endpoint
   */
  public SwapInfoPacket sendSwapCmd(SwapValue val) throws CcException
  {
    return mote.cmdEndpoint(epID, val);
  }

  /**
   * getAddress
   *
   * REturn device address of the current endpoint
   */
  public int getAddress()
  {
    return mote.getAddress();
  }

  /**
   * getNonce
   *
   * Return security nonce for the device owning the current endpoint
   */
  public int getNonce()
  {
    return mote.getNonce();
  }

  /**
   * getEpID
   *
   * Return endpoint ID
   */
  public final int getEpID()
  {
    return epID;
  }

  /**
   * getValue
   *
   * Return endpoint value
   */
  public final SwapValue getValue()
  {
    return value;
  }

  /**
   * setValue
   *
   * Set endpoint value
   */
  public void setValue(SwapValue val)
  {
    value = val;
  }

  /**
   * getType
   *
   * Return endpoint type
   */
  public final Type getType()
  {
    return type;
  }

  /**
   * getDirection
   *
   * Return direction of the endpoint
   */
  public final Direction getDirection()
  {
    return direction;
  }

  /**
   * getFactor
   *
   * Return factor operator
   */
  public final float getFactor()
  {
    return factor;
  }

  /**
   * setFactor
   *
   * Set factor operator
   */
  public void setFactor(float value)
  {
    factor = value;
  }

  /**
   * getOffset
   *
   * Return offset operator
   */
  public final float getOffset()
  {
    return offset;
  }

  /**
   * setOffset
   *
   * Set offset operator
   */
  public void setOffset(float value)
  {
    offset = value;
  }
}
