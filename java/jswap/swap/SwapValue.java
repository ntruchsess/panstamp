/**
 * SwapValue.java
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
package swap;

/**
 * Class: SwapValue
 * 
 * Description:
 * 
 * SWAP value field
 */
public class SwapValue
{
  /**
   * Value coded in form of int array
   */
  public int[] value;

  /**
   * SwapValue
   *
   * Class constructor
   *
   * 'val'	Array of integers
   */
  public SwapValue(int[] val)
  {
    value = val;
  }

  /**
   * SwapValue
   *
   * Class constructor
   *
   * 'val'	integer
   */
  public SwapValue(int val)
  {
    int i;
    value = new int[4];

    for(i=0 ; i<4 ; i++)
      value[i] = (val >> 8*(3-i)) & 0xFF;
  }

  /**
   * SwapValue
   *
   * Class constructor
   *
   * 'val'	integer
   * 'len'  length (1-4)
   */
  public SwapValue(int val, int len)
  {
    int i, length;

    if (len < 1)
      length = 1;
    else if (len > Integer.SIZE)
      length = Integer.SIZE;
    else
      length = len;

    value = new int[length];

    for(i=0 ; i<length ; i++)
      value[i] = (val >> 8*(length-1-i)) & 0xFF;
  }

  /**
   * SwapValue
   *
   * Class constructor
   *
   * 'val'	long integer
   * 'len'  length (1-8)
   */
  public SwapValue(long val, int len)
  {
    int i, length;

    if (len < 1)
      length = 1;
    else if (len > Long.SIZE)
      length = Long.SIZE;
    else
      length = len;

    value = new int[length];

    for(i=0 ; i<length ; i++)
      value[i] = (int)(val >> 8*(length-1-i)) & 0xFF;
  }

  /**
   * SwapValue
   *
   * Class constructor
   *
   * 'val'	long integer
   */
  public SwapValue(long val)
  {
    int i;
    value = new int[8];

    for(i=0 ; i<8 ; i++)
      value[i] = (int)((val >> 8*(7-i)) & 0xFF);
  }

  /**
   * SwapValue
   *
   * Class constructor
   *
   * 'strVal'	string
   */
  public SwapValue(String strVal)
  { 
    int i;
    value = new int[strVal.length()];

    for(i=0 ; i<strVal.length() ; i++)
      value[i] = (int)strVal.charAt(i);
  }

  /**
   * getLength
   *
   * Return length of value
   */
  public int getLength()
  {
    return value.length;
  }
  /**
   * toInteger
   * 
   * Convert to integer
   */
  public int toInteger() 
  {
    int i, len = value.length;
    int val = 0;

    if (len > Integer.SIZE)
      len = Integer.SIZE;

    for(i=0 ; i<len ; i++)
      val |= (value[i] & 0xFF) << 8*(len-1-i);

    return val;
  }

  /**
   * toLong
   * 
   * Convert to long
   */
  public long toLong() 
  {
    int i, len = value.length;
    long val = 0;

    if (len > Long.SIZE)
      len = Long.SIZE;

    for(i=0 ; i<len ; i++)
      val |= (value[i] & 0xFF) << 8*(len-1-i);

    return val;
  }

  /**
   * toString
   * 
   * Convert to string
   */
  @Override
  public String toString() 
  {
    int i;
    StringBuilder strBuf = new StringBuilder("");

    for(i=0 ; i<value.length ; i++)
    {
      if (value[i] != 0)
        strBuf.append(value[i]);
    }
    
    return strBuf.toString();
  }

  /**
   * toArray
   *
   * Return array of integers
   */
  public int[] toArray()
  {
    return value;
  }

  /**
   * isEqual
   *
   * Return true if both values are equal
   *
   * 'val'	Value to compare against the current one
   */
  public boolean isEqual(SwapValue val)
  {
    int i;

    if (value.length != val.toArray().length)
      return false;
    
    for(i=0 ; i<value.length ; i++)
    {
      if (value[i] != val.toArray()[i])
        return false;
    }

    return true;
  }

  /**
   * parseSwapValue
   *
   * Parse SwapValue from string
   *
   * 'str'	String to be parsed
   *
   * Returns:
   *   SwapValue
   */
  public static SwapValue parseSwapValue(String str)
  {
    int i, len = str.length()/2;
    int[] arr = new int[len];

    for(i=0 ; i<len ; i++)
      arr[i] = Integer.parseInt(str.substring(i*2, 2));

    return new SwapValue(arr);
  }
}

