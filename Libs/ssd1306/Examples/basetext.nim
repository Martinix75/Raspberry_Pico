import picostdlib/[stdio, gpio, time, i2c]
import ssd1306

setupI2c(blokk=i2c1,psda=18.Gpio, pscl=19.Gpio, freq=100_000)
let dsp = newSsd1306I2C(i2c=i2c1, lcdAdd=0x3C, width=128, height=64)
dsp.clear(0)
dsp.text(text="FrameBuf Ver: " & frameBufferVer, x=10, y=5, color=1, charType="std", size=1)
dsp.text(text="ssd1306Ver: " & ssd1306Ver, x = 15, y= 25, color= 1, charType="test", size=1)
dsp.text(text="Driver Write in NIM", x = 6, y= 45, color= 1, charType="test", size=1)
## text() writes a string on the display
## arguments:
## text = It is the writing string
## x = position on the X axis of the beginning of the text
## y = position on the Y axis of the beginning of the text
## color = set color of the text (0=pixel off, 1=pixel on)
## charType = chooses the type of character to be used on the text
## size = change the size of the text (only integer numbers)

dsp.show()
## show() show everything you wrote in the memory of the display by bringing it to the video
 
