/**
 * CommPortReader.java
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
package serial;

import ccexception.CcException;

import gnu.io.*;
import java.io.IOException;
import java.io.InputStream;

/**
 * Class: CommPortReader
 * 
 * Description:
 * 
 * Serial port reader class
 */
public class CommPortReader implements SerialPortEventListener
{
  /**
   * Communication gateway
   */
  private Gateway gateway;

  /**
   * Input serial stream
   */
  private InputStream in;

  /**
   * Initial container for the data being received
   */
  private byte[] buffer = new byte[512];

  /**
   * CommPortReader
   * 
   * Class constructor
   * 
   * 'eventHandler'	Event handler (master object implementing the Gateway interface)
   * 'in'	Input serial stream
   */
  public CommPortReader(Gateway eventHandler, InputStream in) throws CcException
  {
    this.in = in;
    this.gateway = eventHandler;
  }

  /**
   * serialEvent
   * Interface method
   * 
   * Function automatically called by the serial API whenever an event occurs
   * on the serial port.
   * 
   * 'event'	Event occurred on the serial port
   */
  public void serialEvent(SerialPortEvent event) 
  {
    int data;
    StringBuilder strBuf = new StringBuilder("");
    
    try
    {
      int i = 0;
      while ((data = in.read()) > -1)
      {
        if (data == '\n')
          break;
        else if (data != '\r')
          strBuf.append(Character.toChars(data));
      }
      // Notify event
      gateway.serialDataReceived(strBuf.toString());
    }
    catch (IOException e)
    {
    }
  }
}
