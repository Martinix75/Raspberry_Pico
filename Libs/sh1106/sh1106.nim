import picostdlib/[stdio, gpio, time, i2c]
import std/[options, strformat]
import frameBuffer
from sequtils import insert
#import strformat
export frameBuffer

const
  sh1106Ver = "0.3.2" #flip
  setContrast = 0x81
  setNormInv = 0xA6
  setDisp = 0xAE
  setScanDir = 0xC0
  setSegRemap = 0xA0
  lowColumnAddress = 0x00
  highColumnAddress = 0x10
  setPageAddress = 0xB0

type 
  SH1106I2C* = ref object of Framebuffer
    i2c: I2cInst
    lcdAdd, rotate, pagesToUpDate: uint8
    temp: array[0..1, byte]
    width, height, pages, bufSize: int
    externalVcc, rotate90, flip_en: bool
    displayBuff: seq[byte]
    delay: uint32

# ---------- INIZIO Prototipi Procedura Private   ----------
proc initDisplay(self: SH1106I2C)
proc writeCdm(self: SH1106I2C; cdm: byte)
proc writeData(self: SH1106I2C; buf: seq[byte])
proc flip(self: SH1106I2C; flag=none(bool); update=true)
# ---------- FINE   Prototipi Procedura Private   ----------
# ---------- INIZIO Prototipi Procedura Pubbliche ----------
proc newSh1106*(i2c: I2cInst; lcdAdd: uint8; width, height: int; externalVcc=false, rotate=0, delay=uint32(0)): SH1106I2C
proc registerUpDate*(self: SH1106I2C; yZero: int; yOne=none(int))
proc clear*(self:SH1106I2C, color=0)
proc powerOn*(self: SH1106I2C)
proc powerOff*(self: SH1106I2C)
proc hline*(self: SH1106I2C; x, y, width, color: int)
proc vline*(self: SH1106I2C; x, y, height, color: int)
proc line*(self: SH1106I2C; xZero, yZero, xOne, yOne, color: int; size=1)
proc rect*(self: SH1106I2C; x, y, width, height, color: int; fill=false)
proc circle*(self: SH1106I2C; xCenter, yCenter, radius, color: int)
proc text*(self: SH1106I2C; text: string; x, y, color: int; size=1)
proc show*(self: SH1106I2C; fullUpDate=false)
proc invert*(self: SH1106I2C; invert=false)
proc contrast*(self: SH1106I2C; contrast: uint8=0)
proc image*(self: SH1106I2C; x, y, color: int; nameImg="img1"; direct=true)
# ---------- FINE   Prototipi Procedura Pubbliche ----------
proc newSh1106*(i2c: I2cInst; lcdAdd: uint8; width, height: int; externalVcc=false, rotate=0, delay=uint32(0)): SH1106I2C =
  let 
    pagesSh = height div 8
    bufSizeSh = pagesSh*width
    renderBuffSh = newSeqOfCap[byte](bufSizeSh+1)
    pagesToUpDateSh = uint8(0)
  var
    displayBuffSh = if rotate == 0: renderBuffSh else: newSeqOfCap[byte](bufSizeSh) #da studiare in caso di rotazione!!
    flipSh: bool = if rotate == 180 or rotate == 270: true else: false
  displayBuffSh.setLen(bufSizeSh+1)
  
  result = SH1106I2C(i2c: i2c, lcdAdd: lcdAdd, width: width, height: height, externalVcc: externalVcc,
                  pages: pagesSh, bufSize: bufSizeSh, pagesToUpDate: pagesToUpDateSh, fbRotation: 0,
                  delay: delay, fbStride: width, fbWidth: width, fbHeight: height, fbBuff: displayBuffSh,
                  flip_en: flipSh)
  result.initDisplay()

proc initDisplay(self: SH1106I2C) =
  self.powerOn()
  self.clear(0)
  self.show()
  self.flip(some(self.flip_en))
  #self.loadChars()

proc writeCdm(self: SH1106I2C; cdm: byte) =
  self.temp[0] = 0x80
  self.temp[1] = cdm
  let addrElementCdm = self.temp[0].unsafeAddr
  writeBlocking(self.i2c, self.lcdAdd, addrElementCdm,
                csize_t(self.temp.len()*sizeof(self.temp[0])), true)
  
proc writeData(self: SH1106I2C; buf: seq[byte]) = 
  let paramWD: byte = 0x40
  var buffWD = buf
  buffWD.insert(paramWD, 0)
  let addrElementBuffWD = buffWD[0].unsafeAddr
  writeBlocking(self.i2c, self.lcdAdd, addrElementBuffWD,
                csize_t(buffWD.len()*sizeof(buffWD[0])), false)

proc flip(self: SH1106I2C; flag=none(bool); update=true) =
  var 
    flagFl: bool
  if isNone(flag):
    flagFl = not self.flip_en
  let
    mir_v: bool = flagFl xor self.flip_en
    mir_h: bool = flagFl
    cazzoFlip = if mir_v == true: 0x01 else: 0x00
    figafiappa = if mir_h == true: 0x08 else: 0x00
  self.writeCdm(uint8(setSegRemap or (cazzoFlip)))
  self.writeCdm(uint8(setScanDir or (figafiappa)))
  self.flip_en = flagFl
  if update == true:
    self.show(true)
    
