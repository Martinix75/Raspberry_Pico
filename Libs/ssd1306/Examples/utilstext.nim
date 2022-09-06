import picostdlib/[stdio, gpio, time, i2c]
import ssd1306
import utilssd1306

setupI2c(blokk=i2c1,psda=18.Gpio, pscl=19.Gpio, freq=100_000)
let dsp = newSsd1306I2C(i2c=i2c1, lcdAdd=0x3C, width=128, height=64)

dsp.clear(0)
## clear() clean the screnn il argument = 0 all pixeloff; if =1 all pixel on

dsp.centerText(text="Utils Ver: " & utilSsd1306Ver, y=5, color=1, charType="std")
## centerText() writes the text directly to the center of the display
## arguments:
## text = it is the writing string
## y = position on the Y axis of the beginning of the text
## color = set color of the text (0=pixel off, 1=pixel on)
## charType = chooses the type of character to be used on the text

dsp.shiftTextDx(text="Shift Dx>", x=0,y=15, speed=2, hidden=false, charType="std")
## shiftTextDx() move the text from left to right
## arguments:
## text = it is the writing string
## x = position on the X axis of the beginning of the text
## y = position on the Y axis of the beginning of the text
## speed = it is the speed with which the text moves on the display
## hiden = if hidden = false keeps the text on the display, otherwise it cancels it at the end
## charType = chooses the type of character to be used on the text

dsp.shiftTextSx(text="<Shift SX", x=110, y=25, speed=3, hidden=false, charType="std")
## shiftTextDx() move the text from right to left
## arguments:
## text = it is the writing string
## x = position on the X axis of the beginning of the text
## y = position on the Y axis of the beginning of the text
## speed = it is the speed with which the text moves on the display
## hiden = if hidden = false keeps the text on the display, otherwise it cancels it at the end
## charType = chooses the type of character to be used on the text

dsp.crossText(text="Cross Txt", y=40, speed=3, hidden=false, charType="std")
## crossText() The text crosses the display from left to right 
## and comes out of the display (character by character)
## arguments:
## y = position on the Y axis of the beginning of the text
## speed = it is the speed with which the text moves on the display
## hiden = if hidden = false keeps the text on the display, otherwise it cancels it at the end
## charType = chooses the type of character to be used on the text

dsp.shiftCenterText(text="Shift Center", y=40, speed=3, charType="std")
## shiftCenterText() move the text from right to the display center (only from left for now)
## arguments:
## y = position on the Y axis of the beginning of the text
## speed = it is the speed with which the text moves on the display
## charType = chooses the type of character to be used on the text

dsp.centerText(text="Test End Ok!", y=55, color=1, charType="test")
dsp.show()
print("---- Exit ok!! -------")
