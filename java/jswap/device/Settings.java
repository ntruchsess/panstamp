/**
 * Settings.java
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
package device;

import xmltools.XmlSettings;
import xmltools.XmlException;



/**
 * Class: Settings
 * 
 * Description:
 * 
 * Common settings
 */
public class Settings
{
  /**
   * Configuration file for the current settings
   */
  private static final String cfgFile = "settings.xml";

   /**
   * XML settings file
   */
  private static XmlSettings settings;

  /**
   * read
   * 
   * Take values from XML file
   */
  public static void read() throws XmlException
  {
    settings = new XmlSettings(cfgFile);
  }

  /**
   * getDeviceDir
   *
   * Return directory where device definition files are placed
   */
  public static String getDeviceDir()
  {
    return settings.getDeviceDir();
  }

  /**
   * getSerialFile
   *
   * Return name/path of the serial settings file
   */
  public static String getSerialFile()
  {
    return settings.getSerialFile();
  }

  /**
   * getNetworkFile
   *
   * Return name/path of the network settings file
   */
  public static String getNetworkFile()
  {
    return settings.getNetworkFile();
  }
}
