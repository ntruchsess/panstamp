/**
 * SWAPdmtView.java
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

import chronos.ChronosWatch;
import swap.SwapMote;
import swap.SwapValue;
import ccexception.CcException;
import xmltools.XmlException;

import org.jdesktop.application.Action;
import org.jdesktop.application.SingleFrameApplication;
import org.jdesktop.application.FrameView;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JOptionPane;
import java.util.ArrayList;
import javax.swing.DefaultListModel;

import java.awt.Dimension;
import java.awt.Toolkit;

/**
 * The application's main frame.
 */
public class SWAPdmtView extends FrameView
{
  /**
   * SWAP device management tool object
   */
  private SWAPdmt swapDmt;

  public SWAPdmtView(SingleFrameApplication app)
  {
    super(app);

    initComponents();

    // Center window
    Toolkit tk = Toolkit.getDefaultToolkit();
    Dimension screenSize = tk.getScreenSize();
    int screenHeight = screenSize.height;
    int screenWidth = screenSize.width;
    this.getFrame().setSize(screenWidth / 2, screenHeight / 2);
    this.getFrame().setLocation(screenWidth / 4, screenHeight / 4);

    // Add model to jListSwapMotes
    swapMotes = new DefaultListModel();
    jListSwapMotes.setModel(swapMotes);

    // Disable menus
    setEnableMenus(false);
  }

