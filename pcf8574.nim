import picostdlib/[gpio, i2c]
import picostdlib

const 
  pcf8574Ver* = "0.2.2"
  on = true
  off = false
  p0: uint8 = 0b00000001 #create a bit mask 
  p1: uint8 = 0b00000010
  p2: uint8 = 0b00000100
  p3: uint8 = 0b00001000
  p4: uint8 = 0b00010000
  p5: uint8 = 0b00100000
  p6: uint8 = 0b01000000
  p7: uint8 = 0b10000000

type 
  Pcf8574* = ref object #creates the pcf8574 object
    addressDevice: uint8
    blockk: I2cInst
    buffer: uint8

proc writeByte*(self: Pcf8574, dato: uint8 ) = #proc to write the byte 
  let dato = dato.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.addressDevice, dato, 1, true) #write the data on the i2c bus 

proc readByte*(self: Pcf8574, dato: var array[1,uint8]) =
  let datox = dato[0].unsafeAddr
  discard readBlocking(self.blockk, self.addressDevice, datox, 1, false)

proc writeBit*(self: Pcf8574, pin: uint8, value: bool) =
  if value == on:
    self.buffer = (self.buffer or pin) #go to act (turn on) the selected bit 
    self.writeByte(self.buffer)
  elif value == off:
    self.buffer = (self.buffer xor pin) #go to act (turn off) the selected bit 
    self.writeByte(self.buffer)

proc readBit*(self: Pcf8574, pin: uint8): bool =
  var buff = [uint8(0)]
  readByte(self, buff)
  let valuePins = buff[0]
  let mask = (valuePins xor 0b11111111)
  let valuePin = (mask and pin)
  print("valore Pin: " & $valuePin)
  if pin == valuePin:
    result = on
  else:
    result =  off

proc setLow*(self: Pcf8574) = #set buffer 0x00 all 0
  self.writeByte(0x00)

proc setHigh*(self: Pcf8574) = #set buffer 0xff all 1
  self.writeByte(0xff)

when isMainModule:
  stdioInitAll()
  let exp1 = Pcf8574(addressDevice: 0x20, blockk: i2c1)#, buffer: 0x00 initializes the object if if necessary

  const sda = 2.Gpio 
  const scl = 3.Gpio 
  const address = 0x20
  init(i2c1,10000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()
  sleep(1000)

  while true:
    exp1.setHigh() #set all led on
    sleep(1000)
    exp1.writeBit(p1, on) #turn on the bit "p1" 
    sleep(800)
    exp1.writeBit(p4, on) #turn on the bit "p4" 
    sleep(1000)
    exp1.writeBit(p1, off) #turn off the bit "p1" 
    sleep(1000)
    exp1.writeBit(p4, off) #turn off the bit "p4" ]#
    sleep(500)
    #exp1.writeByte(0xaa) #alternating leds 
    #sleep(1000)
    #exp1.setLow() #set all led off
    #sleep(1000)
    #var lettura = [uint8(0)] #create a variable uint8 = 0
    #exp1.readByte(lettura) #read all byte on device 
    #print("Leggo sul expander: " & $lettura[0]) #stampa tutto il byte
    #[var p3val = exp1.digitRead(p3) #assigns p3val only the value of bit p3 (bool) 
    print("P3= " & $p3val) #prints the value of bit p3
    sleep(200)
    if p3val == true:
      exp1.writeBit(p0, on)
    else:
      exp1writeBit(p0, off)]#

    #sleep(1900)
    
#[ in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc) 
add--> (hardware_i2c) ]#
