#[
Framebuffer generic for display written in Nim.
port from framebuffer.py (Damien P. George and Tony DiCola)
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6

author Andrea Martin (Martinix75)
https://github.com/Martinix75/Raspberry_Pico/tree/main/Libs/ssd1306
]#

import sh1106
import options
#import picostdlib/[time]
#import picostdlib/[stdio, gpio, time, i2c] #x test
#stdioInitAll() #per test
const
  utilSsh1106* = "0.1.0"
  
proc centerText*(self: SH1106I2C; text: string; y: int; color=1, charType="std") =
  let
    dispCenter = (self.fbWidth/2)-1
    lenText = len(text)*5
    setX: int = int(dispCenter - (lenText / 2))-1
  self.textFb(text, setX, y, color, charType=charType, direct=true)
  self.registerUpDate(yZero=y, yOne=some(y+7))
  self.show()

proc shiftTextDx*(self: SH1106I2C; text: string; x, y: int; speed=2, hidden=false, charType="std") =
  let step = int(110-(len(text)*5))
  for i in countup(0, step, speed):
    self.textFb(text, i+x, y, charType=charType, color=1, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
    self.show()
    self.textFb(text, i+x, y, charType=charType, color=0, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
  self.textFb(text, step, y, charType=charType, color=1, direct=false)
  self.registerUpDate(yZero=y, yOne=some(y+7))
  self.show()
  if hidden == true:
    self.textFb(text, step, y, charType=charType, color=0, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
    self.show()

proc shiftTextSx*(self: SH1106I2C; text: string; x, y: int; speed=2, hidden=false, charType="std") =
  self.loadCharsFb(charType)# deve tirare su (aggiornare) i font ogni volta che si invoca test
  for step in countdown(x, 0, speed):
    self.textFb(text, step, y, 1, charType=charType, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
    self.show()
    self.textFb(text, step, y, 0, charType=charType, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
  self.textFb(text, 0, y, 1, charType=charType, direct=false)
  self.registerUpDate(yZero=y, yOne=some(y+7))
  self.show()
  if hidden == true:
    self.textFb(text, 0, y, 0, charType=charType, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
    self.show()
    #print("StepDw: " & $(step+speed) )

proc crossText*(self: SH1106I2C; text: string; y:int; speed=2, hidden=false, charType="std") =
  self.loadCharsFb(charType)# deve tirare su (aggiornare) i font ogni volta che si invoca test
  for step in countup(0, 128, 2):
    #print("StepUP: " & $step)
    self.textFb(text, step, y, 1, charType=charType, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
    self.show()
    if step != 128 or hidden == true:
      self.textFb(text, step, y, 0, charType=charType, direct=false)
      self.registerUpDate(yZero=y, yOne=some(y+7))

proc shiftCenterText*(self: SH1106I2C; text: string; y: int; speed=2; charType="std") =
  let
    dispCenter = (self.fbWidth/2)-1
    lenText = len(text)*5
    setX: int = int(dispCenter - (lenText / 2))
  for i in countUp(0, setX, speed):
    self.textFb(text, i, y, 1, charType=charType, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
    self.show()
    self.textFb(text, i, y, 0, charType=charType, direct=false)
    self.registerUpDate(yZero=y, yOne=some(y+7))
  self.textFb(text, setX, y, 1, charType=charType, direct=false)
  self.registerUpDate(yZero=y, yOne=some(y+7))

proc screenSaver*(self: SH1106I2C) =
  echo("scrensaver")
  self.imageFb(x=3, y=3, color=1, nameImg="iom1")
