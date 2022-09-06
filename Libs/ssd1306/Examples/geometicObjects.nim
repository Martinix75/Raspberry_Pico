import picostdlib/[stdio, gpio, time, i2c]
import ssd1306

setupI2c(blokk=i2c1,psda=18.Gpio, pscl=19.Gpio, freq=100_000)
let dsp = newSsd1306I2C(i2c=i2c1, lcdAdd=0x3C, width=128, height=64)
dsp.clear(0)
## clear() clean the screen if argument = 0 all pixell off if =1 all pixel on
dsp.rect( x=5 ,y=5, width=30, height=62, color=1, fill=false)
## rect() draw a rectangle on the screen
## arguments:
## x = position on the X axis of the high left corner
## y = position on the Y axis of the high left corner
## width = length of the side on the X axis
## height = length of the side on the Y axis
## color = set rectangle color (only black or white 1 or 0)
## fill = filling of the rectangle (false=pixel off, ture=pixel on)

dsp. circle(centerX = 90, centerY=30, radius=20, color=1)
## circle() draw a circle on the screen
## arguments:
## centerX = position of the center of the circle on the X axis
## centerY = position of the center of the circle on the Y axis
## radius = set the ray of the circle
## color = set circle color (false=pixel off, ture=pixel on)

dsp.hline(x=65, y=60, width=45, color=1)
## hline() draw a straight line on the X axis
## arguments:
## x = position on the X axis of the starting point of the straight line
## y = position on the Y axis of the starting point of the straight line
## color = sethline color (false=pixel off, ture=pixel on)

dsp. vline(x=50, y=5, height= 45, color=1)
## vline() draw a straight line on the Y axis
## arguments:
## x = position on the X axis of the starting point of the straight line
## y = position on the Y axis of the starting point of the straight line
## color = sethline color (false=pixel off, ture=pixel on)

dsp.line(xStr=60, yStr=5, xEnd=120, yEnd=50, color=1)
dsp.line(xStr=120, yStr=5, xEnd=60, yEnd=50, color=1)
## line() draw a line on the screen giving the beginning and end coordinates
## arguments:
## xStr = position on the X axis of the starting point of the line
## yStr = position on the Y axis of the starting point of the line
## xEnd = position on the X axis of the point of the end of the line
## yEnd = position on the Y axis of the point of the end of the line

dsp.show()
## show() show everything you wrote in the memory of the display by bringing it to the video
