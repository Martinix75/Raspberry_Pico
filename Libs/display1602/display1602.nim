#[
Driver for display type 1604 (HD44780+connected via PCF8574 on I2C) write in Nim.
This is a port of https://github.com/Seeed-Studio/Grove_LCD_RGB_Backlight
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6
]#
## This module offers you methods to simply manage the SSD1602 display
## (HHD44780) via the I2C connection (with PCF8574 module).
from sequtils import toSeq
from math import round
import picostdlib/[stdio, gpio, i2c, time]
#import picostdlib

const 
  disp1602Ver* = "1.2.2"

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

#---------- declaration of private procedures ----------
proc lcdSendByte(self: Lcd, valore: uint8)
proc lcdWriteWord(self: Lcd, command: uint8)
proc lcdSendCommandInit(self: Lcd, comm: uint8)
proc lcdSendCommand(self: Lcd, comm: uint8)
proc lcdWriteData(self: Lcd, data: uint8)
proc lcdFormatStr(self: Lcd, strg: string, dir: bool): string
proc lcdShiftSx(self: Lcd, strg: string, speed: uint16, dir: bool, cross=false, effect: uint8) 
proc lcdShiftDx(self: Lcd, strg: string, speed: uint16, dir: bool, cross=false, effect: uint8)
proc lcdCross(self: Lcd, strg: string, dir: bool, effect: uint8=0): string
proc toString(self: Lcd, seqx: seq[char]): string
proc makeArray[T](charmap: array[0..7, T]): array[0..7, uint8]
proc addHead(strg: string, chr: char): string

#---------- declaration of public procedures ----------
proc newDisplay*(i2c: I2cInst, lcdAdd:uint8, numLines:uint8, numColum:uint8): Lcd
proc clearLine*(self: Lcd)
proc clear*(self: Lcd)
proc moveTo*(self: Lcd, columx, rowx: uint8)
proc putChar*(self: Lcd, charx: char)
proc putString*(self: Lcd, strg: string)
proc centerString*(self: Lcd, strg: string)
proc shiftChar*(self: Lcd, charx: char, speed: uint16=400, dir=true)
proc shiftString*(self: Lcd, strg: string, speed: uint16=400, dir=true, cross=false, effect: uint8=0)
proc customChar*[T](self: Lcd, location: uint8, charmap: array[0..7, T])
proc displayOn*(self: Lcd)
proc displayOff*(self: Lcd)
proc backLightOn*(self: Lcd)
proc backLightOff*(self: Lcd)
proc hideCursor*(self: Lcd)

#---------- private procedures ----------
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

proc makeArray[T](charmap: array[0..7, T]): array[0..7, uint8] =
  for index in countup(0,7):
    result[index] = uint8(charmap[index])

proc lcdFormatStr(self: Lcd, strg: string, dir: bool): string = #controlla la lunghezza delal stringa
  var chars = toSeq(strg)
  var lenseq = uint8(len(chars))
  if lenseq > self.numColum:
    while lenseq > self.numColum:
      if dir == false:
        chars.delete(len(strg))
      else:
        chars.delete(0)
      lenseq = uint8(len(chars))
  result = self.toString(chars)

proc toString(self: Lcd, seqx: seq[char]): string = #convert seq in to string
  for j in seqx:
    result.add(j)

proc addHead(strg: string, chr: char): string =
  result.add(chr & strg)


proc lcdShiftSx(self: Lcd, strg: string, speed: uint16, dir: bool, cross=false, effect: uint8) =
  var strgCopy = strg
  var dinamicString: string
  if cross == true:
    strgCopy = self.lcdCross(strgCopy, dir, effect)
  self.clearLine()
  for charx in countup(0, len(strgCopy) - 1):#0..len(strg) - 1:
    dinamicString.add(strgCopy[charx]) #aggiunge una lettera ad ogni ciclo
    var fString = self.lcdFormatStr(dinamicString, dir) #controlla e manipola la stringa se troppo grande
    self.cursorX = self.numColum - uint8(len(fString)) #calcola posizione inizio stringa
    self.moveTo(self.cursorX, self.cursorY) #muovi ora il cursore li
    self.putString(fString) #stampa la stringa
    sleep(speed)

proc lcdShiftDx(self: Lcd, strg: string, speed: uint16, dir: bool, cross=false, effect: uint8) =
  var strgCopy = strg
  var dinamicString: string
  if cross == true:
    strgCopy = self.lcdCross(strgCopy, dir, effect)
  self.clearLine()
  for charx in countdown(len(strgCopy)-1,0): #aggiunge una lettera ad ogni ciclo
    dinamicString = dinamicString.addHead(strgCopy[charx]) #aggiunge il carattere in testa e non in coda
    var fString = self.lcdFormatStr(dinamicString, dir) #controlla e manipola la stringa se troppo grande
    self.cursorX = 0
    self.moveTo(self.cursorX, self.cursorY) #muovi ora il cursore li
    self.putString(fString) #stampa la stringa
    sleep(speed)