  /**
   * showGatewayBox
   *
   * Show "Gateway" box
   */
  @Action
  public void showSerialBox()
  {
    int answer;

    // Get current gateway settings
    String portName = swapDmt.getPortName();
    int portSpeed = swapDmt.getPortSpeed();

    SerialPanel serialPanel = new SerialPanel(portName, portSpeed);
    answer = JOptionPane.showConfirmDialog(null, serialPanel, "Serial port",
                 JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

    if (answer == JOptionPane.OK_OPTION)
    {
      portName = serialPanel.getPortName();
      if ((portSpeed = serialPanel.getPortSpeed()) < 0)
      {
        JOptionPane.showMessageDialog(null, "Please enter a valid baud rate");
        return;
      }
      swapDmt.setSerialParams(portName, portSpeed);
    }
  }

  /**
   * showGnetBox
   *
   * Display "gateway network" box
   */
  @Action
  public void showGnetBox()
  {
    int answer;
    
    // Get current network settings
    try
    {
      int address = swapDmt.getGatewayAddress();
      int freqChann = swapDmt.getFreqChannel();
      int netId = swapDmt.getNetworkId();
      int secu = swapDmt.getSecurityOpt();

      NetworkPanel netPanel = new NetworkPanel(address, freqChann, netId, secu);
      answer = JOptionPane.showConfirmDialog(null, netPanel, "Gateway's Network Settings",
                   JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

      if (answer == JOptionPane.OK_OPTION)
      {
        address = netPanel.getAddress();
        freqChann = netPanel.getFreqChannel();
        netId = netPanel.getNetworkId();
        secu = netPanel.getSecurity();

        if (!swapDmt.setNetworkParams(address, freqChann, netId, secu))
          JOptionPane.showMessageDialog(null,  "Unable to set gateway's network settings\n", "Warning", JOptionPane.WARNING_MESSAGE);
      }
    }
    catch(CcException ex)
    {
      ex.display();
    }
  }

  /**
   * showDnetBox
   *
   * Display "device network" box
   */
  @Action
  public void showDnetBox()
  {
    int answer;
    int index = getMoteIndexFromList();
    int address = 0xFF, freqChann, netId, secu;
    SwapMote mote = null;

    // Get current network settings
    try
    {
      freqChann = swapDmt.getFreqChannel();
      netId = swapDmt.getNetworkId();
      secu = swapDmt.getSecurityOpt();

      if (index >= 0)
      {
        address = mote.getAddress();
        mote = swapDmt.getMote(index);
      }

      NetworkPanel netPanel = new NetworkPanel(address, freqChann, netId, secu);
      answer = JOptionPane.showConfirmDialog(null, netPanel, "Device's Network Settings",
                   JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

      if (answer == JOptionPane.OK_OPTION)
      {
        address = netPanel.getAddress();
        freqChann = netPanel.getFreqChannel();
        netId = netPanel.getNetworkId();
        secu = netPanel.getSecurity();

        boolean runSync = false;
        // Mote not selected or mote with power-down mode?
        if (mote == null)
          runSync = true;
        else if (mote.getPwrDownMode())
          runSync = true;

        if (runSync)
        {
          // Display SYNC waiting screen
          syncDiag = new SyncDialog(null, true);
          syncDiag.setVisible(true);

          // Sync dialog closed by the user?
          if (syncDiag != null)
          {
            syncDiag = null;
            return;
          }

          // Sync signal received
          if (syncAddress > 0)
            mote = swapDmt.getMoteFromAddress(syncAddress);
        }

        // Send new parameters only if the mote has been contacted
        if (mote != null)
        {
          if (mote.getAddress() != address)
          {
            if (!mote.sendAddressWack(address))
            {
              JOptionPane.showMessageDialog(null,  "Unable to set device network address", "Warning", JOptionPane.WARNING_MESSAGE);
              return;
            }
          }
          if (swapDmt.getNetworkId() != netId)
          {
            if (!mote.sendNetworkIdWack(netId))
            {
              JOptionPane.showMessageDialog(null,  "Unable to set Network ID on device", "Warning", JOptionPane.WARNING_MESSAGE);
              return;
            }
          }
          if (swapDmt.getFreqChannel() != freqChann)
          {
            if (!mote.sendFreqChannelWack(freqChann))
            {
              JOptionPane.showMessageDialog(null,  "Unable to set frequency channel on device", "Warning", JOptionPane.WARNING_MESSAGE);
              return;
            }
          }
          if (swapDmt.getSecurityOpt() != secu)
          {
            if (!mote.sendSecurityWack(secu))
            {
              JOptionPane.showMessageDialog(null,  "Unable to set security option on device", "Warning", JOptionPane.WARNING_MESSAGE);
              return;
            }
          }
        }
        else
          JOptionPane.showMessageDialog(null,  "Unable to contact remote device", "Warning", JOptionPane.WARNING_MESSAGE);
      }
    }
    catch(CcException ex)
    {
      ex.display();
    }
  }

  /**
   * showChronosBox
   *
   * Display "chronos" box
   */
  @Action
  public void showChronosBox()
  {
    int answer, i;
  
    ChronosPanel chronosPanel = new ChronosPanel();
    answer = JOptionPane.showConfirmDialog(null, chronosPanel, "ez430-Chronos Settings",
                 JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

    if (answer == JOptionPane.OK_OPTION)
    {
      SwapValue dateTime = chronosPanel.getDateTimeString();
      SwapValue alarm = chronosPanel.getAlarmString();
      SwapValue calibration = chronosPanel.getCalibration();
      SwapValue period = chronosPanel.getTxPeriod();

      ArrayList pages = new ArrayList(ChronosWatch.NUMBER_OF_PAGES);
      
      for(i=0 ; i<ChronosWatch.NUMBER_OF_PAGES ; i++)
      {
        pages.add(chronosPanel.getPage(i));
      }

      configChronos(dateTime, alarm, calibration, period, pages);
    }
  }

 /**
   * showSetRegisterBox
   *
   * Display "Set register" box
   */
  @Action
  public void showSetRegisterBox()
  {
    SwapMote mote = null;

    RegisterPanel regPanel = new RegisterPanel();
    int answer = JOptionPane.showConfirmDialog(null, regPanel, "Set register value",
                 JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

    if (answer == JOptionPane.OK_OPTION)
    {
      int index = getMoteIndexFromList();

      if (index > -1)
        mote = swapDmt.getMote(index);

      boolean runSync = false;
      // Mote not selected or mote with power-down mode?
      if (mote == null)
        runSync = true;
      else if (mote.getPwrDownMode())
        runSync = true;

      if (runSync)
      {
        // Display SYNC waiting screen
        syncDiag = new SyncDialog(null, true);
        syncDiag.setVisible(true);

        // Sync dialog closed by the user?
        if (syncDiag != null)
        {
          syncDiag = null;
          return;
        }

        // Sync signal received
        if (syncAddress > 0)
          mote = swapDmt.getMoteFromAddress(syncAddress);
      }

      int regId = regPanel.getRegisterId();
      String val = regPanel.getRegisterValue();
      setRegVal(mote, regId, val);
    }
  }

  /**
   * showAboutBox
   *
   * Display "about" box
   */
  @Action
  public void showAboutBox()
  {
    if (aboutBox == null)
    {
      JFrame mainFrame = SWAPdmtApp.getApplication().getMainFrame();
      aboutBox = new SWAPdmtAboutBox(mainFrame);
      aboutBox.setLocationRelativeTo(mainFrame);
    }
    SWAPdmtApp.getApplication().show(aboutBox);
  }

  /** This method is called from within the constructor to
   * initialize the form.
   * WARNING: Do NOT modify this code. The content of this method is
   * always regenerated by the Form Editor.
   */
  @SuppressWarnings("unchecked")
  // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
  private void initComponents() {

    mainPanel = new javax.swing.JPanel();
    jScrollPane1 = new javax.swing.JScrollPane();
    jListSwapMotes = new javax.swing.JList();
    jLabel1 = new javax.swing.JLabel();
    jLabelAddress = new javax.swing.JLabel();
    jLabelManufact = new javax.swing.JLabel();
    jLabelManufactDescr = new javax.swing.JLabel();
    jLabelProduct = new javax.swing.JLabel();
    jLabelProductDescr = new javax.swing.JLabel();
    jButtonConnect = new javax.swing.JButton();
    jLabelStatus = new javax.swing.JLabel();
    menuBar = new javax.swing.JMenuBar();
    javax.swing.JMenu fileMenu = new javax.swing.JMenu();
    javax.swing.JMenuItem exitMenuItem = new javax.swing.JMenuItem();
    gatewayMenu = new javax.swing.JMenu();
    serialMenuItem = new javax.swing.JMenuItem();
    gNetMenuItem = new javax.swing.JMenuItem();
    deviceMenu = new javax.swing.JMenu();
    dNetMenuItem = new javax.swing.JMenuItem();
    chronosMenuItem = new javax.swing.JMenuItem();
    regMenuItem = new javax.swing.JMenuItem();
    javax.swing.JMenu helpMenu = new javax.swing.JMenu();
    javax.swing.JMenuItem aboutMenuItem = new javax.swing.JMenuItem();

    mainPanel.setName("mainPanel"); // NOI18N
    mainPanel.setPreferredSize(new java.awt.Dimension(490, 270));

    jScrollPane1.setName("jScrollPane1"); // NOI18N

    jListSwapMotes.setSelectionMode(javax.swing.ListSelectionModel.SINGLE_SELECTION);
    jListSwapMotes.setName("jListSwapMotes"); // NOI18N
    jListSwapMotes.addListSelectionListener(new javax.swing.event.ListSelectionListener() {
      public void valueChanged(javax.swing.event.ListSelectionEvent evt) {
        jListSwapMotesSelected(evt);
      }
    });
    jScrollPane1.setViewportView(jListSwapMotes);

    org.jdesktop.application.ResourceMap resourceMap = org.jdesktop.application.Application.getInstance(swapdmt.SWAPdmtApp.class).getContext().getResourceMap(SWAPdmtView.class);
    jLabel1.setText(resourceMap.getString("jLabel1.text")); // NOI18N
    jLabel1.setName("jLabel1"); // NOI18N

    jLabelAddress.setText(resourceMap.getString("jLabelAddress.text")); // NOI18N
    jLabelAddress.setName("jLabelAddress"); // NOI18N

    jLabelManufact.setText(resourceMap.getString("jLabelManufact.text")); // NOI18N
    jLabelManufact.setName("jLabelManufact"); // NOI18N

    jLabelManufactDescr.setText(resourceMap.getString("jLabelManufactDescr.text")); // NOI18N
    jLabelManufactDescr.setName("jLabelManufactDescr"); // NOI18N

    jLabelProduct.setText(resourceMap.getString("jLabelProduct.text")); // NOI18N
    jLabelProduct.setName("jLabelProduct"); // NOI18N

    jLabelProductDescr.setText(resourceMap.getString("jLabelProductDescr.text")); // NOI18N
    jLabelProductDescr.setName("jLabelProductDescr"); // NOI18N

    jButtonConnect.setText(resourceMap.getString("jButtonConnect.text")); // NOI18N
    jButtonConnect.setName("jButtonConnect"); // NOI18N
    jButtonConnect.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        jButtonConnectPressed(evt);
      }
    });

    jLabelStatus.setText(resourceMap.getString("jLabelStatus.text")); // NOI18N
    jLabelStatus.setName("jLabelStatus"); // NOI18N

    javax.swing.GroupLayout mainPanelLayout = new javax.swing.GroupLayout(mainPanel);
    mainPanel.setLayout(mainPanelLayout);
    mainPanelLayout.setHorizontalGroup(
      mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addGroup(mainPanelLayout.createSequentialGroup()
        .addContainerGap()
        .addGroup(mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
          .addGroup(mainPanelLayout.createSequentialGroup()
            .addGroup(mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
              .addComponent(jLabel1)
              .addGroup(mainPanelLayout.createSequentialGroup()
                .addComponent(jScrollPane1, javax.swing.GroupLayout.PREFERRED_SIZE, 220, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addGap(24, 24, 24)
                .addGroup(mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                  .addComponent(jLabelManufact)
                  .addComponent(jLabelProduct)
                  .addComponent(jLabelAddress)
                  .addComponent(jLabelProductDescr, javax.swing.GroupLayout.DEFAULT_SIZE, 218, Short.MAX_VALUE)
                  .addComponent(jLabelManufactDescr, javax.swing.GroupLayout.DEFAULT_SIZE, 218, Short.MAX_VALUE))))
            .addGap(378, 378, 378))
          .addGroup(mainPanelLayout.createSequentialGroup()
            .addComponent(jButtonConnect, javax.swing.GroupLayout.PREFERRED_SIZE, 92, javax.swing.GroupLayout.PREFERRED_SIZE)
            .addGap(18, 18, 18)
            .addComponent(jLabelStatus)
            .addContainerGap())))
    );
    mainPanelLayout.setVerticalGroup(
      mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
      .addGroup(mainPanelLayout.createSequentialGroup()
        .addContainerGap()
        .addComponent(jLabel1)
        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
        .addGroup(mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
          .addComponent(jScrollPane1, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.PREFERRED_SIZE, 191, javax.swing.GroupLayout.PREFERRED_SIZE)
          .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, mainPanelLayout.createSequentialGroup()
            .addComponent(jLabelManufact)
            .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
            .addComponent(jLabelManufactDescr)
            .addGap(5, 5, 5)
            .addComponent(jLabelProduct)
            .addGap(4, 4, 4)
            .addComponent(jLabelProductDescr)
            .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
            .addComponent(jLabelAddress)
            .addGap(85, 85, 85)))
        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
        .addGroup(mainPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
          .addComponent(jButtonConnect)
          .addComponent(jLabelStatus))
        .addGap(8, 8, 8))
    );

    menuBar.setName("menuBar"); // NOI18N

    fileMenu.setText(resourceMap.getString("fileMenu.text")); // NOI18N
    fileMenu.setName("fileMenu"); // NOI18N

    javax.swing.ActionMap actionMap = org.jdesktop.application.Application.getInstance(swapdmt.SWAPdmtApp.class).getContext().getActionMap(SWAPdmtView.class, this);
    exitMenuItem.setAction(actionMap.get("quit")); // NOI18N
    exitMenuItem.setName("exitMenuItem"); // NOI18N
    fileMenu.add(exitMenuItem);

    menuBar.add(fileMenu);

    gatewayMenu.setText(resourceMap.getString("gatewayMenu.text")); // NOI18N
    gatewayMenu.setName("gatewayMenu"); // NOI18N

    serialMenuItem.setAction(actionMap.get("showSerialBox")); // NOI18N
    serialMenuItem.setText(resourceMap.getString("serialMenuItem.text")); // NOI18N
    serialMenuItem.setName("serialMenuItem"); // NOI18N
    gatewayMenu.add(serialMenuItem);

    gNetMenuItem.setAction(actionMap.get("showGnetBox")); // NOI18N
    gNetMenuItem.setText(resourceMap.getString("gNetMenuItem.text")); // NOI18N
    gNetMenuItem.setName("gNetMenuItem"); // NOI18N
    gatewayMenu.add(gNetMenuItem);

    menuBar.add(gatewayMenu);

    deviceMenu.setText(resourceMap.getString("deviceMenu.text")); // NOI18N
    deviceMenu.setName("deviceMenu"); // NOI18N

    dNetMenuItem.setAction(actionMap.get("showDnetBox")); // NOI18N
    dNetMenuItem.setText(resourceMap.getString("dNetMenuItem.text")); // NOI18N
    dNetMenuItem.setName("dNetMenuItem"); // NOI18N
    deviceMenu.add(dNetMenuItem);

    chronosMenuItem.setAction(actionMap.get("showChronosBox")); // NOI18N
    chronosMenuItem.setText(resourceMap.getString("chronosMenuItem.text")); // NOI18N
    chronosMenuItem.setName("chronosMenuItem"); // NOI18N
    deviceMenu.add(chronosMenuItem);

    regMenuItem.setAction(actionMap.get("showSetRegisterBox")); // NOI18N
    regMenuItem.setText(resourceMap.getString("regMenuItem.text")); // NOI18N
    regMenuItem.setName("regMenuItem"); // NOI18N
    deviceMenu.add(regMenuItem);

    menuBar.add(deviceMenu);

    helpMenu.setText(resourceMap.getString("helpMenu.text")); // NOI18N
    helpMenu.setName("helpMenu"); // NOI18N

    aboutMenuItem.setAction(actionMap.get("showAboutBox")); // NOI18N
    aboutMenuItem.setName("aboutMenuItem"); // NOI18N
    helpMenu.add(aboutMenuItem);

    menuBar.add(helpMenu);

    setComponent(mainPanel);
    setMenuBar(menuBar);
  }// </editor-fold>//GEN-END:initComponents

  /**
   * jButtonSetAddressPressed
   * 
   * "Set address" button pressed
   */
  /**
   * jButtonConnectPressed
   *
   * "Connect/Disconnect" button pressed
   */
  private void jButtonConnectPressed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonConnectPressed
    // Start comms
    if (!swapDmt.isConnected())
    {
      // Update status
      updateStatus("Connecting...");
      // Connect comms
      swapDmt.connect();

      // Check connection
      if (swapDmt.isConnected())
      {
        // Enable items
        setEnableMenus(true);
        // Clear list of motes
        jListSwapMotes.removeAll();
        // Change button text
        jButtonConnect.setText("Disconnect");
        // Update status
        updateStatus("Connected");
      }
      else
      {
        JOptionPane.showMessageDialog(null,  "Unable to start comms on " + swapDmt.getPortName() + "\nPlease check serial modem", "Warning", JOptionPane.WARNING_MESSAGE);
        // Update status
        updateStatus("Disconnected");
      }
    }
    // Stop comms
    else
    {
      // Update status
      updateStatus("Disconnecting...");
      // Disconnect comms
      swapDmt.disconnect();

      // Check disconnection
      if (!swapDmt.isConnected())
      {
        // Disable items
        setEnableMenus(false);
        // Clear list of motes
        jListSwapMotes.removeAll();
        // Change button text
        jButtonConnect.setText("Connect");
        // Update status
        updateStatus("Disconnected");
      }
      else
      {
        JOptionPane.showMessageDialog(null,  "Unable to stop comms. Please check serial modem", "Warning", JOptionPane.WARNING_MESSAGE);
        // Update status
        updateStatus("Connected");
      }
    }
  }//GEN-LAST:event_jButtonConnectPressed

  /**
   * jListSwapMotesSelected
   * 
   * Item selected from list of SWAP motes
   */
  private void jListSwapMotesSelected(javax.swing.event.ListSelectionEvent evt) {//GEN-FIRST:event_jListSwapMotesSelected
    readMote(jListSwapMotes.getSelectedIndex());
  }//GEN-LAST:event_jListSwapMotesSelected

  // Variables declaration - do not modify//GEN-BEGIN:variables
  private javax.swing.JMenuItem chronosMenuItem;
  private javax.swing.JMenuItem dNetMenuItem;
  private javax.swing.JMenu deviceMenu;
  private javax.swing.JMenuItem gNetMenuItem;
  private javax.swing.JMenu gatewayMenu;
  private javax.swing.JButton jButtonConnect;
  private javax.swing.JLabel jLabel1;
  private javax.swing.JLabel jLabelAddress;
  private javax.swing.JLabel jLabelManufact;
  private javax.swing.JLabel jLabelManufactDescr;
  private javax.swing.JLabel jLabelProduct;
  private javax.swing.JLabel jLabelProductDescr;
  private javax.swing.JLabel jLabelStatus;
  private javax.swing.JList jListSwapMotes;
  private javax.swing.JScrollPane jScrollPane1;
  private javax.swing.JPanel mainPanel;
  private javax.swing.JMenuBar menuBar;
  private javax.swing.JMenuItem regMenuItem;
  private javax.swing.JMenuItem serialMenuItem;
  // End of variables declaration//GEN-END:variables

  private JDialog aboutBox;
  private DefaultListModel swapMotes;

  // Sync splash screen
  SyncDialog syncDiag = null;

  /**
   * Address of the mote having sent a SYNC state packet. -1 if none
   */
  private int syncAddress = -1;

  /**
   * setSWAPdmtObj
   *
   * Set SWAP Device Management Tool object
   *
   * 'dmt'  SWAP device management tool object
   */
  public void setSWAPdmtObj(SWAPdmt dmt)
  {
    swapDmt = dmt;
  }
  
  /**
   * addMoteToList
   *
   * Add SWAP mote to the list
   */
  public void addMoteToList(SwapMote mote)
  {
    swapMotes.addElement("Addr: " + mote.getAddress() + " Prod: " + mote.getProduct());
  }

  /**
   * clearMoteList
   *
   * Clear list of SWAP motes
   */
  public void clearMoteList()
  {
    swapMotes.removeAllElements();
  }
  
  /**
   * getMoteIndexFromList
   *
   * Get selected index from the list
   */
  private int getMoteIndexFromList()
  {
    int index = jListSwapMotes.getSelectedIndex();
    jListSwapMotes.clearSelection();
    return index;
  }

  /**
   * readMote
   *
   * Read properties of a given mote and fill the associated fields
   *
   * 'index'  Index of the mote within the list
   */
  private void readMote(int index)
  {
    if (index < 0)
      return;

    SwapMote mote = swapDmt.getMote(index);

    jLabelManufact.setText("Manufacturer: (ID: 0x" + Long.toHexString(mote.getManufactId()) + ")");
    jLabelProduct.setText("Product: (ID: 0x" + Long.toHexString(mote.getProductId()) + ")");
    jLabelManufactDescr.setText(mote.getManufacturer());
    jLabelProductDescr.setText(mote.getProduct());
    jLabelAddress.setText("Address: " + Integer.toString(mote.getAddress()));
  }

  /**
   * setRegVal
   *
   * Send new register value
   *
   * 'mote'   SWAP mote
   * 'regId'  Register ID
   * 'value'  New register value
   */
  private void setRegVal(SwapMote mote, int regId, String value)
  {
    SwapValue swapVal;
    // Does "value" represent a numeric value?
    try
    {
      long lVal;
      // Try with decimal format first
      lVal = Long.parseLong(value);
      // Calculate length
      int i;
      long a = lVal;
      for(i=0 ; i<Long.SIZE ; i++)
      {
        if ((a = a/0xFF) < 1)
          break;
      }
      // Create SWAP value
      swapVal = new SwapValue(lVal, i);
    }
    catch (Exception ex)
    {
      // Finaly, try with ASCII format
      swapVal = new SwapValue(value);
    }

    try
    {
      mote.cmdRegister(regId, swapVal);
    }
    catch (CcException ex)
    {
      ex.print();
    }
  }

  /**
   * configChronos
   *
   * Configure Chronos watch
   *
   * 'dateTime'     Date/Time configuration SwapValue, ready to be sent to the Chronos
   * 'alarm'        Alarm configuration SwapValue, ready to be sent to the Chronos
   * 'calibration'  Temperature & altitude calibration SwapValue, ready to be sent to the Chronos
   * 'period'       Transmission period for temperature, pressure and altitude data
   * 'pages'        List of browsing pages, ready to be sent to the Chronos
   */
  private void configChronos(SwapValue dateTime, SwapValue alarm, SwapValue calibration, SwapValue period, ArrayList pages)
  {
    // Display SYNC waiting screen
    syncDiag = new SyncDialog(null, true);
    syncDiag.setVisible(true);

    // Sync dialog closed by the user?
    if (syncDiag != null)
    {
      syncDiag = null;
      return;
    }

    // Once arrived to this point, we have a mote having sent a SYNC signal
    if (syncAddress > 0)
    {
      // Is the mote a Chronos watch?
      if (swapDmt.getMoteManufacturer(syncAddress).equalsIgnoreCase("panStamp"))
      {
        if (swapDmt.getMoteProduct(syncAddress).equalsIgnoreCase("Chronos"))
        {
          try
          {
            // Create temporary Chronos device
            ChronosWatch chronos = new ChronosWatch(syncAddress);
            // Configure settings
            chronos.setDateTime(dateTime);
            Thread.sleep(200);
            chronos.setAlarm(alarm);
            Thread.sleep(200);
            chronos.setCalibration(calibration);
            Thread.sleep(200);
            chronos.setTxPeriod(period);
            Thread.sleep(200);
            // Configure pages
            int i;
            for(i=0 ; i<ChronosWatch.NUMBER_OF_PAGES ; i++)
            {
              SwapValue pageCfg = (SwapValue)pages.get(i);
              if (pageCfg != null)
              {
                chronos.setPage(i, pageCfg);
                Thread.sleep(200);
              }
            }

            // Take out the chronos from the SYNC state
            chronos.stopSwapComms();
          }
          catch (XmlException ex)
          {
            ex.print();
          }
          catch (CcException ex)
          {
            ex.print();
          }
          catch (InterruptedException ex)
          {
            System.out.println(ex.getMessage());
          }

          syncAddress = -1;
        }
      }
    }
  }

  /**
   * syncReceived
   *
   * SYNC state received from mote
   *
   * 'devAddr'  Device address of the mote
   */
  public void syncReceived(int devAddr)
  {
    syncAddress = devAddr;

    // Close current SYNC dialog
    if (syncDiag != null)
    {
      syncDiag.close();
      syncDiag = null;
    }
  }

  /**
   * updateStatus
   *
   * Update status string
   */
  private void updateStatus(final String status)
  {
    jLabelStatus.setText(status);
    jLabelStatus.paintImmediately(jLabelStatus.getVisibleRect());
  }

  /**
   * setEnableMenus
   *
   * Enable/disable menus
   *
   * 'enable' If true, enable menus. If false, disable
   */
  private void setEnableMenus(boolean enable)
  {
    gNetMenuItem.setEnabled(enable);
    dNetMenuItem.setEnabled(enable);
    chronosMenuItem.setEnabled(enable);
    regMenuItem.setEnabled(enable);
  }
}
