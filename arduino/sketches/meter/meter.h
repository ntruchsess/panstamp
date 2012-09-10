/**
 * meter.h
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
 * panStamp is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with panStamp; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 
 * USA
 * 
 * Author: Daniel Berenguer
 * Creation date: 09/08/2012
 */
 
#include "channel.h"
#include "regtable.h"
#include "panstamp.h"

#ifndef _METER_H
#define _METER_H

/**
 * EEPROM addresses
 */
 
#define CONFIG_CHANNEL_SIZE      6
#define EEPROM_CONFIG_CHANNEL0   EEPROM_FIRST_CUSTOM
#define EEPROM_CONFIG_CHANNEL1   EEPROM_CONFIG_CHANNEL0 + CONFIG_CHANNEL_SIZE
#define EEPROM_CONFIG_CHANNEL2   EEPROM_CONFIG_CHANNEL1 + CONFIG_CHANNEL_SIZE
#define EEPROM_CONFIG_CHANNEL3   EEPROM_CONFIG_CHANNEL2 + CONFIG_CHANNEL_SIZE
#define EEPROM_CONFIG_CHANNEL4   EEPROM_CONFIG_CHANNEL3 + CONFIG_CHANNEL_SIZE
#define EEPROM_CONFIG_CHANNEL5   EEPROM_CONFIG_CHANNEL4 + CONFIG_CHANNEL_SIZE
#define CONFIG_PULSEINPL_SIZE    6
#define EEPROM_CONFIG_PULSE0     EEPROM_CONFIG_CHANNEL5 + CONFIG_CHANNEL_SIZE
#define EEPROM_CONFIG_PULSE1     EEPROM_CONFIG_PULSE0 + CONFIG_PULSEINPL_SIZE
#define EEPROM_CONFIG_PULSE2     EEPROM_CONFIG_PULSE1 + CONFIG_PULSEINPL_SIZE

/**
 * Pin definitions
 */
#define PIN_ACVOLTAGE    0    // Arduino analog pin 0

/**
 * Time 1 interval
 */
#define TIMER1_TICK_PERIOD_US    1000000  // Timer1 tick = 1 sec

/**
 * Timer 1 ticks
 */
unsigned int t1Ticks = 0;

/**
 * Wireless transmission interval (seconds)
 */
unsigned int txInterval;

/**
 * If true, send power data wirelessly
 */
bool transmit = false;

/**
 * Vcc in mV
 */
unsigned int voltageSupply = 3260;

/**
 * AC channels
 */
CHANNEL channels[6];

/**
 * Interrupt masks
 */
#define PCINTMASK    0xE0  // PD[5:7]

/**
 * PCINT macros
 */
#define pcEnableInterrupt()     PCICR = 0x04    // Enable Pin Change interrupt on Port D
#define pcDisableInterrupt()    PCICR = 0x00    // Disable Pin Change interrupts

/**
 * Pin Change Interrupt flag
 */
volatile boolean pcIRQ = false;

/**
 * Counters
 */
uint8_t counterPin[] = {5, 6, 7};                            // Counter pins (Atmega port bits)
volatile uint8_t *counterPort[] = {&PIND, &PIND, &PIND};     // Counter ports (Atmega port)
unsigned long counters[] = {0, 0, 0};                        // Initial counter values
int lastStateCount[] = {-1, -1, -1};                         // Initial pin states

#endif
