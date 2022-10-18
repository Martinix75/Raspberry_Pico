#[
Driver for display type ssd1306 write in Nim.
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6

author Andrea Martin (Martinix75)
https://github.com/Martinix75/Raspberry_Pico/tree/main/Libs/ssd1306
]#

## Driver for display type ssd1306 write in Nim.
## This module offers you basic methods to simply manage the ssd1306 display

import picostdlib/[stdio, gpio, time, i2c]
import frameBuffer
export frameBuffer

const 
  ssd1306Ver* = "0.7.2"
  setContrast = 0x81
  setEntireOn = 0xA4
  setNormInv = 0xA6
  setDisp = 0xAE
  setMemAddr = 0x20
  setColAddr = 0x21
  setPageAddr = 0x22
  setDispStartLine = 0x40
  setSegRemap = 0xA0
  setMuxRatio = 0xA8
  setComOutDir = 0xC0
  setDispOffset = 0xD3
  setComPinCfg = 0xDA
  setDispClkDiv = 0xD5
  setPrecharge = 0xD9
  setVcomDesel = 0xDB
  setChargePump = 0x8D

type 
  SSD1306I2C* = ref object of FrameBuffer
    i2c: I2cInst
    lcdAdd: uint8
    pages: int
    externalVcc: bool
    temp: array[0..1, byte]
    
# ---------- INIZIO Prototipi Procedure Private ----------
proc initDisplay(self: SSD1306I2C)
proc writeCmd(self: SSD1306I2C, cmd: uint8)
proc writeData(self: SSD1306I2C)
# ---------- FINE Prototipi Procedure Private -------------
# ---------- INIZIO Prototipi Procedure Pubbliche ---------
proc newSsd1306I2C*(i2c: I2CInst; lcdAdd: uint8; width, height: int; externalVcc=false): SSD1306I2C
proc powerOff*(self: SSD1306I2C)
proc powerOn*(self: SSD1306I2C)
proc contrast*(self: SSD1306I2C, contrast: uint8)
proc invert*(self: SSD1306I2C, invert: uint8)
proc show*(self: SSD1306I2C)
# ---------- FINE Prototipi Procedure Pubbliche -----------

proc newSsd1306I2C*(i2c: I2CInst; lcdAdd: uint8; width, height: int; externalVcc=false): SSD1306I2C =
  ## Display initiator
  ##
  runnableExamples:
    newSsd1306I2C(i2c=i2c1, lcdAdd=0x3C, width=128, height=64)
  ## **Parameters:**
  ## - *i2c* = name of the block where the display connected (i2c0 or i2c1).
  ## - *lcdAdd* = hardware address of the display.
  ## - *width* = display width (see data scheet).
  ## - *height* = display height (see data sheet).
  let pagesInit = height div 8
  let nBytes = pagesInit*width+1
  var bufInit = newSeqOfCap[uint8](nBytes) #usato uan sequanza fissa per calcolare la dimensione dell'array
  bufInit.setLen(nBytes)
  bufInit[0] = byte(0x40)
  result = SSD1306I2C(i2c: i2c, lcdAdd: lcdAdd, fbBuff: bufInit, fbWidth: width, fbHeight: height, pages: pagesInit, 
                      fbRotation: 0, fbStride: width)
  result.initDisplay()

proc initDisplay(self: SSD1306I2C) =
  self.loadChars()
  for cmd in [setDisp or 0x00, 
              setMemAddr, 
              0x00, 
              setDispStartLine or 0x00, 
              setSegRemap or 0x01, 
              setMuxRatio,
              int(self.fbHeight-1), 
              setComOutDir or 0x08, setDispOffset, 
              0x00, 
              setComPinCfg, 
              if self.fbWidth > 2*self.fbHeight: 0x02 else: 0x12, 
              setDispClkDiv, 
              0x80, 
              setPrecharge,
              if self.externalVcc == true: 0x22 else: 0xF1, 
              setVcomDesel, 
              0x30, 
              setContrast, 
              0xFF, 
              setEntireOn, 
              setNormInv,
              setChargePump, 
              if self.externalVcc == true: 0x10 else: 0x14, 
              setDisp or 0x01]:
    self.writeCmd(uint8(cmd))
    #print($cmd)
  self.clear(0)
  self.show()

proc writeCmd(self: SSD1306I2C, cmd: uint8) =
  #print("Write Cmd..")
  self.temp[0] = 0x80
  self.temp[1] = cmd
  #print("Tempo0: " & $(self.temp[0]))
  #print("Tempo1: " & $(self.temp[1]))
  let addrElement = self.temp[0].unsafeAddr
  writeBlocking(self.i2c, self.lcdAdd, addrElement, csize_t(self.temp.len()*sizeof(self.temp[0])), true)

proc writeData(self: SSD1306I2C) =
  let addrElement2 = self.fbBuff[0].unsafeAddr
  #print("El2: " & $(self.fbBuff))
  writeBlocking(self.i2c, self.lcdAdd, addrElement2, csize_t(self.fbBuff.len()*sizeof(self.fbBuff[0])), true)

proc powerOff*(self: SSD1306I2C) =
  ## Turn off the display
  ## da finire...
  #print("off " & $(setDisp or 0x00))
  self.writeCmd(uint8(setDisp or 0x00))

proc powerOn*(self: SSD1306I2C) =
  ## Turn on the display
  ## da finire....
  self.writeCmd((setDisp or 0x01))

proc contrast*(self: SSD1306I2C, contrast: uint8) =
  ## DA VEDERE QUESTA:::
  self.writeCmd(setContrast)
  self.writeCmd(contrast)

proc invert*(self: SSD1306I2C, invert: uint8) = 
  self.writeCmd(setNormInv or (invert and 1))

proc show*(self: SSD1306I2C) =
  ## shows what is written in memory by the procedures that trace 
  ## forms or characters (otherwise they are not displayed).
  ##
  runnableExamples:
    show()
  #print("chiamata a show.. " & '\n')
  var xZero: uint8 = 0
  var xOne: uint8 = uint8(self.fbWidth-1)
  if self.fbWidth == 64:
    xZero = xZero+32
    xOne = xOne+32
  self.writeCmd(setColAddr)
  #print("setColAddr: " & $setColAddr & '\n')
  self.writeCmd(xZero)
  self.writeCmd(xOne)
  self.writeCmd(setPageAddr)
  #print("setPageADD: " & $setPageAddr & '\n')
  self.writeCmd(0)
  self.writeCmd(uint8(self.pages-1))
  #print("Page: " & $(self.pages-1) & '\n')
  self.writeData()
  #print( "no el: " & $len(self.fbBuff))

when isMainModule:
  import picostdlib/[stdio, gpio, time, i2c]
  stdioInitAll()
  sleep(2000)
  print("Partenza...")
  setupI2c(blokk=i2c1,psda=2.Gpio, pscl=3.Gpio, freq=100_000)
  let test = newSsd1306I2C(i2c=i2c1, lcdAdd=0x3C, width=128, height=64)
  test.clear(0)
  test.rect( x=5 ,y=5, width=123, height=62, color=1, fill=false)
  test.text("Driver for", 35 ,17, 1)
  test.text("NIM", 55 ,30 ,1, charType="test")
  test.text("Version:" & ssd1306Ver , 30 ,45 ,1, charType="test")
  test.show()