proc lcdCross(self: Lcd, strg: string, dir : bool, effect: uint8): string =
  let lenstrg: uint8 = uint8(len(strg))
  var addSpace: uint8
  if effect == 0:
    addSpace = self.numColum - 1
  elif effect == 1:
    addSpace = (self.numColum - 1) - lenstrg
  var buildString: string
  for _ in countup(uint8(0), addSpace):
    buildString.add(' ')
  if dir == true: 
    result = strg & buildString
  else:
    result = buildString & strg
  
proc initDisplay(self: Lcd) =
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

#---------- public procedures ----------
proc moveTo*(self: Lcd, columx, rowx: uint8) =
  ## Move the cursor to the indicated position
  ##
  runnableExamples:
    self.moveTo(0,5)
  ## **Parameters:** 
  ## - *columx* = position colum cursor.
  ## - *rowx* = position row cursor.
  self.cursorX = columx
  self.cursorY = rowx
  var addrx = self.cursorX and 0x3f
  if (self.cursorY and 0x01) == uint8(1):
    addrx = addrx + 0x40
  if (self.cursorY and 0x02) == uint8(1):
    addrx = addrx + self.numColum
  self.lcdSendCommand(lcdDdRam or addrx)

proc putChar*(self: Lcd, charx: char) = #prints a single character
  ## Write an ASCII character from the position indicated with moveTo()
  ##
  runnableExamples:
    self.moveTo(0,5)
    self.putChar('#')
  ## **Parameters:** 
  ## - *charx* = ascii char.
  self.lcdWriteData(uint8(ord(charx)))
  self.cursorX = self.cursorX + 1
  if self.cursorX > self.numColum - 1:
    self.cursorX = self.numColum - 1
  self.moveTo(columx = self.cursorX, rowx = self.cursorY)

proc shiftChar*(self: Lcd, charx: char, speed: uint16=400, dir=true) = #move the single character on the line
  ##  and move the single ASCII character on the display
  ##
  runnableExamples:
    self.moveTo(0,0)
    self.shiftChar('#', 300, true)
  ## **Parameters:**
  ## - *charx* = ascii char
  ## - *speed* = display crossing speed, dir = 
    
  if dir == true:
    for _ in countup(0, 16):
      self.lcdWriteData(uint8(ord(charx)))
      sleep(speed)
      self.moveTo(columx = self.cursorX, rowx = self.cursorY)
      self.lcdWriteData(uint8(ord(' ')))
      self.cursorX = self.cursorX + 1
      self.moveTo(columx = self.cursorX, rowx = self.cursorY)
  else:
    self.moveTo(columx = 16, rowx = self.cursorY)
    for _ in countdown(16, 0):
      self.lcdWriteData(uint8(ord(charx)))
      sleep(speed)
      self.moveTo(columx = self.cursorX, rowx = self.cursorY)
      self.lcdWriteData(uint8(ord(' ')))
      self.cursorX = self.cursorX - 1
      self.moveTo(columx = self.cursorX, rowx = self.cursorY)

proc putString*(self: Lcd, strg: string) = #print the string on the display 
  ## Write  string ASCII character from the position indicated with moveTo()
  ##
  runnableExamples:
    self.moveTo(7,0)
    self.putString("Hello Nim")
  ##
  ## **Parameters:**
  ## - *strg* = string to write in the display
  let lenstrg = uint8(len(strg))
  if lenstrg <= self.numColum: # da mettere <= ;intest >
    for charx in strg:
      self.putChar(charx)
      #sleep(5)
  else:
    discard
    self.shiftString(strg)

proc shiftString*(self: Lcd, strg: string, speed: uint16=400, dir=true, cross=false, effect: uint8=0) = 
  ## Write and move the string on the display
  ##
  runnableExamples:
    shiftString("Nim", 200, false, false, 0)
  ##
  ## **Parameters:**
  ## - *strg* = string to write in the display.
  ## - *speed* = croll speed of the string.
  ## - *dir* = direction of the scrolling of the string.
  ## - *cross* = if the string has to cross the whole display or stop.
  ## - *effect* = if the string has to get out of the display.
  if dir == true:
    self.lcdShiftSx(strg, speed, dir, cross, effect) #sx
  else:
    self.lcdShiftDx(strg, speed, dir, cross, effect) #dx

