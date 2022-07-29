import std/[options]
from strutils import split
import font5x8

const frameBufferVer* = "0.6.2"
#stdioInitAll()
type 
  Framebuffer* = ref object of RootObj
    fbWidth*, fbHeight*, fbStride*: int #per ora metto tutti i membi acessibili(pubblici poi vediamo s eprivatizzare)
    fbRotation*: uint8
    fbBuff*: seq[byte]
    fbFont: array[0..95, array[0..4, byte]]
    #fbFontName: string
    
# ---------- INIZIO Prototipi Procedure Private ----------
proc setPixelFb(self: Framebuffer; x, y, color: int)
proc getPixelFb(self: Framebuffer; x, y: int): uint8
proc fillRectD1(self: Framebuffer; x ,y ,width, height, color: int)
proc fillRect(self: Framebuffer; x, y, width, height, color: int)
proc loadChars(self: Framebuffer; charType="std"): tuple[sizeW, sizeH: int]
proc drawChar(self: Framebuffer; dcChar: char; x, y, color, txWidth, txHeight: int; size=1)
proc fillFb(self: Framebuffer; color: int)
# ---------- FINE Prototipi Procedure Private ------------
# ---------- INIZIO Prototipi Procedure Pubbliche --------
proc clear*(self: Framebuffer; color=0)
proc rect*(self: Framebuffer; x ,y, width, height, color: int, fill=false)
proc line*(self: Framebuffer, xZero, yZero, xOne, yOne, color: int)
proc pixel(self: Framebuffer; x, y: int; color=none(int)): Option[uint8]
proc hline*(self: Framebuffer; x, y, width, color: int)
proc vline*(self: Framebuffer; x, y, height, color: int)
proc circle*(self: Framebuffer; centerX, centerY, radius, color: int)
proc text*(self: Framebuffer; text: string; x, y, color: int; charType="std"; size=1,)
# ---------- FINE Prototipi Procedure Pubbliche ----------

proc setPixelFb(self: Framebuffer; x, y, color: int) = #ok!
  let index = (y shr 3)*self.fbStride+x
  let offset = y and 0x07
  var h: uint8
  if color != 0:
    h = uint8(color shl offset)
  self.fbBuff[index] = (self.fbBuff[index] and uint8(not(0x01 shl offset))) or h

proc getPixelFb(self: Framebuffer; x, y: int): uint8 = #credo uint8, per ora auto..
  let index = (y shr 3)*self.fbStride+x
  let offset = y and 0x07
  result = (self.fbBuff[index] shr offset) and 0x01

proc fillFb(self: Framebuffer; color: int) = #ok!
  var fill: uint8
  if color == 1: 
    fill = 0xFF
  else:
    fill = 0x00
  for indx in countup(1, len(self.fbBuff)-2):
    #print("Fill: " & $fill)
    self.fbBuff[indx] = fill
  #print("FbBuffer: " & $self.fbBuff & "Elenemt = " & $self.fbBuff.len)

proc fillRectD1(self: Framebuffer; x ,y ,width, height, color: int) = #ok!
  var 
    frY = y
    frHeight = height
    index: int
    offset: int
    h: uint8
  while frHeight > 0:
    index = (frY shr 3)*self.fbStride+x
    offset = frY and 0x07
    if color != 0:
      h = uint8(color shl offset)
    for j in countup(1, width):
      self.fbBuff[index+j] = (self.fbBuff[index+j] and byte(not(0x01 shl offset))) or h
    frY += 1
    frHeight -= 1

proc fillRect(self: Framebuffer; x, y, width, height, color: int) =
  self.rect(x=x, y=y, width=width, height=height, color=color, fill=true)
  
proc rect*(self: Framebuffer; x ,y, width, height, color: int, fill=false) = #ok!
  var #!! dove ce x e y forse ma messo rX ed rY
    rX = x
    rY = y
    rWidth = width
    rHeight = height
    
  if self.fbRotation == 1:
    rX = y; rY = x
    rWidth = height; rHeight = width
    rX = self.fbWidth-rX-width
  elif self.fbRotation == 2:
    rX = self.fbWidth-rX-width
    rY = self.fbHeight-rY-height
  elif self.fbRotation == 3:
    rX= y; rY = x
    rWidth = height; rHeight = width
    rY = self.fbHeight-rY-height
  if width < 1 or height < 1 or (rX+width) <= 0 or (rY+height) <= 0 or rY >= self.fbHeight or rX >= self.fbWidth:
    echo("errore... fors eun raise!")
  let xEnd = min(self.fbWidth-1, rX+width-1)
  let yEnd = min(self.fbHeight-1, rY+height-1)
  rX = max(rX, 0)
  rY = max(rY, 0)
  if fill == true:
    self.fillRectD1(x=rX ,y=rY ,width=xEnd-rX+1, height=yEnd-rY+1, color=color) #buona x hline
  elif fill == false:
    self.fillRectD1(x=rX ,y=rY ,width=xEnd-rX+1, height=1, color=color) #ok!!
    self.fillRectD1(x=rX ,y=rY ,width=1, height=yEnd-rY+1, color=color) #sembra non vada!!
    self.fillRectD1(x=rX ,y=yEnd ,width=xEnd-rX+1, height=1, color=color) #ok!!
    self.fillRectD1(x=xEnd ,y=rY ,width=1, height=yEnd-rY+1, color=color)# non va!!

