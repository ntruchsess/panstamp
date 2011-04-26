/**
 * XmlParser.java
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

package xmltools;

import java.io.IOException;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;
import org.xml.sax.SAXException;

/**
 * XmlParser
 *
 * Simple XML parser class
 */
public class XmlParser
{
  /**
   * XML document
   */
  private Document doc;

  /**
   * Class constructor
   *
   * 'strFile'  Path to the xml file
   */
  public XmlParser(String strFile) throws XmlException
  {
    File fXmlFile = new File(strFile);
    DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
    DocumentBuilder dBuilder;
    try
    {
      dBuilder = dbFactory.newDocumentBuilder();
      doc = dBuilder.parse(fXmlFile);
      doc.getDocumentElement().normalize();
    }
    catch (ParserConfigurationException ex)
    {
      throw new XmlException("Unable to initialize XML parser for: " + strFile);
    }
    catch (SAXException ex)
    {
      throw new XmlException("Incorrect XML format: " + strFile);
    }
    catch (IOException ex)
    {
      throw new XmlException("Unable to open XML file: " + strFile);
    }
  }

 /**
  * enterNodeName
  *
  * Enter XML node with a given name
  *
  * 'baseNode'  Starting node
  * 'strNode'   Tag name
  *
  * Return node
  */
  public Element enterNodeName(Element baseNode, String strNode)
  {
    NodeList nList;
    
    if (baseNode == null)
      nList = doc.getElementsByTagName(strNode);
    else
      nList = baseNode.getElementsByTagName(strNode);

    Node nNode = nList.item(0);

    return (Element) nNode;
  }

  /**
   * getNodeValue
   *
   * 'elem' Element to get the value from
   *
   * Return the value of the node
   */
  public String getNodeValue(Element elem)
  {
    NodeList nlList= elem.getChildNodes();
    Node nValue = (Node) nlList.item(0);

    return nValue.getNodeValue();
  }
}
