import picostdlib/[gpio, i2c]
import picostdlib
import display1602

stdioInitAll()
const
  sda = 2.Gpio 
  scl = 3.Gpio 
i2c1.init(100000)
sda.setFunction(I2C); sda.pullUp()
scl.setFunction(I2C); scl.pullUp()

let lcd = init(i2c = i2c1, lcdAdd = 0x27, numColum = 16, numLines = 2)
#various printing tests

while true:
  lcd.clear() #cleans the display
  lcd.moveTo(0,0) #move the cursor into position (colum, line)
  lcd.centerString("Version Lib:") #prints the string in the center of the display
  lcd.moveTo(0,1) #move the cursor in the second line
  lcd.centerString(disp1602Ver)
  sleep(1500)
  lcd.clear()
  lcd.moveTo(0,0)
  lcd.putStr("dir = false") #write string (without handling) 
  lcd.moveTo(0,1)
  lcd.shiftString(disp1602Ver, dir = false) #moves from left to right
  sleep(3500)
  lcd.clear()
  lcd.moveTo(0,0)
  lcd.putStr("dir = true")
  lcd.moveTo(0,1)
  lcd.shiftString(disp1602Ver, dir = true) #moves from right to left  (default)
  sleep(3500)
  lcd.clear()
  lcd.moveTo(0,0)
  lcd.putStr("cross = false")
  lcd.moveTo(0,1)
  lcd.shiftString(disp1602Ver, cross = false) #not across the display (default)
  sleep(3500)
  lcd.clear()
  lcd.moveTo(0,0)
  lcd.putStr("cross = true")
  lcd.moveTo(0,1)
  lcd.shiftString(disp1602Ver, cross = true) #across the display
  sleep(3500)
  lcd.clear()
  lcd.moveTo(0,0)
  lcd.putStr("effect = 0")
  lcd.moveTo(0,1)
  lcd.shiftString(disp1602Ver, cross = true, effect = 0) # the string exits the display (default)
  sleep(3500)
  lcd.clear()
  lcd.moveTo(0,0)
  lcd.putStr("effect = 1")
  lcd.moveTo(0,1)
  lcd.shiftString(disp1602Ver, cross = true, effect = 1) # the string stops at the edge of the display 
  sleep(3500) 