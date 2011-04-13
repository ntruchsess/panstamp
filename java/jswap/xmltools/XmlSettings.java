/**
 * XmlSettings.java
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
package xmltools;

import org.w3c.dom.Element;
import java.io.IOException;
import java.io.BufferedWriter;
import java.io.FileWriter;

/**
 * Class: XmlSettings
 * 
 * Description:
 * 
 * General settings in form of XML file
 */
public class XmlSettings
{
  /**
   * XML file
   */
  private String file;

  /**
   * Directory where device definition files are placed
   */
  private String deviceDir = "devices";

  /**
   * Name/path of the serial settings file
   */
  private String serialFile = "serial.xml";

  /**
   * Name/path of the network settings file
   */
  private String networkFile = "network.xml";

  /**
   * XmlSettings
   *
   * Class constructor
   *
   * 'file'	Configuration file
   */
  public XmlSettings(String file) throws XmlException
  {
    this.file = file;
    
    Element elem;
    XmlParser parser = new XmlParser(file);

    if ((elem = parser.enterNodeName(null, "devices")) != null)
      deviceDir =  parser.getNodeValue(elem);
    if ((elem = parser.enterNodeName(null, "serial")) != null)
      serialFile =  parser.getNodeValue(elem);
    if ((elem = parser.enterNodeName(null, "network")) != null)
      networkFile =  parser.getNodeValue(elem);
  }

  /**
   * getDeviceDir
   * 
   * Return directory where device definition files are placed
   */
  public final String getDeviceDir() 
  {
    return deviceDir;
  }

  /**
   * setDeviceDir
   * 
   * Set directory where device definition files are placed
   */
  public void setDeviceDir(String value) 
  {
    deviceDir = value;
  }

  /**
   * getSerialFile
   * 
   * Return the name/path of the serial settings file
   */
  public final String getSerialFile() 
  {
    return serialFile;
  }

  /**
   * setSerialFile
   * 
   * Return the name/path of the serial settings file
   */
  public void setSerialFile(String value) 
  {
    serialFile = value;
  }

  /**
   * getNetworkFile
   * 
   * Return name/path of the network settings file
   */
  public final String getNetworkFile()
  {
    return networkFile;
  }

  /**
   * setNetworkFile
   * 
   * Set name/path of the network settings file
   */
  public void setNetworkFile(String value)
  {
    networkFile = value;
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
      out.write("<settings>\n");
      out.write("\t<devices>" + deviceDir + "</devices>");
      out.write("\t<serial>" + serialFile + "</serial>");
      out.write("\t<network>" + networkFile + "</network>");
      out.write("</settings>\n");
      out.close();
    }
    catch (IOException ex)
    {
      throw new XmlException("Unable to create " + file);
    }
  }
}
