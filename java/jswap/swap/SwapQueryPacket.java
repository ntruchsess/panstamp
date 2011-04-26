/**
 * SwapQueryPacket.java
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
 * Class: SwapQueryPacket
 * 
 * Description:
 * 
 * SWAP query packet
 */
public class SwapQueryPacket extends SwapPacket
{
  /**
   * SwapQueryPacket
   *
   * Class constructor
   *
   * 'endpoint'	SWAP endpoint to be queried
   */
  /*
  public SwapQueryPacket(SwapEndpoint endpoint)
  {
    this.destAddress = endpoint.mote.getAddress();
    this.srcAddress = SwapEndpoint.device.getAddress();
    this.hop = 0;
    this.security = SwapEndpoint.device.getSecurity();
    this.nonce = 0;
    this.function = SwapPacket.FQUERY;
    this.regAddress = endpoint.mote.getAddress();
    this.regId = endpoint.regId;
  }
  */
  /**
   * SwapQueryPacket
   *
   * Class constructor
   */
  public SwapQueryPacket(int epAddr, int epId)
  {
    super(epAddr, 0, 0, SwapPacket.FQUERY, epAddr, epId, null);
  }
}
