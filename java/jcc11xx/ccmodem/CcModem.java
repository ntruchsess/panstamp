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

import java.util.logging.Level;
import java.util.logging.Logger;
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
   * Hardware version of the serial modem
   */
  private long hwVersion;

  /**
   * Firmware version
   */
  private long fwVersion;

  /**
   * Carrier frequency
   */
  private int carrierFreq;

  /**
   * Frequency channel
   */
  private int freqChannel;

  /**
   * Synchronization word
   */
  private int syncWord;

  /**
   * Device address
   */
  private int deviceAddr;

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
    CcPacket.setModem(this);
  }


  /**
   * connect
   *
   * Connect serial modem
   */
  public void connect() throws CcException
  {
    commPort.connect();

    try {
      Thread.sleep(3000);
    } catch (InterruptedException ex) {
      Logger.getLogger(CcModem.class.getName()).log(Level.SEVERE, null, ex);
    }

    if (serMode == SerialMode.DATA)
      goToCommandMode();

    String response;

    // Retrieve modem settings
    // Hardware version
    if ((response = runAtCommand("ATHV?\r")) == null)
      throw new CcException("Unable to retrieve Hardware Version from serial modem");
    hwVersion = Long.parseLong(response, 16);

    // Firmware version
    if ((response = runAtCommand("ATFV?\r")) == null)
      throw new CcException("Unable to retrieve Firmware Version from serial modem");
    fwVersion = Long.parseLong(response, 16);

    // Carrier frequency
    if ((response = runAtCommand("ATCF?\r")) == null)
      throw new CcException("Unable to retrieve Carrier Frequency from serial modem");
    carrierFreq = Integer.parseInt(response, 16);

    // Frequency channel
    if ((response = runAtCommand("ATCH?\r")) == null)
      throw new CcException("Unable to retrieve Frequency Channel from serial modem");
    freqChannel = Integer.parseInt(response, 16);

    // Synchronization word
    if ((response = runAtCommand("ATSW?\r")) == null)
      throw new CcException("Unable to retrieve Synchronization Word from serial modem");
    syncWord = Integer.parseInt(response, 16);

    // Device address
    if ((response = runAtCommand("ATDA?\r")) == null)
      throw new CcException("Unable to retrieve Device Address from serial modem");
    deviceAddr = Integer.parseInt(response, 16);
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
    commPort.send(cmd);

    atResponse = "(";
    while (atResponse.startsWith("("))
    {
      if (!waitForResponse(2000))
        return null;
    }

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
    if (serMode == SerialMode.COMMAND)
      goToDataMode();
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
  public long getHwVersion()
  {
    return hwVersion;
  }

  /**
   * getFwVersion
   * 
   * Get firmware version of the modem
   * 
   * Return:
   * 	Firmware version
   */
  public long getFwVersion()
  {
    return fwVersion;
  }

  /**
   * getCarrierFreq
   *
   * Get carrier frequency from modem
   */
  public int getCarrierFreq()
  {
    return carrierFreq;
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
    {
      carrierFreq = freq;
      return true;
    }
    return false;
  }

  /**
   * getFreqChannel
   *
   * Get frequency channel from modem
   */
  public int getFreqChannel()
  {
    return freqChannel;
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

    if (runAtCommand("ATCH=" + strBuf.toString() + "\r").startsWith("OK"))
    {
      freqChannel = channel;
      return true;
    }
    return false;
  }

  /**
   * getSyncWord
   *
   * Get sync word from modem
   */
  public int getSyncWord()
  {
    return syncWord;
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
    {
      syncWord = sync;
      return true;
    }
    return false;
  }

  /**
   * getDeviceAddr
   *
   * Get device address from modem
   */
  public int getDeviceAddr()
  {
    return deviceAddr;
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
    {
      deviceAddr = addr;
      return true;
    }
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
