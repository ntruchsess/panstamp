/**
 * SwapInfoPacket.java
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

/**
 * Class: SwapInfoPacket
 * 
 * Description:
 * 
 * SWAP information packet
 */
public class SwapInfoPacket extends SwapPacket
{
  /**
   * SwapInfoPacket
   *
   * Class constructor
   *
   * 'register'	SWAP register to inform about
   */
  public SwapInfoPacket(SwapRegister register)
  {
    super(BROADCAST_ADDR, 0, SwapMote.getGateway().getNonce(), SwapPacket.FINFO,
            register.getAddress(), register.getId(), register.getValue());

    SwapMote.getGateway().incrementNonce();
  }

  /**
   * SwapInfoPacket
   *
   * Class constructor
   *
   * 'epAddr'	Endpoint address
   * 'epId'	Endpoint id
   * 'val'	New endpoint value
   */
  public SwapInfoPacket(int epAddr, int epId, SwapValue val)
  {
    super(BROADCAST_ADDR, 0, 0, SwapPacket.FINFO, epAddr, epId, val);
  }
}
