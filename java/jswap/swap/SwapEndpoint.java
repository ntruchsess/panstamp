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
 * Creation date: 04/01/2011
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
   * Swap register where the endpoint belongs to
   */
  private SwapRegister register;
  
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
   * Position (in bytes) of the endpoint within the parent register
   */
  private byte position = 0;

  /**
   * Size (in bytes) of the endpoint value
   */
  private byte size = 1;

  /**
   * SwapEndpoint
   *
   * Class constructor
   *
   * 'register'	Parent register
   * 'type'	Type of endpoint
   * 'dir'	Direction
   */
  public SwapEndpoint(SwapRegister register, Type type, Direction dir)
  {
    this.register = register;
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
    SwapInfoPacket packet = new SwapInfoPacket(register);
    packet.send();
  }


  /**
   * sendSwapQuery
   *
   * Send SWAP query
   */
  public void sendSwapQuery() throws CcException
  {
    register.getMote().qryRegister(register.getId());
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
    SwapValue currVal, newVal;

    currVal = register.getValue();
    int arrVal[] = new int[size];
    int i, j = 0;
    for(i=0 ; i<currVal.getLength() ; i++)
    {
      if ((i >= position) && (i < (position + size)))
      {
        arrVal[i] = val.toArray()[j];
        j++;
      }
      else
        arrVal[i] = currVal.toArray()[i];
    }

    newVal = new SwapValue(arrVal);
 
    return register.getMote().cmdRegister(register.getId(), newVal);
  }

  /**
   * getAddress
   *
   * REturn device address of the current endpoint
   */
  public int getAddress()
  {
    return register.getMote().getAddress();
  }

  /**
   * getNonce
   *
   * Return security nonce for the device owning the current endpoint
   */
  public int getNonce()
  {
    return register.getMote().getNonce();
  }

  /**
   * getRegisterId
   *
   * Return register ID
   */
  public int getRegisterId()
  {
    return register.getId();
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
   * setRegisterValue
   *
   * Set register value
   *
   * 'regVal'	New register value
   *
   * Return true if the endpoint value changed
   */
  public boolean setRegisterValue(SwapValue regVal)
  {
    register.setValue(regVal);

    int arrVal[] = new int[size];
    int i;
    for(i=0 ; i<size ; i++)
      arrVal[i] = regVal.toArray()[position + i];

    SwapValue swVal = new SwapValue(arrVal);

    if (value.isEqual(swVal))
      return false;

    value = swVal;
    return true;
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
   * getPosition
   *
   * Return position of the endpoint (in bytes) within the register
   */
  public final byte getPosition()
  {
    return position;
  }

  /**
   * setPosition
   *
   * Set position of the endpoint
   */
  public void setPosition(byte value)
  {
    position = value;
  }

  /**
   * getSize
   *
   * Return size of the endpoint value
   */
  public final byte getSize()
  {
    return size;
  }

  /**
   * setSize
   *
   * Set size of the endpoint value
   */
  public void setSize(byte value)
  {
    size = value;
  }
}
