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
 * Creation date: #cdate#
 */

package swapdmt;

import ccexception.CcException;
import javax.swing.DefaultListModel;
import swap.SwapMote;
import swap.SwapValue;

import org.jdesktop.application.Action;
import org.jdesktop.application.SingleFrameApplication;
import org.jdesktop.application.FrameView;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JOptionPane;

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

    // Add model to jListSwapMotes
    swapMotes = new DefaultListModel();
    jListSwapMotes.setModel(swapMotes);
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
   * showGatewayBox
   *
   * Show "Gateway" box
   */
  @Action
  public void showAddressBox()
  {
    // Get current gateway address
    int addr = swapDmt.getGatewayAddress();

    String answer = JOptionPane.showInputDialog(null, "Enter new address (1-255)", addr);
    if (answer == null)   // CANCEL button pressed
      return;
    addr = Integer.parseInt(answer);
    if (addr < 1 || addr > 255)
    {
      JOptionPane.showMessageDialog(null,  "Please enter a valid address", "Warning", JOptionPane.WARNING_MESSAGE);
      return;
    }
    else
      swapDmt.setDevAddress(addr);
  }

  /**
   * showNetworkBox
   *
   * Display "network" box
   */
  @Action
  public void showNetworkBox()
  {
    int answer;
    
    answer = JOptionPane.showConfirmDialog(null, "There is a risks of loosing contact with some of your wireless devices\n Are you sure you want to continue?",
                                  "Attention!!", JOptionPane.OK_CANCEL_OPTION);
    if (answer == JOptionPane.CANCEL_OPTION)
      return;

    // Get current network settings
    int carFreq = swapDmt.getCarrierFreq();
    int freqChann = swapDmt.getFreqChannel();
    int netId = swapDmt.getNetworkId();
    int secu = swapDmt.getSecurityOpt();

    NetworkPanel netPanel = new NetworkPanel(carFreq, freqChann, netId, secu);
    answer = JOptionPane.showConfirmDialog(null, netPanel, "SWAP Network Settings",
                 JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

    if (answer == JOptionPane.OK_OPTION)
    {
      carFreq = netPanel.getCarrierFreq();
      freqChann = netPanel.getFreqChannel();
      netId = netPanel.getNetworkId();
      secu = netPanel.getSecurity();

      if (!swapDmt.setNetworkParams(carFreq, freqChann, netId, secu))
        JOptionPane.showMessageDialog(null,  "This appplication was not able to contact one or more wireless devices\n" +
                                             "You will probably have to configure these motes manually", "Warning", JOptionPane.WARNING_MESSAGE);
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
    jButtonSetEndpoint = new javax.swing.JButton();
    jButtonSetAddress = new javax.swing.JButton();
    jLabelManufactDescr = new javax.swing.JLabel();
    jLabelProduct = new javax.swing.JLabel();
    jLabelProductDescr = new javax.swing.JLabel();
    jButtonConnect = new javax.swing.JButton();
    menuBar = new javax.swing.JMenuBar();
    javax.swing.JMenu fileMenu = new javax.swing.JMenu();
    javax.swing.JMenuItem exitMenuItem = new javax.swing.JMenuItem();
    configMenu = new javax.swing.JMenu();
    serialMenuItem = new javax.swing.JMenuItem();
    networkMenuItem = new javax.swing.JMenuItem();
    addrMenuItem = new javax.swing.JMenuItem();
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

    jButtonSetEndpoint.setText(resourceMap.getString("jButtonSetEndpoint.text")); // NOI18N
    jButtonSetEndpoint.setEnabled(false);
    jButtonSetEndpoint.setName("jButtonSetEndpoint"); // NOI18N
    jButtonSetEndpoint.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        jButtonSetEndpointPressed(evt);
      }
    });

    jButtonSetAddress.setText(resourceMap.getString("jButtonSetAddress.text")); // NOI18N
    jButtonSetAddress.setEnabled(false);
    jButtonSetAddress.setName("jButtonSetAddress"); // NOI18N
    jButtonSetAddress.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(java.awt.event.ActionEvent evt) {
        jButtonSetAddressPressed(evt);
      }
    });

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
            .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
            .addComponent(jButtonSetAddress, javax.swing.GroupLayout.PREFERRED_SIZE, 97, javax.swing.GroupLayout.PREFERRED_SIZE)
            .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
            .addComponent(jButtonSetEndpoint)
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
          .addComponent(jButtonSetAddress)
          .addComponent(jButtonSetEndpoint))
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

    configMenu.setText(resourceMap.getString("configMenu.text")); // NOI18N
    configMenu.setName("configMenu"); // NOI18N

    serialMenuItem.setAction(actionMap.get("showSerialBox")); // NOI18N
    serialMenuItem.setText(resourceMap.getString("serialMenuItem.text")); // NOI18N
    serialMenuItem.setName("serialMenuItem"); // NOI18N
    configMenu.add(serialMenuItem);

    networkMenuItem.setAction(actionMap.get("showNetworkBox")); // NOI18N
    networkMenuItem.setText(resourceMap.getString("networkMenuItem.text")); // NOI18N
    networkMenuItem.setEnabled(false);
    networkMenuItem.setName("networkMenuItem"); // NOI18N
    configMenu.add(networkMenuItem);

    addrMenuItem.setAction(actionMap.get("showAddressBox")); // NOI18N
    addrMenuItem.setText(resourceMap.getString("addrMenuItem.text")); // NOI18N
    addrMenuItem.setEnabled(false);
    addrMenuItem.setName("addrMenuItem"); // NOI18N
    configMenu.add(addrMenuItem);

    menuBar.add(configMenu);

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
  private void jButtonSetAddressPressed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonSetAddressPressed
    int index = getMoteIndexFromList();
    if (index < 0)
      return;
    String answer = JOptionPane.showInputDialog(null, "Enter new address (1-255)");
    int addr = Integer.parseInt(answer);
    if (addr < 1 || addr > 255)
    {
      JOptionPane.showMessageDialog(null,  "Please enter a valid address", "Warning", JOptionPane.WARNING_MESSAGE);
      return;
    }
    setAddress(index, Integer.parseInt(answer));
  }//GEN-LAST:event_jButtonSetAddressPressed

  /**
   * jButtonConnectPressed
   *
   * "Connect" button pressed
   */
  private void jButtonConnectPressed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonConnectPressed
    swapDmt.connect();
    // Enable items
    jButtonSetAddress.setEnabled(true);
    jButtonSetEndpoint.setEnabled(true);
    networkMenuItem.setEnabled(true);
    addrMenuItem.setEnabled(true);
  }//GEN-LAST:event_jButtonConnectPressed

  /**
   * jButtonSetEndpointPressed
   *
   * "Set endpoint" button pressed
   */
  private void jButtonSetEndpointPressed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonSetEndpointPressed
    int index = getMoteIndexFromList();
    if (index < 0)
      return;
    EndpointPanel endpPanel = new EndpointPanel();
    int answer = JOptionPane.showConfirmDialog(null, endpPanel, "Set endpoint value",
                 JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

    if (answer == JOptionPane.OK_OPTION)
    {
      int epId = endpPanel.getEndpointId();
      if (epId < 3 || epId > 255)
      {
        JOptionPane.showMessageDialog(null, "Please enter a valid endpoint", "Warning", JOptionPane.WARNING_MESSAGE);
        return;
      }
      String val = endpPanel.getEndpointValue();
      setEndpVal(index, epId, val);
    }
  }//GEN-LAST:event_jButtonSetEndpointPressed

  /**
   * jListSwapMotesSelected
   * 
   * Item selected from list of SWAP motes
   */
  private void jListSwapMotesSelected(javax.swing.event.ListSelectionEvent evt) {//GEN-FIRST:event_jListSwapMotesSelected
    readMote(jListSwapMotes.getSelectedIndex());
  }//GEN-LAST:event_jListSwapMotesSelected

  // Variables declaration - do not modify//GEN-BEGIN:variables
  private javax.swing.JMenuItem addrMenuItem;
  private javax.swing.JMenu configMenu;
  private javax.swing.JButton jButtonConnect;
  private javax.swing.JButton jButtonSetAddress;
  private javax.swing.JButton jButtonSetEndpoint;
  private javax.swing.JLabel jLabel1;
  private javax.swing.JLabel jLabelAddress;
  private javax.swing.JLabel jLabelManufact;
  private javax.swing.JLabel jLabelManufactDescr;
  private javax.swing.JLabel jLabelProduct;
  private javax.swing.JLabel jLabelProductDescr;
  private javax.swing.JList jListSwapMotes;
  private javax.swing.JScrollPane jScrollPane1;
  private javax.swing.JPanel mainPanel;
  private javax.swing.JMenuBar menuBar;
  private javax.swing.JMenuItem networkMenuItem;
  private javax.swing.JMenuItem serialMenuItem;
  // End of variables declaration//GEN-END:variables

  private JDialog aboutBox;
  private DefaultListModel swapMotes;

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
    if (index < 0)
      JOptionPane.showMessageDialog(null, "Please select a device", "Warning", JOptionPane.WARNING_MESSAGE);
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
   * setAddress
   *
   * Send new address to mote
   *
   * 'index'    Index of the mote within the list
   * 'address'  New device address
   */
  private void setAddress(int index, int address)
  {
    if (index < 0)
    {
      JOptionPane.showMessageDialog(null, "Warning", "Please select a mote", JOptionPane.WARNING_MESSAGE);
      return;
    }

    SwapMote mote = swapDmt.getMote(index);
    // Send command to mote
    try
    {
      mote.cmdAddress(address);
    }
    catch (CcException ex)
    {
      ex.print();
    }
  }

  /**
   * setEndpVal
   *
   * Send new endpoint value
   *
   * 'index'  Index of the mote within the list
   * 'epId'   Endpoint ID
   * 'value'  New endpoint value
   */
  private void setEndpVal(int index, int epId, String value)
  {
    if (index < 0)
    {
      JOptionPane.showMessageDialog(null, "Warning", "Please select a mote", JOptionPane.WARNING_MESSAGE);
      return;
    }

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

    SwapMote mote = swapDmt.getMote(index);
    try
    {
      mote.cmdEndpoint(epId, swapVal);
    }
    catch (CcException ex)
    {
      ex.print();
    }
  }
}
