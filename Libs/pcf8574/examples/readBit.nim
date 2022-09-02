#update for picostdlib >= 0.2.7
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
let timeSl: uint32 = 800
var readBuffer = [uint8(0)] #make array uint8 (ini = 0; 1 element)
var bit1, bit2: bool

while true:
  # ==== Read bit ====
  
  bit1 = exp.readBit(p1) #read bit "p1" (true or false)
  print("Il valore di P1 è: " & $bit1 & '\n') 
  bit2 = exp.readBit(p2) #read bit "p2" (true or false)
  print("Il valore di P2 è: " & $bit2 & '\n') 
  if bit1 == false and bit2 == false: #if bit e bit2 = false..
    blink(4) #make 4 blink!
  elif bit1 == false: #if only bit1 = false..
    blink(1) #make 1 blink!
  elif bit2 == false: #if only pit2 = false..
    blink(2) #make 2 blink!
  else:
    blink(0)
  sleep(2000)

  #For this example I only used the first 4 bits (P0, P1, P2, P3), 
  #but it is obvious that then you all use them because you read the entire byte! 
