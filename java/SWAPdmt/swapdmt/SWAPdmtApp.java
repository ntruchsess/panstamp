/**
 * SWAPdmtApp.java
 *
 * Copyright (c) 2011 Daniel Berenguer <dberenguer@usapiens.com>
 *
 * This file is part of the panStamp project.
 *
 * panStamp  is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * any later version.
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

package swapdmt;

import org.jdesktop.application.Application;
import org.jdesktop.application.SingleFrameApplication;

/**
 * The main class of the application.
 */
public class SWAPdmtApp extends SingleFrameApplication
{
  /**
   * At startup create and show the main frame of the application.
   */
  @Override protected void startup()
  {
    SWAPdmtView view = new SWAPdmtView(this);
    show(view);
    SWAPdmt sdmTool = new SWAPdmt(view);
  }

  /**
   * This method is to initialize the specified window by injecting resources.
   * Windows shown in our application come fully initialized from the GUI
   * builder, so this additional configuration is not needed.
   */
  @Override protected void configureWindow(java.awt.Window root)
  {
  }

  /**
   * A convenient static getter for the application instance.
   * @return the instance of SWAPdmtApp
   */
  public static SWAPdmtApp getApplication()
  {
    return Application.getInstance(SWAPdmtApp.class);
  }

  /**
   * Main method launching the application.
   */
  public static void main(String[] args)
  { 
    launch(SWAPdmtApp.class, args);
  }
}
