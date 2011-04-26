/**
 * SwapDefs.java
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
 * Class: SwapDefs
 * 
 * Description:
 * 
 * Static SWAP definitions
 */
public class SwapDefs
{
  /**
   * Carrier frequencies
   */
  public enum CarrierFreq
  {
    FREQ_868_MHZ,
    FREQ_915_MHZ
  };
  
  /**
   * Broadcast address
   */
  public static final int BCAST_ADDRESS = 0;
  
  /**
   * Default product code
   */
  public static final int[] DEF_PRODUCT_CODE = {0,0,0,1,0,0,0,1};

  /**
   * Default device address
   */
  public static final int DEF_DEV_ADDRESS = 0x01;

  /**
   * Function codes
   */
  /**
   * Basic SWAP endpoint ID's
   */
  public static final int ID_PRODUCT_CODE = 0;
  public static final int ID_HW_VERSION = 1;
  public static final int ID_FW_VERSION = 2;
  public static final int ID_SYSTEM_STATE = 3;
  public static final int ID_CARRIER_FREQ = 4;
  public static final int ID_FREQ_CHANNEL = 5;
  public static final int ID_SECU_OPTION = 6;
  public static final int ID_SECU_NONCE = 7;
  public static final int ID_NETWORK_ID = 8;
  public static final int ID_DEVICE_ADDR = 9;

  /**
   * System states
   */
  public static final int SYSTATE_RESTART = 0;
  public static final int SYSTATE_RUNNING = 1;
}
