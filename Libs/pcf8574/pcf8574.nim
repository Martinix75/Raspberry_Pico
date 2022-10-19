#[
Driver for 8bit expander Pcf8574 write in Nim.
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6

author Andrea Martin (Martinix75)
https://github.com/Martinix75/Raspberry_Pico/tree/main/Libs/pcf8574
]#

## Module to manage the PCF8574.
## Allows you to read and write either individual bits, or whole bytes.

import picostdlib/[stdio, gpio, i2c, time]

from math import log2

const 
  pcf8574Ver* = "1.3.0"
  p0*: byte = 0b00000001 #create a bit mask 
  p1*: byte = 0b00000010
  p2*: byte = 0b00000100
  p3*: byte = 0b00001000
  p4*: byte = 0b00010000
  p5*: byte = 0b00100000
  p6*: byte = 0b01000000
  p7*: byte = 0b10000000

type 
  Pcf8574* = ref object #creates the pcf8574 object
    expAdd: uint8
    blockk: I2cInst
    buffer: byte

proc writeByte*(self: Pcf8574, data: byte ) = #proc to write the byte
  ## Write a whole byte (8 outings) on the PCF8574 register.
  ##
  runnableExamples:
    self.writeByte(0xAA)
  ## **Parameters:**
  ## - *data:* it is the Byte you want to write on the register.
  self.buffer = data #store data in self.buffer
  let dato = data.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.expAdd, dato, 1, false) #write the data on the i2c bus 

proc readByte*(self: Pcf8574, data: var array[1,uint8]) =
  ## Read the entry byte present that instant.
  ##
  runnableExamples:
    let exp = newExpander(blokk = i2c1, expAdd = 0x20)
    var readBuffer = [byte(0)]
    exp.readByte(readBuffer)
    print("Byte sul Expander: " & $readBuffer & '\n')
  ## **Parameters:**
  ## - *data:* byte array where the value received by the PFC8574 is stored.
  let datox = data[0].unsafeAddr
  discard readBlocking(self.blockk, self.expAdd, datox, 1, false)

proc writeBit*(self: Pcf8574, pin: uint8, value: bool) =
  ## Write a single byte on the exit (P0, P1 ..) desired.
  ##
  runnableExamples:
    self.readByte(pin=p0, value=on)
  ## **Parameters:**
  ## - *pin:* it is the pin on which you want to write the new value (p0..p7).
  ## - *value:* *on* = set exit high, *low* = set exit low.
  if value == on:
    self.buffer = byte(self.buffer or pin) #go to act (turn on) the selected bit 
    self.writeByte(self.buffer)
  elif value == off:
    let ctrl = self.buffer shr uint8(log2(float(pin))) #Calculate if it is odd (moving the bit chosen to position 0) 
    if (ctrl mod 2) != 0: #if it is odd then bit = 1 and goes off 
      self.buffer = (self.buffer xor pin) #go to act (turn off) the selected bit 
      self.writeByte(self.buffer)

proc readBit*(self: Pcf8574, pin: uint8): bool =
  ## Reads the value of a single bit in the PFC8574 register.
  ##
  runnableExamples:
    let bit0 = expander.readBit(p0)
    let bit7 = expander.readBit(p7)
  ## **Parameters:**
  ## - *pin:* read the single pin indicated (p0..p7).
  ## **Return:**
  ## bool
  var buff = [uint8(0)]
  self.readByte(buff)
  let valuePins = buff[0]
  #let mask = (valuePins xor 0b11111111)
  #let valuePin = (mask and pin)
  let valuePin = (valuePins and pin)
  #print("valore Pin: " & $valuePin)
  if pin == valuePin:
    result = true
  else:
    result =  false

proc setLow*(self: Pcf8574) = #set buffer 0x00 all 0
  ## It puts all the low outputs.
  ##
  runnableExamples:
    self.setLow()
  self.buffer = 0x00
  self.writeByte(self.buffer)

proc setHigh*(self: Pcf8574) = #set buffer 0xff all 1
  ## It puts all the high outputs.
  ##
  runnableExamples:
    self.setHigh()
  self.buffer = 0xff
  self.writeByte(self.buffer)

proc newExpander*(blokk: I2cInst, expAdd: uint8, buffer: uint8 = 0x00): Pcf8574 =
  result = Pcf8574(blockk: blokk, expAdd: expAdd, buffer: buffer)

when isMainModule:
  stdioInitAll()
  let exp = newExpander(blokk = i2c1, expAdd = 0x20)
  const sda = 2.Gpio 
  const scl = 3.Gpio 
  init(i2c1,10000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()

  let timeSl: uint32 = 100
  var superCar: uint8 = 0x01
  while true:
    for _ in countup(0,6):
      exp.writeByte(superCar)
      superCar = superCar shl 1
      sleep(timeSl)
    for _ in countup(0,6):
      exp.writeByte(superCar)
      superCar = superCar shr 1
      sleep(timeSl)

