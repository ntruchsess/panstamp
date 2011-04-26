/**
 * CcModem.java
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
package ccmodem;

import serial.Gateway;
import serial.TtyPort;
import ccexception.CcException;

/**
 * Class: Modem
 * 
 * Description:
 * 
 * Serial modem class
 */
public class CcModem implements Gateway
{
  /**
   * SerialMode
   *
   * Serial working mode
   */
  private enum SerialMode
  {
    DATA,
    COMMAND
  };

  /**
   * Serial port
   */
  private TtyPort commPort;

  /**
   * CC11XX packet handler parent
   */
  private CcPacketHandler packetHandler;

  /**
   * Serial mode
   */
  private SerialMode serMode = SerialMode. DATA;

  /**
   * Response to the last AT command sent to the serial modem
   */
  private String atResponse = "";

  /**
   * Reception flag
   */
  private boolean atResponseReceived = false;

  /**
   * CcModem
   *
   * Class constructor
   *
   * 'parent'	Parent
   * 'port'	Path to the serial port
   * 'speed'	Serial baud rate
   */
  public CcModem(CcPacketHandler parent, String port, int speed) throws CcException
  {
    packetHandler = parent;
    commPort = new TtyPort(this, port, speed);
    commPort.connect();
    CcPacket.setModem(this);
  }

  /**
   * close
   *
   * Close modem connection
   */
  public void close() throws CcException
  {
    commPort.close();
  }

  /**
   * serialDataReceived
   *
   * Serial data received
   *
   * 'data'	Data received
   */
  public void serialDataReceived(String data)
  {
    System.out.println("Received = " + data);
    if (serMode == SerialMode.DATA)
    {
      try
      {
        CcPacket packet = new CcPacket(data);
        packetHandler.ccPacketReceived(packet);
      }
      catch(CcException ex)
      {
        //ex.print();
      }
    }
    else // SerialMode.COMMAND
    {
      atResponse = data;
      atResponseReceived = true;
    }
  }

  /**
   * runAtCommand
   * 
   * Run AT command on the modem
   * 
   * 'cmd'	At command to be run
   * 
   * Return:
   * 	Response received from the serial modem
   */
  private String runAtCommand(String cmd) throws CcException
  {
    atResponseReceived = false;
    System.out.println("command: " + cmd);
    commPort.send(cmd);

    if (!waitForResponse(2000))
      return "-1";
    return atResponse;
  }

  /**
   * sendCcPacket
   * 
   * Send wireless packet
   * 
   * 'packet'	CC1101 packet to be sent
   */
  public void sendCcPacket(CcPacket packet) throws CcException
  { 
    commPort.send(packet.toString() + "\r");
  }

