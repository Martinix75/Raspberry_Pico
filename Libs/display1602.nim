from sequtils import toSeq
from math import round
import picostdlib/[gpio, i2c]
import picostdlib
import picousb


const 
  disp1602Ver* = "0.2.1"
  lcdClr = 0x01
  lcdHome = 0x02
  lcdEntryMode = 0x04
  lcdEntryInc = 0x02
  lcdEntryShift = 0x01
  lcdOnCtrl = 0x08
  lcdOnDisplay = 0x04
  lcdOnCursor = 0x02
  lcdOnBlink = 0x01
  lcdMove = 0x10
  lcdMoveDisp = 0x08
  lcdMoveRight = 0x04
  lcdFunction = 0x20
  lcdFunction8Bit = 0x10
  lcdFunction2Lines = 0x08
  lcdFunction10Dots = 0x04
  lcdFunctionReset = 0x30
  lcdCgRam = 0x40
  lcdDdRam = 0x80
  lcdShiftBackLight = 0x03
  lcdShiftData = 0x04
  lcdMaskE = 0x04
  lcdMaskRs = 0x01
  lcdMaskRw = 0x02
var 
  lcdBackLight:uint8 = 0x01
  blen: uint8 = 1 #1 = lcd on 0=off
  impiledNewLine = 0
  fd: uint8

  
type 
  Lcd* = ref object 
    i2c: I2cInst
    lcdAdd: uint8
    numLines, numColum: uint8
    cursorX, cursorY: uint8

proc lcdSendByte(self: Lcd, valore: uint8)
proc lcdWriteWord(self: Lcd, command: uint8)
proc lcdSendCommandInit(self: Lcd, comm: uint8)
proc lcdSendCommand(self: Lcd, comm: uint8)
proc lcdWriteData(self: Lcd, data: uint8)
proc lcdShiftRight(self: Lcd, seqx: seq[char], speed: uint16)
proc lcdShiftLeft(self: Lcd, seqx: seq[char], speed: uint16)
proc lcdCleraLine(self: Lcd)
proc lcdFormatStr(self: Lcd, strg: string): seq[char]
proc moveTo*(self: Lcd, curx, cury: uint8)
proc putChar*(self: Lcd, charx: char)
proc shiftChar*(self: Lcd, charx: char, speed: uint16 = 400, dir = true)

proc lcdSendByte(self: Lcd, valore: uint8) =
  let addVal = valore.unsafeAddr
  let lenn = csize_t(1)#valore.len*seizeof(valore))
  writeBlocking(self.i2c, self.lcdAdd, addVal, lenn, true)

proc lcdWriteWord(self: Lcd, command: uint8) =
  var temp = command
  if blen == 1:
    temp = temp or 0x08
  else:
    temp = temp and 0xf7
  #print("WriteWord: " & $temp & '\n')
  self.lcdSendByte(temp)

proc lcdSendCommandInit(self: Lcd, comm: uint8) = #ok tramette correto l'init!!
  var buf: uint8
  buf = comm and 0xf0
  buf = buf or 0x04
  self.lcdWriteWord(buf)
  #print("CommandIni1: " & $buf & '\n')
  sleep(2)
  buf = buf and 0xfb
  self.lcdWriteWord(buf)
  #print("CommandIni2: " & $buf & '\n')

proc lcdSendCommand(self: Lcd, comm: uint8) =  #ok funziona!!!
  var buf = ((lcdBackLight shl lcdShiftBackLight) or (((comm shr 0x04) and 0x0f) shl lcdShiftData))
  self.lcdWriteWord(buf or lcdMaskE)
  #print("Command1: " & $(buf or lcdMaskE) & '\n')
  self.lcdWriteWord(buf)
  #print("Command2: " & $buf & '\n')
  buf = ((lcdBackLight shl lcdShiftBackLight) or (( comm and 0x0f) shl lcdShiftData))
  self.lcdWriteWord(buf or lcdMaskE)
  #print("Command3: " & $(buf or lcdMaskE) & '\n')
  self.lcdWriteWord(buf)
  #print("Command4: " & $buf & '\n')
  if comm <= 3:
    sleep(5)

