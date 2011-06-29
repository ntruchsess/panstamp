/**
 * CommPortWriter.java
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

import java.io.OutputStream;

/**
 * Class: CommPortWriter
 * 
 * Description:
 * 
 * Serial port writer class
 */
public class CommPortWriter extends Thread
{
  /**
   * Output serial stream
   */
  private OutputStream out;

  /**
   * Serial message to be sent
   */
  private String message;

  /**
   * Send data buffer whenever this flag is true
   */
  private boolean sendDataFlag = false;

  /**
   * CommPortWriter
   * 
   * Class constructor
   * 
   * 'in'	Output serial stream
   */
  public CommPortWriter(OutputStream out)
  {
    this.out = out;
  }

  /**
   * run
   * 
   * Run thread
   */
  @Override
  public void run() 
  {
    while(true)
    {
      try
      {
        // Send data?
        if (sendDataFlag)
        {
          out.write(message.getBytes());
          out.flush();
          sendDataFlag = false;
        }

        // Wait for send command from parent
        waitForSend();
      }
      catch (Exception ex)
      {
      }
    }
  }

  /**
   * send
   * 
   * Send buffer
   * 
   * 'msg'  Serial message to be sent
   */
  public synchronized void send(String msg) throws CcException
  {
    System.out.println("Send: " + msg);
    this.message = msg;
    sendDataFlag = true;
    notify();
  }

  /**
   * waitForSend
   * 
   * Wait until the next serial data transmission
   */
  public synchronized void waitForSend() 
  {
    try
    {
      wait();
    }
    catch (InterruptedException ex)
    {
    }
  }
}
