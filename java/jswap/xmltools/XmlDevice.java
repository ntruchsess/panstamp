/**
 * XmlDevice.java
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
 * Class: XmlDevice
 * 
 * Description:
 * 
 * SWAP mote definition file
 */
public class XmlDevice
{
  /**
   * True if the mote is a battery-operated sensor with low power capability
   */
  private boolean pwrDownMode;

  /**
   * Manufacturer string
   */
  private String manufacturer;

  /**
   * Product string
   */
  private String product;

  /**
   * XmlDevice
   * 
   * Class constructor
   * 
   * 'defFile'	Definition file
   */
  public XmlDevice(String defFile) throws XmlException
  {
    Element elRoot, elem;

    XmlParser parser = new XmlParser(defFile);

    if ((elRoot = parser.enterNodeName(null, "device")) != null)
    {
      if ((elem = parser.enterNodeName(elRoot, "manufacturer")) != null)
        manufacturer = parser.getNodeValue(elem);
      if ((elem = parser.enterNodeName(elRoot, "product")) != null)
        product = parser.getNodeValue(elem);
      if ((elem = parser.enterNodeName(elRoot, "pwrdownmode")) != null)
        pwrDownMode = Boolean.parseBoolean(parser.getNodeValue(elem));
    }
  }

  /**
   * getPwrDownMode
   * 
   * Return the value of the low-power flag
   */
  public final boolean getPwrDownMode() 
  {
    return pwrDownMode;
  }

  /**
   * getManufacturer
   * 
   * Return manufacturer string
   */
  public final String getManufacturer() 
  {
    return manufacturer;
  }

  /**
   * getProduct
   * 
   * Return product string
   */
  public final String getProduct() 
  {
    return product;
  }

}