proc clearLine*(self: Lcd) =  
  ## Clear the only line where the cursor is located
  ##
  runnableExamples:
    self.moveTo(0,0)
    self.clearLine()
  var poscurX: uint8 = uint8(0)
  self.moveTo(columx = poscurX, rowx = self.cursorY) #moves the cursor to the beginning of the line 
  for _ in uint8(0)..self.numColum: #repeat how many columxs there are 
    self.lcdWriteData(uint8(ord(' '))) #print "empty" character 
    poscurX = poscurX + uint8(1)
    self.moveTo(columx = poscurX, rowx = self.cursorY) #moves the cursor one position

proc centerString*(self: Lcd, strg: string) = #prints the string in the center of the display
  ## Write the string at the center of the display
  ##
  runnableExamples:
    self.centerString("Hello Nim")
  ##
  ## *Parameters**
  ## - *strg* = string to write in the display.
  let numColum = uint8(self.numColum div 2)
  let lenStr = uint8(len(strg))
  let division = float((lenStr div 2))
  let round = uint8(round(division))
  let posCur: uint8 = numColum - round
  self.moveTo(columx = posCur, rowx = self.cursorY)
  self.putString(strg)

proc customChar*[T](self: Lcd, location: uint8, charmap: array[0..7, T])= #macke custom char
  ## Create custom characters
  ## Watch the example file attached to this module.
  let charOk = makeArray(charmap)
  let location = location and 0x07
  self.lcdSendCommand(lcdCgRam or (location shl uint8(3)))
  sleepMicroseconds(40)
  for line in 0..7:
    self.lcdWriteData(charOk[line])
    sleepMicroseconds(40)
  self.moveTo(self.cursorX, self.cursorY)

proc displayOn*(self: Lcd) =
  ## Activate the display
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay)

proc displayOff*(self: Lcd) =
  ## Deactivate the display
  self.lcdSendCommand(lcdOnCtrl)

proc showCursor*(self: Lcd) =
  ## Show the cursor on the display
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay or lcdOnCursor)

proc hideCursor*(self: Lcd) =
  ## hides the cursor on the display
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay)

proc blinkCursorOn*(self: Lcd) =
  ## Show the blink  cursor
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay or lcdOnCursor or lcdOnBlink)

proc blinkCursorOff*(self: Lcd) = 
  ## Show the non-blink cursor
  self.lcdSendCommand(lcdOnCtrl or lcdOnDisplay or lcdOnCursor)

proc backLightOn*(self: Lcd) =
  ## Turn on the displays backlighting LED
  lcdBackLight = 1
  self.lcdSendByte(1 shl lcdShiftBackLight)

proc backLightOff*(self: Lcd) =
  ## Turn off the displays backlighting LED
  #lcdBackLight = 0
  self.lcdSendByte(1)

proc clear*(self: Lcd) = 
  ## It cleans the whole display and place the cursor in 0.0
  self.lcdSendCommand(lcdClr)
  self.lcdSendCommand(lcdHome)
  self.cursorX = 0 
  self.cursorY = 0

proc newDisplay*(i2c: I2cInst, lcdAdd:uint8, numLines:uint8, numColum:uint8): Lcd =
  ## Display initiator
  ##
  runnableExamples:
    newDisplay(i2c=i2c1, lcdAdd=0x27, numLines=2, numColum=16)
  ## **Parameters:**
  ## - i2c = name of the block where the display connected (i2c0 or i2c1).
  ## - lcdAdd = hardware address of the display.
  ## - numLines = number of display lines
  ## - numColum = number of display rows.
  result = Lcd(i2c: i2c, lcdadd: lcdAdd, numLines: numlines, numColum: numColum)
  result.initDisplay()

when isMainModule:
  stdioInitAll()
  const sda = 2.Gpio 
  const scl = 3.Gpio 

  i2c1.init(100000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()

  let lcd = newDisplay(i2c=i2c1, lcdAdd=0x27, numLines=2, numColum=16)
  let nim = [0x00,0x11,0x15,0x15,0x1f,0x1b,0x1f,0x00]
  lcd.customChar(0, nim)
  while true:
    lcd.clear()
    lcd.putChar(char(0))
    lcd.centerString("Test Lib")
    lcd.moveto(15,0)
    lcd.putChar(char(0))
    lcd.moveTo(0,1)
    lcd.centerString("Ver: " & disp1602Ver)
    #lcd.shiftString("Ver: " & disp1602Ver, dir = true, cross = true, effect = 0)
    sleep(1500)
