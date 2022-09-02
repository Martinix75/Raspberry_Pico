#readbite piostdli => 0.2.7
import picostdlib/[stdio, gpio, i2c, time]
import pcf8574

stdioInitAll()
const
  sda = 2.Gpio 
  scl = 3.Gpio 
i2c1.init(10000)
sda.setFunction(I2c); sda.pullUp()
scl.setFunction(I2C); scl.pullUp()

DefaultLedPin.init() #init led on-board
DefaultLedPin.setDir(Out) #set out

proc blink(val:uint8) =
  discard
  for _ in countup(uint8(1),val):
    DefaultLedPin.put(High)
    sleep(50)
    DefaultLedPin.put(Low)
    sleep(450)

let exp = newExpander(blokk = i2c1, expAdd = 0x20)
#let time: uint32 = 800
var readBuffer = [uint8(0)] #make array uint8 (ini = 0)
while true:
  # ==== Read Byte ====
  
  exp.readByte(readBuffer) #read the buffer expander and save in array readBuffer 
  var valBuffer = not readBuffer[0] #invert the buffer (ex 0xff --> 0, 0xfe --> 0x01)
  print("Byte sul Expander: " & $valBuffer & '\n') #print on usb
  if valBuffer == 1: #if p0 = low --> make 1 blink
    blink(valBuffer)
  elif valBuffer == 2:#if p1 = low --> make 2 blink etc...
    blink(valBuffer)
  elif valBuffer == 4:
    blink(valBuffer)
  elif valBuffer == 8:
    blink(valBuffer)
  else:
    blink(3)
  sleep(2000)

  #For this example I only used the first 4 bits (P0, P1, P2, P3), 
  #but it is obvious that then you all use them because you read the entire byte! 