proc pixel(self: Framebuffer; x, y: int; color=none(int)): Option[uint8] =
  var
    pX = x
    pY = y
  if self.fbRotation == 1:
    pX = y; pY = x
    pX = self.fbWidth-pX-1
  elif self.fbRotation == 2:
    pX = self.fbWidth-pX-1
    pY = self.fbHeight-pY-1
  elif self.fbRotation == 3:
    pX = y; pY = x
    pY = self.fbHeight-pY-1
  if pX < 0 or pX >= self.fbWidth or pY < 0 or pY >= self.fbHeight:
    echo "errore, ma dovrebbe torbnare NONE"
  if isNone(color):
    result = some(self.getPixelFb(x=pX, y=pY))
  else:
    self.setPixelFb(x=pX, y=pY, color=color.get())
    result = none(uint8)
    
proc hline*(self: Framebuffer; x, y, width, color: int) = #ok!
  self.rect(x=x ,y=y, width=width, height=1, color=color, fill=true)

proc vline*(self: Framebuffer; x, y, height, color: int) = #ok!
  self.rect(x=x ,y=y, width=1, height=height, color=color, fill=true)
    
proc line*(self: Framebuffer, xZero, yZero, xOne, yOne, color: int) = #ok!
  var
    lXzero = int(xZero)
    lYzero = int(yZero)
    lXone = int(xOne)
    lYone = int(yOne)
    err: float
  let
    dX = abs(lXone-lXzero)
    dY = abs(lYone-lYzero)
    sX = if xZero > xOne: -1 else: 1
    sY = if yZero > yOne: -1 else: 1
  if dX > dY:
    err = float(dX) / 2.0
    while lXzero != lXone:
      discard self.pixel(x=lXzero, y=lYzero,color=some(color))
      err -= float(dY)
      if err < 0:
        lYzero += sY
        err  += float(dX)
      lXzero += sX
  else:
    err = float(dY)/2.0
    while lYzero != lYone:
      discard self.pixel(x=lXzero, y=lYzero,color=some(color))
      err -= float(dX)
      if err < 0:
        lYzero += sX
        err += float(dY)
      lYzero += sY

proc circle*(self: Framebuffer; centerX, centerY, radius, color: int) =
  var
    x = radius-1
    dX = 1
    dY = 1
    y = 0
    err = dX-(radius shl 1)
  while x >= y:
    discard self.pixel(centerX+x, centerY+y, color=some(color))
    discard self.pixel(centerX+y, centerY+x, color=some(color))
    discard self.pixel(centerX-y, centerY+x, color=some(color))
    discard self.pixel(centerX-x, centerY+y, color=some(color))
    discard self.pixel(centerX-x, centerY-y, color=some(color))
    discard self.pixel(centerX-y, centerY-x, color=some(color))
    discard self.pixel(centerX+y, centerY-x, color=some(color))
    discard self.pixel(centerX+x, centerY-y, color=some(color))
    if err <= 0:
      y += 1
      err += dY
      dY += 2
    if err > 0:
      x -= 1
      dX += 2
      err += dX-(radius shl 1)
      
proc clear*(self: Framebuffer; color=0) =
  self.fillFb(color=color)
  
proc text*(self: Framebuffer; text: string; x, y, color: int; charType="std"; size=1,) =
  var
    fraWidth = self.fbWidth
    fraHeight = self.fbHeight
    xChar: int
    txWidth, txHeight: int
    tY = y
  let setxy = self.loadChars(charType)
  if self.fbRotation in [uint8(1), uint8(3)] == true:
    fraWidth=fraHeight; fraHeight=fraWidth
  for chunk in text.split('\n'):
    txWidth = setxy.sizeW
    txHeight = setxy.sizeH
    for index, charFor in pairs(chunk):
      xChar = x+(index*(int(txWidth+1)))*size
      if xChar+(txWidth*size) > 0 and xChar < int(fraWidth) and y+(txHeight*size) > 0 and y < int(fraHeight):
        self.drawChar(dcChar=charFor, x=xChar, y=y, color=color, txWidth=txWidth, txHeight=txHeight, size=size)
    tY += txHeight*size

# ---------- Da qui parte lc conversione della classepy BitMapFont ---------------
proc loadChars(self: Framebuffer; charType="std"): tuple[sizeW, sizeH: int] =
  let loadFont = initChar(charType)
  self.fbFont = loadFont.byteChar
  result = (loadFont.xSize, loadFont.ySize)
  
proc drawChar(self: Framebuffer; dcChar: char; x, y, color, txWidth, txHeight: int; size=1) =
  var
    dcIndexFont: uint8
    dcLine: byte
    prova = 0
  for charX in 0..txWidth-1: #-1 qui ci va!!!
    dcIndexFont = uint8(ord(dcChar)-(32))
    dcLine = self.fbFont[dcIndexFont][prova] #(0xaa) #1010101 per test
    for charY in 0..txHeight-1: #qui -1 non so ma per ora lo metto
      if ((dcLine shr charY) and 0x1) == 1 :
        self.fillRect(x=x+charX*size, y=y+charY*size, width=size, height=size, color=color)
    if prova > 3:
      prova = 0
    else:
      prova += 1