proc lcdWriteData(self: Lcd, data: uint8) =
  var buf = (lcdMaskRs or (lcdBackLight shl lcdShiftBackLight) or (((data shr 0x04) and 0x0f) shl lcdShiftData))
  self.lcdWriteWord(buf or lcdMaskE)
  self.lcdWriteWord(buf)
  buf = (lcdMaskRs or (lcdBackLight shl lcdShiftBackLight) or ((data and 0x0f) shl lcdShiftData))
  self.lcdWriteWord(buf or lcdMaskE)
  self.lcdWriteWord(buf)

proc moveTo*(self: Lcd, curx, cury: uint8) =
  self.cursorX = curx
  self.cursorY = cury
  var addrx = self.cursorX and 0x3f
  if (self.cursorY and 0x01) == uint8(1):
    addrx = addrx + 0x40
  if (self.cursorY and 0x02) == uint8(1):
    addrx = addrx + self.numColum
  self.lcdSendCommand(lcdDdRam or addrx)

proc putChar*(self: Lcd, charx: char) =
  if charx == '\n':
    if impiledNewLine == 0:
      discard
    else:
      self.cursorX = self.numColum
  else:
    self.lcdWriteData(uint8(ord(charx)))
    self.cursorX = self.cursorX + 1
  if self.cursorX >= self.numColum:
    self.cursorX = 0
    self.cursorY = self.cursorY + 1
    if charx != '\n':
      impiledNewLine = 0
  if self.cursorY >= self.numLines:
    self.cursorY = 0
  self.moveTo(curx = self.cursorX, cury = self.cursorY)

proc shiftChar*(self: Lcd, charx: char, speed: uint16 = 400, dir = true) =
  if dir == true:
    for _ in countup(0, 16):
      self.lcdWriteData(uint8(ord(charx)))
      sleep(speed)
      self.moveTo(curx = self.cursorX, cury = self.cursorY)
      self.lcdWriteData(uint8(ord(' ')))
      self.cursorX = self.cursorX + 1
      self.moveTo(curx = self.cursorX, cury = self.cursorY)
  else:
    self.moveTo(curx = 16, cury = self.cursorY)
    for _ in countdown(16, 0):
      self.lcdWriteData(uint8(ord(charx)))
      sleep(speed)
      self.moveTo(curx = self.cursorX, cury = self.cursorY)
      self.lcdWriteData(uint8(ord(' ')))
      self.cursorX = self.cursorX - 1
      self.moveTo(curx = self.cursorX, cury = self.cursorY)

proc lcdCleraLine(self: Lcd) =
  for _ in uint8(0)..self.numColum:
    self.moveTo(curx = 0, cury = self.cursorY)
    self.lcdWriteData(uint8(ord(' ')))
    self.cursorX = self.cursorX + 1
    self.moveTo(curx = self.cursorX, cury = self.cursorY)
    

proc shiftString*(self: Lcd, strg: string, speed: uint16 = 400, dir = true) =
  #var seqChr:seq[char]
  var fstring: string
  if dir == true:
    for charx in 0..len(strg)-1:
      fstring.add(strg[charx])
      var pippo = self.lcdFormatStr(fstring)
      self.lcdShiftLeft(pippo, speed)
  else:
    for charx in 1..len(strg):
      fstring.add(strg[^charx])
      var pippo = self.lcdFormatStr(fstring)
      self.lcdShiftRight(pippo, speed)

proc lcdFormatStr(self: Lcd, strg: string): seq[char] =
  result = toSeq(strg)
  let lennseq = uint8(len(result))
  if lennseq >= self.numColum:
    result.delete(0)

proc lcdShiftRight(self: Lcd, seqx: seq[char], speed: uint16) =
  self.lcdCleraLine()
  self.cursorX = uint8(len(seqx) - 1)
  self.moveTo(self.cursorX, self.cursorY)
  #print("sposto..." & '\n')
  for charx in seqx:
    self.lcdWriteData(uint8(ord(charx)))
    self.cursorX = self.cursorX - 1
    self.moveTo(curx = self.cursorX, cury = self.cursorY)
  sleep(speed)

