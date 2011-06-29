/**
 * Device.java
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
package device;

import swap.SwapComm;
import swap.SwapPacket;
import swap.SwapPacketHandler;
import swap.SwapEndpoint;
import swap.SwapMote;
import swap.SwapDefs;
import swap.SwapQueryPacketBcast;
import swap.SwapInfoPacket;
import ccexception.CcException;
import xmltools.XmlException;
import xmltools.XmlParser;
import xmltools.XmlNetwork;
import xmltools.XmlSerial;

import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import java.util.ArrayList;
import java.io.File;
import swap.SwapRegister;

/**
 * Class: Device
 * 
 * Description:
 * 
 * SWAP device class. SWAP devices are typically computers using this library
 */
public class SwapGateway extends SwapMote implements SwapPacketHandler
{
  /**
   * Serial settings
   */
  private XmlSerial serial;

  /**
   * Network settings
   */
  private XmlNetwork network;
  
  /**
   * SWAP communication port
   */
  private SwapComm swapComm;

  /**
   * Device event handler
   */
  private DeviceEventHandler eventHandler;

  /**
   * Security option
   */
  private int security = 0;

  /**
   * Network identifier
   */
  private int netId;

  /**
   * Frequency channel
   */
  private int freqChannel;

  /**
   * Vector of SWAP motes
   */
  private ArrayList alMotes;

  /**
   * Vector of SWAP endpoints
   */
  private ArrayList alEndpoints;

  /**
   * Expected ACK packet (SWAP info packet containing a given endpoint data)
   */
  private SwapInfoPacket expectedAck = null;

   /**
    * True if last packet was ack'ed
    */
  private boolean packetAcked = false;

   /**
    * Maximum waiting time (in ms) for ACK's
    */
  private final static int MAX_WAITTIME_ACK = 500;

   /**
    * Max tries for any configuration command
    */
  private final static int MAX_CONFIG_TRIES = 3;

  /**
   * Device
   *
   * Class constructor
   *
   * 'parent'	Device event handler parent
   */
  public SwapGateway(DeviceEventHandler parent) throws XmlException
  {
    super(SwapDefs.DEF_PRODUCT_CODE, SwapDefs.DEF_DEV_ADDRESS);

    this.eventHandler = parent;

    // Generate serial parameters from XML file
    serial = new XmlSerial(Settings.getSerialFile());
    // Generate network settings from XML file
    network = new XmlNetwork(Settings.getNetworkFile());

    SwapEndpoint.device = this;
    // Create vector of SWAP motes
    this.alMotes = new ArrayList();
    // Create vector of SWAP endpoints
    this.alEndpoints = new ArrayList();
  }

  /**
   * connect
   *
   * Connect serial port and start SWAP comms
   */
  public void connect() throws CcException
  {
    // SwapComm object
    swapComm = new SwapComm(this, serial.getPort(), serial.getSpeed());
    // Start SWAP comms
    swapComm.connect();
    
    int val;
    if ((val = swapComm.getFreqChannel()) >= 0)
      freqChannel = val;
    if ((val = swapComm.getNetworkId()) >= 0)
      netId = val;
    if ((val = swapComm.getAddress()) > 0)
      setAddress(val);

    // Discover wireless motes
    alMotes.clear();
    discoverMotes();
  }

  /**
   * disconnect
   *
   * Stop SWAP comms and disconnect serial port
   */
  public void disconnect() throws CcException
  {
    swapComm.disconnect();
  }
  
  /**
   * swapPacketReceived
   * 
   * SWAP packet received
   * 
   * 'packet'	SWAP packet
   */
  public void swapPacketReceived(SwapPacket packet) 
  {
    try
    {
      switch (packet.function)
      {
        case SwapPacket.FINFO:
          // Expected ack?
          checkAck(packet);
          // Check type of data
          switch (packet.regId)
          {
            case SwapDefs.ID_PRODUCT_CODE:
              // Add new mote to alMotes
              SwapMote swapMote = new SwapMote(packet.value.toArray(), packet.srcAddress);
              swapMote.setNonce(packet.nonce);
              addMote(swapMote);
              createEndpoints(swapMote);
              break;
            case SwapDefs.ID_DEVICE_ADDR:
              // Update mote address in alMotes
              updateMoteAddress(packet.srcAddress, packet.value.toInteger());
              break;
            case SwapDefs.ID_SYSTEM_STATE:
              newMoteState(packet);
              break;
            default:
              // Update endpoint in alEndpoints
              updateEndpoint(packet);
              break;
          }
          break;
        case SwapPacket.FQUERY:
          // Query sent to this gateway?
          if (packet.destAddress == this.getAddress())
          {
            // Recover endpoint from array list
            SwapEndpoint endpoint = getEndpointFromAddress(packet.regAddress, packet.regId);
            // Send info packet
            endpoint.sendSwapInfo();
          }
          break;
        case SwapPacket.FCOMMAND:
          // Command sent to an endpoint belonging to this gateway?
          if (packet.destAddress == this.getAddress() && packet.destAddress == packet.regAddress)
          {
            // Recover endpoint from array list
            SwapEndpoint endpoint = getEndpointFromAddress(packet.regAddress, packet.regId);
            // Set new value
            endpoint.setValue(packet.value);
            // Send info packet
            endpoint.sendSwapInfo();
          }
          break;
        default:
          break;
      }
    }
    catch (CcException ex)
    {
      ex.print();
    }
  }

