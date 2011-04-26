/**
 * TtyPort.java
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
import java.util.TooManyListenersException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Class: CommPort
 * 
 * Description:
 * 
 * Serial port class
 */
public class TtyPort
{
  /**
   * Serial port from the RXTX library
   */
  private SerialPort serialPort = null;

  /**
   * Name of the serial port
   */
  private String portName;

  /**
   * Serial speed
   */
  private int baudRate;

  /**
   * Input serial stream
   */
  private InputStream in;

  /**
   * Output serial stream
   */
  private OutputStream out;

  /**
   * Gateway object
   */
  private Gateway gateway;

  /**
   * Serial port receiver
   */
  private CommPortReader commReader;

  /**
   * Serial port writer
   */
  private CommPortWriter commWriter;

  /**
   * CommPort
   *
   * Class constructor
   *
   * 'parent'	Parent gateway object
   * 'port'	Path to the serial port
   * 'speed'	Serial baud rate
   */
  public TtyPort(Gateway parent, String port, int speed)
  {
    portName = port;
    baudRate = speed;
    gateway = parent;
  }

  /**
   * connect
   * 
   * Start serial comms
   */
  public void connect() throws CcException
  {
    try
    {
      CommPortIdentifier portIdentifier = CommPortIdentifier.getPortIdentifier(portName);

      if (portIdentifier.isCurrentlyOwned())
        throw new CcException("Serial port " + portName + " is currently in use");
      else
      {
        CommPort commPort = portIdentifier.open(this.getClass().getName(), 5000);
        if (commPort instanceof SerialPort)
        {
          serialPort = (SerialPort) commPort;
          serialPort.setSerialPortParams(baudRate, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
          serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);

          in = serialPort.getInputStream();
          out = serialPort.getOutputStream();
          out.flush();

          /**
           * Create serialport reader
           */
          commReader = new CommPortReader(gateway, in);
          serialPort.addEventListener(commReader);
          serialPort.notifyOnDataAvailable(true);

          /**
            * Create serialport writer
            */
          commWriter = new CommPortWriter(out);
          commWriter.start();
        }
        else
          throw new CcException(portName + " is not a valid serial port");
      }
    }
    catch (TooManyListenersException ex)
    {
      throw new CcException("TooManyListenersException: " + ex.getMessage());
    }
    catch (IOException ex)
    {
      throw new CcException("IOException: " + ex.getMessage());
    }
    catch (UnsupportedCommOperationException ex)
    {
      throw new CcException("UnsupportedCommOperationException: " + ex.getMessage());
    }
    catch (PortInUseException ex)
    {
      throw new CcException("PortInUseException: " + ex.getMessage());
    }
    catch (NoSuchPortException ex)
    {
      throw new CcException("NoSuchPortException: " + portName);
    }
  }

  /**
   * close
   * 
   * Close serial comms
   */
  public void close() throws CcException
  {
    if (serialPort != null)
    {
      try
      {
        // Close I/O streams
        in.close();
        out.close();
      }
      catch (IOException ex)
      {
        throw new CcException("Unable to close I/O streams\n" + ex.getMessage());
      }

      // Close serialport
      serialPort.close();
    }
  }

  /**
   * send
   *
   * Send serial data
   *
   * 'msg'	String to send
   */
  public void send(String msg) throws CcException
  {
    commWriter.send(msg);
  }
}