proc lcdShiftLeft(self: Lcd, seqx: seq[char], speed: uint16) =
  self.lcdCleraLine()
  self.cursorX = self.numColum - uint8(len(seqx) + 1)
  self.moveTo(self.cursorX, self.cursorY)
  for charx in seqx:
    self.lcdWriteData(uint8(ord(charx)))
    self.cursorX = self.cursorX + 1
    self.moveTo(curx = self.cursorX, cury = self.cursorY)
  sleep(speed)


    #[for _ in 0..16:#len(tt):
      self.cursorX =  0
      self.moveTo(curx = self.cursorX, cury = self.cursorY)
      self.lcdWriteData(uint8(ord(' ')))
      self.cursorX = self.cursorX + 1
      self.moveTo(curx = self.cursorX, cury = self.cursorY)
    self.cursorX  = uint8(len(tt))-1
    self.moveTo(curx = self.cursorX, cury = self.cursorY)
    #sleep(300)
    #self.cursorX = uint8(len(tt)-1)
    for y in tt:
      #self.cursorX = uint8(len(tt))
      self.lcdWriteData(uint8(ord(y)))
      self.cursorX = self.cursorX - 1
      self.moveTo(curx = self.cursorX, cury = self.cursorY)
    sleep(speed)]#

proc putStr*(self: Lcd, strg: string) =
  let lenstrg = uint8(len(strg))
  if lenstrg <= self.numColum:# da mettere <= ;intest >
    for charx in strg:
      self.putChar(charx)
      #sleep(5)
  else:
    self.shiftString(strg)

proc centerString*(self: Lcd, charx: string) =
  let numColum = uint8(self.numColum div 2)
  let lenStr = uint8(len(charx))
  let division = float((lenStr div 2))
  let round = uint8(round(division))
  let posCur: uint8 = numColum - round
  self.moveTo(curx = posCur, cury = self.cursorY)
  self.putStr(charx)

proc displayOn*(self: Lcd) =
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay)

proc displayOff*(self: Lcd) =
  self.lcdSendCommand(lcdOnCtrl)

proc showCursor*(self: Lcd) =
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay or lcdOnCursor)

proc hideCursor*(self: Lcd) =
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay)

proc blinkCursorOn*(self: Lcd) =
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay or lcdOnCursor or lcdOnBlink)

proc blinkCursorOff*(self: Lcd) = 
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay or lcdOnCursor)

proc backLightOn*(self: Lcd) =
  lcdBackLight = 1
  self.lcdWriteWord(1 shl lcdShiftBackLight)

proc backLightOff*(self: Lcd) =
  lcdBackLight = 0
  self.lcdWriteWord(0)

proc clear*(self: Lcd) = 
  self.lcdSendCommand(lcdClr)
  self.lcdSendCommand(lcdHome)
  self.cursorX = 0 
  self.cursorY = 0

proc init*(self: Lcd) =
  self.lcdSendCommandInit(lcdFunctionReset)
  sleep(5)
  self.lcdSendCommandInit(lcdFunctionReset)
  sleep(5)
  self.lcdSendCommandInit(lcdFunctionReset)
  sleep(5)
  self.lcdSendCommandInit(lcdFunction)
  sleep(5)
  if self.numLines > 4:
    self.numLines = 4
  if self.numColum > 40:
    self.numColum = 40
  self.cursorX = 0
  self.cursorY = 0
  impiledNewLine = 0
  lcdBackLight = 1
  self.displayOff()
  self.backLightOn
  self.clear()
  self.lcdSendCommand(lcdEntryMode or lcdEntryInc)
  self.hideCursor()
  self.displayOn()

when isMainModule:
  stdioInitAll()
  #[const sda = 2.Gpio 
  const scl = 3.Gpio 
  #const address = 0x27

  i2c1.init(100000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()]#
  setupI2c(i2c1, 2.Gpio, 3.Gpio, 100000, true)

  let lcdx = Lcd(i2c: i2c1, lcdAdd: 0x27, numColum:16, numLines:2)
  let usb = PicoUsb()
  #print("---init----" & '\n')
  lcdx.init()
  #print("---disp init----" & '\n')
  sleep(2000)

  while true:
    #if usb.isReady == true:
    lcdx.clear()
    lcdx.putStr("Lcd Version:")
    lcdx.moveTo(0,1)
    lcdx.centerString(disp1602Ver)
    sleep(5000)
    lcdx.clear()
    lcdx.shiftString("Right Shift >", dir = false)
    lcdx.moveTo(0,1)
    lcdx.shiftString("< Left Shift", dir = true)
    sleep(2000)
    lcdx.clear()
    lcdx.putStr("String > 16 Chars!!")
    sleep(3000)
    lcdx.clear()
    lcdx.shiftChar('>')
    lcdx.moveTo(0,1)
    lcdx.shiftChar('<', 200, false)
    sleep(2000)