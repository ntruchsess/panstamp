/**
 * XmlNetwork.java
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
 * Class: XmlNetwork
 * 
 * Description:
 * 
 * Wireless parameters in form of XML file
 */
public class XmlNetwork
{
  /**
   * XML file
   */
  private String file;

  /**
   * Security option
   */
  private int security = 0;

  /**
   * XmlNetwork
   * 
   * Class constructor
   * 
   * 'file'	XML file
   */
  public XmlNetwork(String file) throws XmlException
  {
    this.file = file;

    Element elRoot, elem;

    XmlParser parser = new XmlParser(file);
    if ((elRoot = parser.enterNodeName(null, "network")) != null)
    {
      if ((elem = parser.enterNodeName(elRoot, "security")) != null)
        security = Integer.parseInt(parser.getNodeValue(elem));
    }
  }

  /**
   * getSecurity
   * 
   * Return security option
   */
  public final int getSecurity() 
  {
    return security;
  }

  /**
   * setSecurity
   * 
   * Set security option
   */
  public void setSecurity(int value) 
  {
    security = value;
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
      out.write("<network>\n");
      out.write("\t<security>" + security + "</security>");
      out.write("</network>\n");
      out.close();
    }
    catch (IOException ex)
    {
      throw new XmlException("Unable to create " + file);
    }
  }
}
