import picostdlib/[stdio, gpio, i2c, time]
import display1602
#update for picostdlib 0.2.7
stdioInitAll()
const
  sda = 2.Gpio 
  scl = 3.Gpio 
i2c1.init(100000)
sda.setFunction(I2C); sda.pullUp()
scl.setFunction(I2C); scl.pullUp()

let lcd = newDisplay(i2c = i2c1, lcdAdd = 0x27, numColum = 16, numLines = 2)
#various printing tests
let pos = [5,15,3,11,0,7,9,2,4,10]
while true:
  lcd.clear() #cleans the display
  lcd.moveTo(0,0)
  lcd.centerString("move char ->") #write the text in the center of the display 
  lcd.moveTo(0,1)
  lcd.shiftChar('>') #move the character along the entire line 
  sleep(1000)
  lcd.moveTo(0,0)
  lcd.clear()
  lcd.centerString("Clear 1 Line:") #write the text in the center of the display 
  lcd.moveTo(0,1) #move the cursor to line 1 (second line) 
  for x in pos:
    lcd.clearLine() #clears the line where the cursor is 
    lcd.moveTo(uint8(x), 1) #moves the cursor on line 1 (second line) 
    lcd.putChar('@') #write the character in the position indicated above 
    sleep(800)
