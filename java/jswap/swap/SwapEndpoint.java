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
   * Mask to be applied on the associated register
   */
  private long mask  = 0;
  
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
    SwapValue newVal;
    if (mask == 0)
      newVal = val;
    else
    {
      long shift = Long.numberOfTrailingZeros(mask);
      long lVal = (register.getValue().toLong() & ~mask) | ((val.toLong() << shift) & mask);
      newVal = new SwapValue(lVal);
    }
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
    if (mask == 0)
    {
      if (regVal != value)
      {
        value = regVal;
        return true;
      }
    }
    else
    {
      int shift = Long.numberOfTrailingZeros(mask);
      Long lVal = (regVal.toLong() & mask) >> shift;
      if (lVal != value.toLong())
      {
        value = new SwapValue(lVal);
        return true;
      }
    }
    return false;
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

  /**
   * getMask
   * 
   * Return mask
   */
  public final long getMask() 
  {
    return mask;
  }
  
  /**
   * setMask
   * 
   * Set mask
   */
  public void setMask(long value) 
  {
    mask = value;
  }
}