  /**
   * reset
   * 
   * Run software reset on the modem
   * 
   * Return:
   * 	1 if the modem returns "OK"
   * 	0 otherwise
   */
  public boolean reset() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    
    if (runAtCommand("ATZ\r").startsWith("OK"))
      return true;
    return false;
  }

  /**
   * goToCommandMode
   * 
   * Enter command mode
   * 
   * Return:
   * 	1 if the modem returns "OK"
   * 	0 otherwise
   */
  public boolean goToCommandMode() throws CcException
  {
    serMode = SerialMode.COMMAND;
    if (runAtCommand("+++").startsWith("OK"))
      return true;

    return false;
  }

  /**
   * goToDataMode
   * 
   * Enter data mode
   * 
   * Return:
   * 	1 if the modem returns "OK"
   * 	0 otherwise
   */
  public boolean goToDataMode() throws CcException
  {
    if (runAtCommand("ATO\r").startsWith("OK"))
    {
      serMode = SerialMode.DATA;
      return true;
    }
    return false;
  }

  /**
   * getHwVersion
   * 
   * Get hardware version of the modem
   * 
   * Return:
   * 	Hardware version
   */
  public long getHwVersion() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    return Long.parseLong(runAtCommand("ATHV?\r"), 16);
  }

  /**
   * getFwVersion
   * 
   * Get firmware version of the modem
   * 
   * Return:
   * 	Firmware version
   */
  public long getFwVersion() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    return Long.parseLong(runAtCommand("ATFV?\r"));
  }

  /**
   * getCarrierFreq
   *
   * Get carrier frequency from modem
   */
  public int getCarrierFreq() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    return Integer.parseInt(runAtCommand("ATCF?\r"), 16);
  }

  /**
   * setCarrierFreq
   * 
   * Set carrier frequency
   * 
   * 'freq'	New carrier frequency
   * 
   * Return:
   * 	1 if the modem returns "OK"
   * 	0 otherwise
   */
  public boolean setCarrierFreq(int freq) throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    StringBuilder strBuf = new StringBuilder("");

    if (freq > 0x0F)
      return false;

    strBuf.append("0");
    strBuf.append(Integer.toHexString(freq));

    if (runAtCommand("ATCF=" + strBuf.toString() + "\r").startsWith("OK"))
      return true;
    return false;
  }

  /**
   * getFreqChannel
   *
   * Get frequency channel from modem
   */
  public int getFreqChannel() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    return Integer.parseInt(runAtCommand("ATCH?\r"), 16);
  }

  /**
   * setFreqChannel
   * 
   * Set frequency channel
   * 
   * 'channel'	New frequency channel
   * 
   * Return:
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setFreqChannel(int channel) throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    StringBuilder strBuf = new StringBuilder("");

    if (channel > 0x0F)
      return false;

    strBuf.append("0");
    strBuf.append(Integer.toHexString(channel));

    return runAtCommand("ATCH=" + strBuf.toString() + "\r").startsWith("OK");
  }

    /**
   * getSyncWord
   *
   * Get sync word from modem
   */
  public int getSyncWord() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    return Integer.parseInt(runAtCommand("ATSW?\r"), 16);
  }

  /**
   * setSyncWord
   * 
   * Set RF synchronization word
   * 
   * 'sync'	New sync word
   * 
   * Return:
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setSyncWord(int sync) throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    StringBuilder strBuf = new StringBuilder("");

    if (sync > 0xFFFF)
      return false;

    if (sync < 0x1000)
      strBuf.append("0");

    strBuf.append(Integer.toHexString(sync));

    if (runAtCommand("ATSW=" + strBuf.toString() + "\r").startsWith("OK"))
      return true;
    return false;
  }

  /**
   * getDeviceAddr
   *
   * Get device address from modem
   */
  public int getDeviceAddr() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    return Integer.parseInt(runAtCommand("ATDA?\r"), 16);
  }

  /**
   * setDeviceAddr
   * 
   * Set device address
   * 
   * 'addr'	New device address
   * 
   * Return:
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setDeviceAddr(int addr) throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    StringBuilder strBuf = new StringBuilder("");

    if (addr > 0xFF)
      return false;

    if (addr < 0x10)
      strBuf.append("0");

    strBuf.append(Integer.toHexString(addr));

    if (runAtCommand("ATDA=" + strBuf.toString() + "\r").startsWith("OK"))
      return true;
    return false;
  }

  /**
   * getDataRate
   *
   * Get data rate from modem
   */
  public int getDataRate() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();
    return Integer.parseInt(runAtCommand("ATDR?\r"), 16);
  }

  /**
   * setDataRate
   * 
   * Set wireless data rate
   * 
   * 'drate'	New data rate
   * 
   * Return:
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setDataRate(int drate) throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    StringBuilder strBuf = new StringBuilder("");

    strBuf.append("0");
    strBuf.append(Integer.toHexString(drate));

    if (runAtCommand("ATDR=" + strBuf.toString() + "\r").startsWith("OK"))
      return true;
    return false;
  }

  /**
   * getModulation
   *
   * Get modulation type from modem
   */
  public int getModulation() throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    return Integer.parseInt(runAtCommand("ATMT?\r"), 16);
  }

  /**
   * setModulation
   * 
   * Set modulation type
   * 
   * 'type'	New data rate
   * 
   * Return:
   * 	1 if the command succeeds
   * 	0 otherwise
   */
  public boolean setModulation(int type) throws CcException
  {
    if (serMode == SerialMode.DATA)
      goToCommandMode();

    StringBuilder strBuf = new StringBuilder("");

    if (type > 0x0F)
      return false;

    strBuf.append("0");
    strBuf.append(Integer.toHexString(type));

    if (runAtCommand("ATMT=" + strBuf.toString() + "\r").startsWith("OK"))
      return true;
    return false;
  }

  /**
   * waitForResponse
   * 
   * Wait until a response is received from the serial modem
   *
   * 'time' Maximum waiting time in milliseconds. Must be multiple of 10 ms
   *
   * Return:
   *    True if the function does not time out
   *    False otherwise
   */
  private boolean waitForResponse(long time)
  {
    long wait = time / 10;

    while(!atResponseReceived)
    {
      try {Thread.sleep(10);} catch (InterruptedException ex){}
      if ((--wait) == 0)
        return false;
    }
    return true;
  }
}