proc registerUpDate*(self: SH1106I2C; yZero: int; yOne=none(int)) =
  var
    startPageUD = max(0, (yZero div 8))
    endPageUD = if isNone(yOne): startPageUD else: max(0, (yOne.get() div 8))
  if startPageUD > endPageUD:
    startPageUD = endPageUD; endPageUD = startPageUD
  for pageUD in countup(startPageUD, endPageUD):
    self.pagesToUpDate = self.pagesToUpDate or uint8((1 shl pageUD))

#[proc fill*(self: SH1106I2C; color=0) = 
  self.fillFb(0)
  self.pagesToUpdate = uint8((1 shl self.pages) - 1) ]#
  
proc clear*(self:SH1106I2C, color=0) =
  self.clearFb(color=color)
  self.pagesToUpdate = uint8((1 shl self.pages) - 1)
  
proc powerOn*(self: SH1106I2C) =
  self.writeCdm(setDisp or 0x01)
  if self.delay != 0:
    sleep(self.delay)

proc powerOff*(self: SH1106I2C) =
  self.writeCdm(setDisp or 0x00)

proc hline*(self: SH1106I2C; x, y, width, color: int) =
  self.hlineFb(x=x, y=y, width=width, color=color)
  self.registerUpDate(yZero=y)

proc vline*(self: SH1106I2C; x, y, height, color: int) =
  self.vlineFb(x=x, y=y, height=height, color=color)
  self.registerUpDate(yZero=y, yOne=some(y+height-1))

proc line*(self: SH1106I2C; xZero, yZero, xOne, yOne, color: int; size=1) =
  self.lineFb(xStr=xZero, yStr=yZero, xEnd=xOne, yEnd=yOne, color=color)
  self.registerUpDate(yZero=yZero, yOne=some(yOne))

proc rect*(self: SH1106I2C; x, y, width, height, color: int; fill=false) =
  self.rectFb(x=x, y=y, width=width, height=height, color=color, fill=fill)
  self.registerUpDate(yZero=y, yOne=some(y+height-1))

proc circle*(self: SH1106I2C; xCenter, yCenter, radius, color: int) =
  let maxRadius = if radius > 13: 13 else: radius
  self.circleFb(xCenter=xCenter, yCenter=yCenter, radius=maxRadius, color=color)
  self.registerUpDate(yZero=yCenter, yOne=some(yCenter+maxRadius)) #12

proc text*(self: SH1106I2C; text: string; x, y, color: int; size=1) =
  self.textFb(text=text, x=x, y=y, color=color)
  self.registerUpDate(yZero=y, yOne=some(y+7))

proc invert*(self: SH1106I2C; invert=false) =
  let sysInvert = if invert == false: 0 else: 1
  self.writeCdm(uint8(setNormInv or (sysInvert and 1)))

proc contrast*(self: SH1106I2C; contrast: uint8=0) =
  self.writeCdm(setContrast)
  self.writeCdm(contrast)

proc image*(self: SH1106I2C; x, y, color: int; nameImg="img1"; direct=true) =
  self.imageFb(x=x, y=y, color=color, nameImg=nameImg, direct=direct)
  self.registerUpDate(yZero=y, yOne=some(y+16))
  
proc show*(self: SH1106I2C; fullUpDate=false) =
  let
    widthSW = self.width
    #pageSW =self.page #futre applicazioni
    displayBuffSW = self.fbBuff
    #renderBuffSW = self.renderBuff
  var
    pagetoUpdateSW: uint8
  if fullUpDate == true:
    pageToUpdateSW = uint8((1 shl self.pages)-1)
  else:
    pagetoUpdateSW = self.pagesToUpDate
  for pageSW in countup(0, (self.pages)-1):
    if (pagetoUpdateSW and uint8((1 shl pageSW))) != 0:
      self.writeCdm(uint8(setPageAddress or pageSW))
      self.writeCdm(lowColumnAddress or 2)
      self.writeCdm(highColumnAddress or 0)
      self.writeData(displayBuffSW[(widthSW*pageSw)..(widthSW*pageSW+widthSW)])
  self.pagesToUpDate = 0
  
when isMainModule:
  import picostdlib/[stdio, gpio, time, i2c]
  import utilssh1106
  stdioInitAll()
  sleep(1500)
  print("Test SH1106I2C")
  setupI2c(blokk=i2c1, psda=2.Gpio, pscl=3.Gpio, freq=300_000)
  let oled = newSh1106(i2c=i2c1, lcdAdd=0x3C, width=128, height=64)#, rotate=270)
  print("--- Fill ---")
  #oled.clear(0)
  #sleep(1000)
  print(" ---- Linea ---")
  oled.invert(false)
  oled.show()
  #for j in countup(0, 255):
  oled.contrast(111)
  #oled.line(2, 6, 124, 6,1)
  oled.hline(0, 0, 121, 1)
   #oled.vline(90, 6, 45, 1)
  oled.rect(10, 18, 40, 20, 1, false)
  oled.centerText(fmt"Utils Ver:  {utilssh1106.utilSsh1106}", 45)
  #oled.circle(65, 50, 10,1)
   #oled.invert(true)
  #oled.text(fmt"contrast : {j}" , 5, 20 ,1)
   #oled.show()
   #oled.text("go Home", 30, 56, 1)
   #sleep(500)
   #oled.text(fmt"contrast : {j}" , 5, 20 ,0)
   #oled.show() ]#
  #oled.powerOff()
  oled.image(15 ,20, 1, "iom1")
  oled.show()
  #[print("---- SHOW------")
  oled.show() ]#
