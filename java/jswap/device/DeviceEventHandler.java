/**
 * DeviceEventHandler.java
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
 * Creation date: #cdate#
 */
package device;

import swap.SwapEndpoint;
import swap.SwapMote;

/**
 * Class: DeviceEventHandler
 * 
 * Description:
 * 
 * Device event handler interface
 */
public interface DeviceEventHandler
{
  /**
   * newMoteDetected
   * 
   * New mote detected in the wireless network
   * 
   * 'mote'	New wireless mote
   */
  public void newMoteDetected(SwapMote mote);

  /**
   * moteAddressChanged
   *
   * Address changed on the mote passed as argument
   *
   * 'mote'	Wireless mote
   */
  public void moteAddressChanged(SwapMote mote);
  
  /**
   * newEndpointDetected
   * 
   * New endpoint detected in the wireless network
   * 
   * 'endpoint'	New endpoint
   */
  public void newEndpointDetected(SwapEndpoint endpoint);

  /**
   * endpointValueChanged
   *
   * Reports endpoint value event
   *
   * 'endpoint'	Endpoint having changed its value
   */
  public void endpointValueChanged(SwapEndpoint endpoint);
}
