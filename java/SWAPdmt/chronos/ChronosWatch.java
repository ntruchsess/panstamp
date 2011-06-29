/**
 * ChronosWatch.java
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
 * Creation date: 06/17/2011
 */

package chronos;

import ccexception.CcException;
import swap.SwapDefs;
import swap.SwapMote;
import swap.SwapValue;
import xmltools.XmlException;

/**
 * ChronosWatch
 *
 * Class representing the TI ez430-Chronos watch with SWAP interface
 */
public class ChronosWatch extends SwapMote
{
  /**
   * Product code
   */
  private static final int[] PRODUCT_CODE = {0,0,0,1,0,0,0,2};

  /**
   * Custom Register ID's
   */
  private static final int ID_CALIBRATION = 9;
  private static final int ID_TXPERIOD = 10;
  private static final int ID_DATETIME = 11;
  private static final int ID_TIMEALARM = 12;
  private static final int ID_TEMPPRESSALTI = 13;
  private static final int ID_ACCELEROMETER = 14;
  private static final int ID_CFGEXTENDPOINT = 15;

  /**
   * Amount of browser pages
   */
  public static final int NUMBER_OF_PAGES = 5;

  /**
   * Class constructor
   *
   * 'address'  Device address
   */
  public ChronosWatch(int address) throws XmlException
  {
    super(PRODUCT_CODE, address);
  }

  /**
   * setDateTime
   *
   * Set Date/Time settings
   *
   * 'settings' Settings SwapValue, ready to be sent to the Chronos
   */
  public void setDateTime(SwapValue settings) throws CcException
  {
    cmdRegister(ID_DATETIME, settings);
  }

  /**
   * setAlarm
   *
   * Set time alarm settings
   *
   * 'settings' Settings SwapValue, ready to be sent to the Chronos
   */
  public void setAlarm(SwapValue settings) throws CcException
  {
    this.cmdRegister(ID_TIMEALARM, settings);
  }

  /**
   * setCalibration
   *
   * Set Temperature/Altitude calibration settings
   *
   * 'settings' Settings SwapValue, ready to be sent to the Chronos
   */
  public void setCalibration(SwapValue settings) throws CcException
  {
    this.cmdRegister(ID_CALIBRATION, settings);
  }

  /**
   * setTxPeriod
   *
   * Settransmission period for temperature, pressure and altitude data
   *
   * 'settings' Settings SwapValue, ready to be sent to the Chronos
   */
  public void setTxPeriod(SwapValue settings) throws CcException
  {
    this.cmdRegister(ID_TXPERIOD, settings);
  }

  /**
   * setPage
   *
   * Set browser page
   *
   * 'page'     Page number, starting from 0
   * 'settings' Settings SwapValue, ready to be sent to the Chronos
   */
  public void setPage(int page, SwapValue settings) throws CcException
  {
    if (page < 0 || page >= NUMBER_OF_PAGES)
      return;  

    this.cmdRegister(ID_CFGEXTENDPOINT + page, settings);
  }

  /**
   * stopSwapComms
   *
   * Stop SWAP communications
   */
  public void stopSwapComms() throws CcException
  {
    this.cmdRegister(SwapDefs.ID_SYSTEM_STATE, new SwapValue(SwapDefs.SYSTATE_STOP, 1));
  }
}
