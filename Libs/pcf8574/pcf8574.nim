import picostdlib/[stdio, gpio, i2c, time]

from math import log2

const 
  pcf8574Ver* = "1.1.0"
  p0*: uint8 = 0b00000001 #create a bit mask 
  p1*: uint8 = 0b00000010
  p2*: uint8 = 0b00000100
  p3*: uint8 = 0b00001000
  p4*: uint8 = 0b00010000
  p5*: uint8 = 0b00100000
  p6*: uint8 = 0b01000000
  p7*: uint8 = 0b10000000

type 
  Pcf8574* = ref object #creates the pcf8574 object
    expAdd: uint8
    blockk: I2cInst
    buffer: uint8

proc writeByte*(self: Pcf8574, dato: uint8 ) = #proc to write the byte 
  let dato = dato.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.expAdd, dato, 1, true) #write the data on the i2c bus 

proc readByte*(self: Pcf8574, dato: var array[1,uint8]) =
  let datox = dato[0].unsafeAddr
  discard readBlocking(self.blockk, self.expAdd, datox, 1, false)

proc writeBit*(self: Pcf8574, pin: uint8, value: bool) =
  if value == on:
    self.buffer = (self.buffer or pin) #go to act (turn on) the selected bit 
    self.writeByte(self.buffer)
  elif value == off:
    let ctrl = self.buffer shr uint8(log2(float(pin))) #Calculate if it is odd (moving the bit chosen to position 0) 
    if (ctrl mod 2) != 0: #if it is odd then bit = 1 and goes off 
      self.buffer = (self.buffer xor pin) #go to act (turn off) the selected bit 
      self.writeByte(self.buffer)

proc readBit*(self: Pcf8574, pin: uint8): bool =
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
  self.buffer = 0x00
  self.writeByte(self.buffer)

proc setHigh*(self: Pcf8574) = #set buffer 0xff all 1
  self.buffer = 0xff
  self.writeByte(self.buffer)

proc initExpander*(blokk: I2cInst, expAdd: uint8, buffer: uint8 = 0x00): Pcf8574 =
  result = Pcf8574(blockk: blokk, expAdd: expAdd, buffer: buffer)

when isMainModule:
  stdioInitAll()
  let exp = initExpander(blokk = i2c1, expAdd = 0x20)
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

#[ in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc) 
add--> (hardware_i2c) ]#
