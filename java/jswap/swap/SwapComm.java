/**
 * SwapServer.java
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

import ccmodem.CcPacketHandler;
import ccmodem.CcModem;
import ccmodem.CcPacket;
import ccexception.CcException;

/**
 * Class: SwapServer
 * 
 * Description:
 * 
 * Swap server
 */
public class SwapComm implements CcPacketHandler
{
  /**
   * Wireless interface
   */
  private CcModem modem;

  /**
   * SWAP packet handler
   */
  private SwapPacketHandler packetHandler;

  /**
   * Data rate
   */
  private final static int dataRate = 0;

  /**
   * Modulation type
   */
  private final static int modulation = 0;

  /**
   * SwapComm
   *
   * Class constructor
   *
   * 'parent'	SWAP packet handler parent
   * 'port'	Serial port name
   * 'speed'	Serial baud rate
   */
  public SwapComm(SwapPacketHandler parent, String port, int speed) throws CcException
  {
    packetHandler = parent;
    modem = new CcModem(this, port, speed);
  }

  /**
   * connect
   *
   * Start SWAP comms
   */
  public void connect() throws CcException
  {
    modem.goToDataMode();
  }

  /**
   * ccPacketReceived
   * 
   * CC1101 packet received
   */
  public void ccPacketReceived(CcPacket packet)
  {
    try
    {
      SwapPacket swPacket = new SwapPacket(packet);
      packetHandler.swapPacketReceived(swPacket);
    }
    catch (CcException ex)
    {
      ex.print();
    }
  }

  /**
   * getCarrierFreq
   *
   * Get carrier frequency
   */
  public int getCarrierFreq() throws CcException
  {
    return modem.getCarrierFreq();
  }

  /**
   * setCarrierFreq
   *
   * Set carrier frequency
   *
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setCarrierFreq(int val) throws CcException
  {
    return modem.setCarrierFreq(val);
  }

  /**
   * getFreqChannel
   *
   * Get frequency channel
   */
  public int getFreqChannel() throws CcException
  {
    return modem.getFreqChannel();
  }

  /**
   * setFreqChannel
   *
   * Set frequency channel
   *
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setFreqChannel(int val) throws CcException
  {
    return modem.setFreqChannel(val);
  }

  /**
   * getNetworkId
   *
   * Get network id
   */
  public int getNetworkId() throws CcException
  {
    return modem.getSyncWord();
  }

  /**
   * setNetworkId
   *
   * Set network id
   *
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setNetworkId(int val) throws CcException
  {
    return modem.setSyncWord(val);
  }

  /**
   * getAddress
   *
   * Return device address
   */
  public int getAddress() throws CcException
  {
    return modem.getDeviceAddr();
  }

  /**
   * setAddress
   *
   * Set device address
   */
  public boolean setAddress(int val) throws CcException
  {
    return modem.setDeviceAddr(val);
  }
}
