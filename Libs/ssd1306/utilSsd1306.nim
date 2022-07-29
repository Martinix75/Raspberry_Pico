import ssd1306
#import picostdlib/[time]
import picostdlib/[stdio, gpio, time, i2c] #x test
stdioInitAll() #per test
const
  utilSsd1306Ver* = "0.1.1"
  

proc shiftTextDx*(self: SSD1306I2C;  text: string; x, y: int; time=0, dx=false; ghost=false) =
  var step: int
  if dx == false:
    print("LEN: " & $(len(text)))
    step = self.fbWidth-(len(text)*5)
  else:
    step = self.fbWidth
  for index in 0..step-2:
    print("Step: " & $step & " index: " & $index)
    self.text(text, index+x, y, 1)
    sleep(uint32(time))
    self.show()
    if ghost == false and index != step-2:
      self.text(text, index+x, y, 0)
    
proc shiftTextSx*(self: SSD1306I2C;  text: string; x, y: int; time=0, sx=false; ghost=false) =
  var step: int
  if sx == false:
    step = self.fbWidth
  else:
    step = self.fbWidth+(len(text)*5)
  for index in 0..x-1:
    print("Step: " & $step & " index: " & $index)
    self.text(text, x-index, y, 1)
    sleep(uint32(time))
    self.show()
    if ghost == false and index != x-1:
      self.text(text, x-index, y, 0)

proc centerText*(self: SSD1306I2C; text: string; y: int; color=1) = 
  let
    dispCenter = (self.fbWidth/2)-1
    lenText = len(text)*5
    setX: int = int(dispCenter - (lenText / 2))
  self.text(text, setX, y, color)
  self.show()