  /**
   * discoverMotes
   *
   * Discover wireless motes by querying (broadcast) the product code
   * from all the motes currently listening on the channel
   */
  private void discoverMotes() throws CcException
  {
    SwapQueryPacketBcast packet = new SwapQueryPacketBcast(SwapDefs.ID_PRODUCT_CODE);
    packet.send();
  }

  /**
   * addMote
   *
   * Add mote to alMotes
   */
  private void addMote(SwapMote mote)
  {
    int i;
    SwapMote tmpMote;
    boolean exists = false;

    for(i=0 ; i<alMotes.size() ; i++)
    {
      tmpMote = (SwapMote)alMotes.get(i);
      if (tmpMote.getAddress() == mote.getAddress())
      {
        exists = true;
        break;
      }
    }
    if (!exists)
    {
      alMotes.add(mote);

      eventHandler.newMoteDetected(mote);
    }
  }

  /**
   * getNbOfMotes
   *
   * Return the amount of motes available in the list
   */
  public int getNbOfMotes()
  {
    return alMotes.size();
  }

  /**
   * getMoteFromIndex
   *
   * Get mote from array list given its index
   *
   * 'index'  Index of the mote within the list of motes
   */
  public SwapMote getMoteFromIndex(int index)
  {
    return (SwapMote)alMotes.get(index);
  }

  /**
   * getMoteFromAddress
   *
   * Get mote from array list given its address
   *
   * 'index'  Index of the mote within the list of motes
   */
  public SwapMote getMoteFromAddress(int address)
  {
    int i;
    SwapMote tmpMote;

    for(i=0 ; i<alMotes.size() ; i++)
    {
      tmpMote = (SwapMote)alMotes.get(i);
      if (tmpMote.getAddress() == address)
        return tmpMote;
    }
    return null;
  }

  /**
   * removeMote
   *
   * Remove SWAP mote from list
   *
   * 'index'  Index of the mote to be removed
   */
  public void removeMote(int index)
  {
    alMotes.remove(index);
  }

  /**
   * updateMoteAddress
   *
   * Update mote address in list
   *
   * 'oldAddr'	old address
   * 'newAddr'  New address
   */
  private void updateMoteAddress(int oldAddr, int newAddr)
  {
    int i;
    SwapMote tmpMote;

    for(i=0 ; i<alMotes.size() ; i++)
    {
      tmpMote = (SwapMote)alMotes.get(i);
      if (tmpMote.getAddress() == oldAddr)
      {
        tmpMote.setAddress(newAddr);
        alMotes.set(i, tmpMote);

        eventHandler.newMoteDetected(tmpMote);
        break;
      }
    }
  }

  /**
   * waitForResponseFrom
   *
   * Wait for ACK (SWAP info) from a given endpoint after having sent a query to it
   *
   * 'epAddr'	Endpoint address
   * 'epId'   Endpoint id
   * 'epVal'  Expected SWAP value
   * 'maxWait'	Max time (in ms) to wait
   *
   * Return true if the last command has been correctly ack'ed
   */
  private boolean waitForAck(SwapInfoPacket ack, long maxWait)
  {
    boolean res;

    expectedAck = ack;

    long lastTime = System.currentTimeMillis();
    while (System.currentTimeMillis() - lastTime < maxWait)
    {
      if (packetAcked)
        break;
    }

    res = packetAcked;

    // Reset ack variables
    packetAcked = false;
    expectedAck = null;

    return res;
  }

  /**
   * checkAck
   *
   * Check ack from info received
   *
   * 'packet' SWAP packet to check against the expected Ack
   *
   * Return true in case of correct ack received
   */
  private boolean checkAck(SwapPacket packet)
  {
    packetAcked = false;
    
    if (expectedAck != null && packet.function == SwapPacket.FINFO)
    {
      if (packet.regAddress == expectedAck.regAddress)
      {
        if (packet.regId == expectedAck.regId)
          packetAcked = expectedAck.value.isEqual(packet.value);
      }
    }
    return packetAcked;
  }

