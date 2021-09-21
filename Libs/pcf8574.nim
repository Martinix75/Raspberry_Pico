import picostdlib/[gpio, i2c]
import picostdlib

const 
  pcf8574Ver = "0.1.0"
  on = true #da valutare se low o altro
  off = false #da valutare se high o altro..
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

proc byteWrite*(self: Pcf8574, dato:uint8 ) = #proc to write the byte 
  let dato = dato.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.addressDevice, dato, 1, true) #write the data on the i2c bus 

proc byteRead*(self:Pcf8574, dato: var array[1,uint8]) =
  let datox = dato[0].unsafeAddr
  discard readBlocking(self.blockk, self.addressDevice, datox, 1, false)

proc digitWrite*(self:Pcf8574,pin:uint8, value:bool) =
  if value == on:
    self.buffer = (self.buffer or pin) #go to act (turn on) the selected bit 
    byteWrite(self,self.buffer)
  elif value == off:
    self.buffer = (self.buffer and pin) #go to act (turn off) the selected bit 
    byteWrite(self,self.buffer)

proc digitRead*(self:Pcf8574, pin:uint8): bool =
  var buffRead = [uint8(0)]
  byteRead(self, buffRead)
  let valuePins = buffRead[0]
  let mask = not valuePins
  let valuePin = (mask and pin)
  #print("valore Pin: " & $valuePin)
  if pin == valuePin:
    result = on
  else:
    result =  off

when isMainModule:
  stdioInitAll()
  let expander = Pcf8574(addressDevice: 0x20, blockk: i2c0) #buffer: 0b00000000  initializes the object 
  setupGpio(led1, 25.Gpio,Out)
  const sda = 0.Gpio 
  const scl = 1.Gpio 
  const address = 0x20
  init(i2c0,10000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()

  #var buffer:uint8 = 0b00000000
  #byteWrite(expander, buffer)
  sleep(1000)

  while true:
    #[digitWrite(expander, p1, on) #turn on the bit "p1" 
    sleep(1500)
    digitWrite(expander, p4, on) #turn on the bit "p4" 
    sleep(1500)
    digitWrite(expander, p1, off) #turn off the bit "p1" 
    sleep(1500)
    digitWrite(expander, p4, off) #turn off the bit "p4" ]#
  
    var p3val = digitRead(expander, p3)
    #print("P3= " & $p3val)
    #sleep(200)
    if p3val == on:
      led1.put(High)
    else:
      led1.put(Low)

    sleep(100)
    
#[ in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc) 
add--> (hardware_i2c) ]#
