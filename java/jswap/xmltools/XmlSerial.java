/**
 * XmlSerial.java
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
package xmltools;

import org.w3c.dom.Element;
import java.io.IOException;
import java.io.BufferedWriter;
import java.io.FileWriter;

/**
 * Class: XmlSerial
 * 
 * Description:
 * 
 * Serial parameters in form of XML file
 */
public class XmlSerial
{
  /**
   * XML file
   */
  private String file;

  /**
   * Path/name of the serial port
   */
  private String port;

  /**
   * Serial baud rate
   */
  private int speed;

  /**
   * XmlSerial
   * 
   * Class constructor
   * 
   * 'file'	XML file
   */
  public XmlSerial(String file) throws XmlException
  {
    this.file = file;

    Element elRoot, elem;

    XmlParser parser = new XmlParser(file);
    if ((elRoot = parser.enterNodeName(null, "serial")) != null)
    {
      if ((elem = parser.enterNodeName(elRoot, "port")) != null)
        port = parser.getNodeValue(elem);
      if ((elem = parser.enterNodeName(elRoot, "speed")) != null)
        speed = Integer.parseInt(parser.getNodeValue(elem));
    }
  }

  /**
   * getPort
   * 
   * Return serial port
   */
  public final String getPort() 
  {
    return port;
  }

  /**
   * getSpeed
   * 
   * Return serial baud rate
   */
  public final int getSpeed() 
  {
    return speed;
  }

  /**
   * setPort
   * 
   * Set serial port
   */
  public void setPort(String value) 
  {
    port = value;
  }

  /**
   * setSpeed
   * 
   * Set serial baud rate
   */
  public void setSpeed(int value) 
  {
    speed = value;
  }

  /**
   * write
   * 
   * Write XML file
   */
  public void write() throws XmlException
  {
    try
    {
      BufferedWriter out = new BufferedWriter(new FileWriter(file));

      // Generate PHP file
      out.write("<?xml version=\"1.0\"?>\n");
      out.write("<serial>\n");
      out.write("\t<port>" + port + "</port>");
      out.write("\t<speed>" + speed + "</speed>");
      out.write("</serial>\n");
      out.close();
    }
    catch (IOException ex)
    {
      throw new XmlException("Unable to create " + file);
    }
  }
}
