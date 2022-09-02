import picostdlib/[stdio, gpio, i2c]
import display1602
#upade for picostdlib 0.2.7
stdioInitAll()
const
  sda = 2.Gpio 
  scl = 3.Gpio 
i2c1.init(100000)
sda.setFunction(I2C); sda.pullUp()
scl.setFunction(I2C); scl.pullUp()

let lcd = newDisplay(i2c = i2c1, lcdAdd = 0x27, numColum = 16, numLines = 2)
#castom char:

let crown = [0x00,0x11,0x15,0x15,0x1f,0x1b,0x1f,0x00] #custom char 5x8
#lcd.init() #sequence to initialize the display
lcd.clear() #cleans the display
lcd.customChar(0, crown) #writes the custom character in memory (but does not print it!!)
lcd.putChar(char(0)) #now the character "0" is printed!!!
lcd.centerString("W Nim") #use "centerstring" to center the text on the display
lcd.moveTo(15,0) #moves the cursor to position 15
lcd.putChar(char(0)) #reprints the "0" character in the new position
lcd.moveTo(0,1) #we go to the second row, column 0
lcd.putString("Version: " & disp1602Ver) #we print the library version "in the normal way"