  /**
   * getSecurity
   *
   * Return security option
   */
  public final int getSecurity()
  {
    return network.getSecurity();
  }

  /**
   * getFreqChannel
   *
   * Return frequency channel
   */
  public final int getFreqChannel()
  {
    return freqChannel;
  }

  /**
   * setFreqChannel
   *
   * Set frequency channel
   */
  public boolean setFreqChannel(int value) throws CcException
  {
    SwapMote tmpMote;
    SwapInfoPacket ack;
    boolean res = true;
    int i = 0, tries = 0;

    while(i < alMotes.size())
    {
      tmpMote = (SwapMote) alMotes.get(i);
      ack = tmpMote.cmdFreqChannel(value);
      if (tmpMote.getPwrDownMode())
        i++;
      else
      {
        tries++;
        if (waitForAck(ack, MAX_WAITTIME_ACK))
        {
          i++;
          tries = 0;
        }
        else if (tries == MAX_CONFIG_TRIES)
        {
          i++;
          tries = 0;
          res = false;
        }
      }
    }
    if (swapComm.setFreqChannel(value))
      freqChannel = value;

    return res;
  }

  /**
   * getNetId
   *
   * Return network id
   */
  public final int getNetId()
  {
    return netId;
  }

  /**
   * setNetId
   *
   * Set network id
   */
  public boolean setNetId(int value) throws CcException
  {
    SwapMote tmpMote;
    SwapInfoPacket ack;
    boolean res = true;
    int i = 0, tries = 0;

    while(i < alMotes.size())
    {
      tmpMote = (SwapMote) alMotes.get(i);
      ack = tmpMote.cmdNetworkId(value);
      if (tmpMote.getPwrDownMode())
        i++;
      else
      {
        tries++;
        if (waitForAck(ack, MAX_WAITTIME_ACK))
        {
          i++;
          tries = 0;
        }
        else if (tries == MAX_CONFIG_TRIES)
        {
          i++;
          tries = 0;
          res = false;
        }
      }
    }
    if (swapComm.setNetworkId(value))
      netId = value;

    return res;
  }

  /**
   * setAddress
   *
   * Set device address
   */
  public boolean setDevAddress(int value) throws CcException
  {
    SwapMote tmpMote;
    SwapInfoPacket ack;
    boolean res = true;
    int i = 0, tries = 0;

    while(i < alMotes.size())
    {
      tmpMote = (SwapMote) alMotes.get(i);
      ack = tmpMote.cmdAddress(value);
      if (tmpMote.getPwrDownMode())
        i++;
      else
      {
        tries++;
        if (waitForAck(ack, MAX_WAITTIME_ACK))
        {
          i++;
          tries = 0;
        }
        else if (tries == MAX_CONFIG_TRIES)
        {
          i++;
          tries = 0;
          res = false;
        }
      }
    }
    if (swapComm.setAddress(value))
      setAddress(value);

    return res;
  }

  /**
   * updateEndpoint
   *
   * Update endpoint in the array list
   *
   * 'info'	SWAP packet containing information about the endpoint
   */
  private void updateEndpoint(SwapPacket info)
  {
    int i;
    SwapEndpoint tmpEndpoint;

    for(i=0 ; i<alEndpoints.size() ; i++)
    {
      tmpEndpoint = (SwapEndpoint)alEndpoints.get(i);
      if (tmpEndpoint.getAddress() == info.regAddress)
      {
        if (tmpEndpoint.getRegisterId() == info.regId)
        {
          // value changed?
          if (!tmpEndpoint.getValue().isEqual(info.value))
          {
            // Update value
            if (tmpEndpoint.setRegisterValue(info.value))
            {
              // Update endpoint in the array list
              alEndpoints.set(i, tmpEndpoint);
              // Notify changes
              eventHandler.endpointValueChanged(tmpEndpoint);
            }
          }
        }
      }
    }
  }

  /**
   * newMoteState
   *
   * New mote state received
   *
   * 'info'	SWAP packet containing information about the state
   */
  private void newMoteState(SwapPacket info)
  {
    if (info.regId != SwapDefs.ID_SYSTEM_STATE)
      return;
    
    SwapMote mote = getMoteFromAddress(info.srcAddress);

    if (mote != null)
    {
      if (info.value.getLength() != 1)
        return;

      int state = info.value.toInteger();

      if (mote.getState() != state)
      {
        mote.setState(state);
        eventHandler.moteStateChanged(mote);
      }
    }
  }

  /**
   * getEndpointFromIndex
   *
   * Get endpoint given its index in the array list
   *
   * 'index'	Index of the endpoint
   */
  public SwapEndpoint getEndpointFromIndex(int index)
  {
    return (SwapEndpoint) alEndpoints.get(index);
  }

  /**
   * getEndpointFromAddress
   *
   * Get endpoint from the array list given its device address and id
   *
   * 'addr'	Device address
   * 'id' Endpoint ID
   */
  public SwapEndpoint getEndpointFromAddress(int addr, int id)
  {
    int i;
    SwapEndpoint tmpEndpoint;

    for(i=0 ; i<alEndpoints.size() ; i++)
    {
      tmpEndpoint = (SwapEndpoint)alEndpoints.get(i);
      if (tmpEndpoint.getAddress() == addr && tmpEndpoint.getRegisterId() == id)
        return tmpEndpoint;
    }
    return null;
  }

  /**
   * getNbOfEndpoints
   *
   * Return the amount of endpoints available in the array list
   */
  public int getNbOfEndpoints()
  {
    return alEndpoints.size();
  }

  /**
   * createEndpoints
   *
   * Create endpoints from  device definition file
   *
   * 'mote'  parent device
   */
  public void createEndpoints(SwapMote mote) throws XmlException
  {
    Element elRoot, elRegister, elEndpoint, elem;

    XmlParser parser = new XmlParser(Settings.getDeviceDir() + File.separator + Long.toHexString(mote.getManufactId()) +
                                      File.separator + Long.toHexString(mote.getProductId()) + ".xml");

    if ((elRoot = parser.enterNodeName(null, "registers")) != null)
    {
      NodeList regList;
      if ((regList = elRoot.getElementsByTagName("reg")) != null)
      {
        int i, id;
        for(i=0 ; i<regList.getLength() ; i++)
        {
          elRegister = (Element) regList.item(i);
          id = Integer.parseInt(elRegister.getAttribute("id"));
          SwapRegister register = new SwapRegister(mote, id);
          
          NodeList epList;
          if ((epList = elRegister.getElementsByTagName("endpoint")) != null)
          {
            int j;
            String type, dir;
            for(j=0 ; j<epList.getLength() ; j++)
            {
              elEndpoint = (Element) epList.item(j);
              type = elEndpoint.getAttribute("type");
              dir = elEndpoint.getAttribute("dir");

              // Create endpoint
              SwapEndpoint endpoint = new SwapEndpoint(register, SwapEndpoint.Type.valueOf(type), SwapEndpoint.Direction.valueOf(dir));
              
              if ((elem = parser.enterNodeName(elEndpoint, "position")) != null)
                endpoint.setPosition(Byte.parseByte(parser.getNodeValue(elem)));
              if ((elem = parser.enterNodeName(elEndpoint, "size")) != null)
                endpoint.setSize(Byte.parseByte(parser.getNodeValue(elem)));
              // Add endpoint to the array list
              alEndpoints.add(endpoint);
              // Notify changes
              eventHandler.newEndpointDetected(endpoint);
            }
          }
        }
      }
    }
  }

  /**
   * getSerialPort
   *
   * Get name/path of the serial port
   */
  public final String getSerialPort()
  {
    return serial.getPort();
  }

  /**
   * getSpeed
   *
   * Get serial baud rate
   */
  public final int getSpeed()
  {
    return serial.getSpeed();
  }

  /**
   * setSerialParams
   *
   * Set serial parameters
   *
   * 'port'	Name/path of the serial port
   * 'speed'	Serial baud rate
   */
  public void setSerialParams(String port, int speed) throws XmlException
  {
    serial.setPort(port);
    serial.setSpeed(speed);
    // Write XML file
    serial.write();
  }

  /**
   * setSecurity
   *
   * Set security settings
   *
   * 'security'	Security option
   *
   * Return false if at least one mote was not able to change its security settings
   */
  public boolean setSecurity(int security) throws CcException
  {
     SwapMote tmpMote;
    SwapInfoPacket ack;
    boolean res = true;
    int i = 0, tries = 0;

    while(i < alMotes.size())
    {
      tmpMote = (SwapMote) alMotes.get(i);
      ack = tmpMote.cmdSecurity(security);
      if (tmpMote.getPwrDownMode())
        i++;
      else
      {
        tries++;
        if (waitForAck(ack, MAX_WAITTIME_ACK))
        {
          i++;
          tries = 0;
        }
        else if (tries == MAX_CONFIG_TRIES)
        {
          i++;
          tries = 0;
          res = false;
        }
      }
    }
    network.setSecurity(security);
    network.write();

    return res;
  }
}
