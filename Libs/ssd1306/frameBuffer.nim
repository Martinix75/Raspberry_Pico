#[
Framebuffer generic for display written in Nim.
port from framebuffer.py (Damien P. George and Tony DiCola)
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6

author Andrea Martin (Martinix75)
https://github.com/Martinix75/Raspberry_Pico/tree/main/Libs/ssd1306
]#

## Module for writing on the buffer characters, geometric shapes and drawings.

import picostdlib/[stdio, gpio, time, i2c] #solo in test
import std/[options]
from strutils import split
import font5x8
import images

const frameBufferVer* = "0.9.0" #cambio nomi per compatttibilità
stdioInitAll()
type 
  Framebuffer* = ref object of RootObj
    fbWidth*, fbHeight*, fbStride*: int #per ora metto tutti i membi acessibili(pubblici poi vediamo s eprivatizzare)
    xSizeFont*, ySizeFont*: int
    xSizeImg*, ySizeImg*: int #memorizza la grandezza dell'immagine.
    fbRotation*: uint8
    fbBuff*: seq[byte]
    fbFont*: array[0..95, array[0..4, byte]]
    #fbImg*: array[0..15, uint] #vediamo se ba bene!!!! usare uint no byte senno niente numeri >255!!!
    fbImg*: seq[uint] #vediamo se ba bene!!!! usare uint no byte senno niente numeri >255!!!
    #fbFontName: string
    
# ---------- INIZIO Prototipi Procedure Private ----------
proc setPixelFb(self: Framebuffer; x, y, color: int)
proc getPixelFb(self: Framebuffer; x, y: int): uint8
proc fillRectD1(self: Framebuffer; x ,y ,width, height, color: int)
proc fillRect(self: Framebuffer; x, y, width, height, color: int)
proc pixel(self: Framebuffer; x, y: int; color=none(int)): Option[uint8]
proc drawChar(self: Framebuffer; dcChar: char; x, y, color, txHeight: int; size=1)
proc drawImage(self: Framebuffer; xPos, yPos, color: int)
proc fillFb(self: Framebuffer; color: int)
# ---------- FINE Prototipi Procedure Private ------------
# ---------- INIZIO Prototipi Procedure Pubbliche --------
proc clearFb*(self: Framebuffer; color=0)
proc rectFb*(self: Framebuffer; x ,y, width, height, color: int, fill=false)
proc lineFb*(self: Framebuffer, xStr, yStr, xEnd, yEnd, color: int)
proc hlineFb*(self: Framebuffer; x, y, width, color: int)
proc vlineFb*(self: Framebuffer; x, y, height, color: int)
proc circleFb*(self: Framebuffer; xCenter, yCenter, radius, color: int)
proc textFb*(self: Framebuffer; text: string; x, y, color: int; charType="std"; size=1, direct=true)
proc loadCharsFb*(self: Framebuffer; charType="std") #: tuple[sizeW, sizeH: int]
proc loadImageFb*(self: Framebuffer; nameImg = "img1")
proc imageFb*(self: Framebuffer; x, y, color: int; nameImg="img1"; direct=true)
# ---------- FINE Prototipi Procedure Pubbliche --------

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
  self.rectFb(x=x, y=y, width=width, height=height, color=color, fill=true)
  
proc rectFb*(self: Framebuffer; x ,y, width, height, color: int, fill=false) = #ok!
  ## Draw a rectangle on the display with the coordinates indicated.
  ##
  runnableExamples:
    rect()
  ## **Parameters:**
  ## - *x*: initial point on the axis of the X of the rectangle.
  ## - *y*: initial point on the axis of the Y of the rectangle.
  ## - *width:* length of the segment on the X axis.
  ## - *height:* length of the segment on the Y axis.
  ## - *color:* if color = 1 lights the pixels, if color = 0 turns off the pixels.
  ## - *fill:* if *false* does not color the rectangle, if *true* it fills it
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
    
proc hlineFb*(self: Framebuffer; x, y, width, color: int) = #ok!
  ## Trace a simple horizontal line.
  ##
  runnableExamples:
    hline(x=5, y=35, width=18, color=1)
  ## **Parameters:**
  ## - *x:* initial point on the axis of the X of the line.
  ## - *y:* initial point on the axis of the Y of the line.
  ## - *width:* length of the segment on the X axis.
  ## - *color:* if color = 1 lights the pixels, if color = 0 turns off the pixels.
  self.rectFb(x=x ,y=y, width=width, height=1, color=color, fill=true)

proc vlineFb*(self: Framebuffer; x, y, height, color: int) = #ok!
  ## Trace a simple vertical line.
  ##
  runnableExamples:
    vline(x=5, y=35, height=18, color=1)
  ## **Parameters:**
  ## - *x:* initial point on the axis of the X of the line.
  ## - *y:* initial point on the axis of the Y of the line.
  ## - *height:* length of the segment on the Y axis.
  ## - *color:* if color = 1 lights the pixels, if color = 0 turns off the pixels.
  self.rectFb(x=x ,y=y, width=1, height=height, color=color, fill=true)
    
proc lineFb*(self: Framebuffer, xStr, yStr, xEnd, yEnd, color: int) = #ok!
  ## Trace a line that can go in all directions
  ##
  runnableExamples:
    line()
  ## **Parameters:**
  ## - *xStr:* initial point on the axis of the X of the line.
  ## - *yStr:* initial point on the axis of the Y of the line.
  ## - *xEnd:* final point on the axis of the X of the line.
  ## - *yEnd:* final point on the axis of the Y of the line.
  ## - *height:* length of the segment on the Y axis.
  ## - *color:* if color = 1 lights the pixels, if color = 0 turns off the pixels.
  var
    lXzero = xStr
    lYzero = yStr
    lXone = xEnd
    lYone = yEnd
    err: float
  let
    dX = abs(lXone-lXzero)
    dY = abs(lYone-lYzero)
    sX = if xStr > xEnd: -1 else: 1
    sY = if yStr > yEnd: -1 else: 1
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
  discard self.pixel(x=lXzero, y=lYzero,color=some(color))
  
proc circleFb*(self: Framebuffer; xCenter, yCenter, radius, color: int) =
  ## Draw a circle in the coordinates indicated and with the indicated radius.
  ##
  runnableExamples:
    circle(xCenter=110, yCenter=20, radius=12, color=1)
  ## **Parameters:**
  ## - *xCenter:* position of the Center on the Axis X.
  ## - *yCenter:* position of the Center on the Axis Y.
  ## - *radius:* defines the circle radius
  ## - *color:* if color = 1 lights the pixels, if color = 0 turns off the pixels.
  var
    x = radius-1
    dX = 1
    dY = 1
    y = 0
    err = dX-(radius shl 1)
  while x >= y:
    discard self.pixel(xCenter+x, yCenter+y, color=some(color))
    discard self.pixel(xCenter+y, yCenter+x, color=some(color))
    discard self.pixel(xCenter-y, yCenter+x, color=some(color))
    discard self.pixel(xCenter-x, yCenter+y, color=some(color))
    discard self.pixel(xCenter-x, yCenter-y, color=some(color))
    discard self.pixel(xCenter-y, yCenter-x, color=some(color))
    discard self.pixel(xCenter+y, yCenter-x, color=some(color))
    discard self.pixel(xCenter+x, yCenter-y, color=some(color))
    if err <= 0:
      y += 1
      err += dY
      dY += 2
    if err > 0:
      x -= 1
      dX += 2
      err += dX-(radius shl 1)
      
proc clearFb*(self: Framebuffer; color=0) =
  ## Delete all drawings and characters on the display.
  ##
  runnableExamples:
    clear()
  ## **Parameters:**
  self.fillFb(color=color)
  
proc textFb*(self: Framebuffer; text: string; x, y, color: int; charType="std"; size=1; direct=true) =
  ## Print a string on the display in the indicated position.
  ##
  runnableExamples:
    text(text="Hello", x=35, y=17, color=1)
  ## **Parameters:**
  ## - *text:* string to print on the display.
  ## - *x:* initial point on the axis of the X of the text.
  ## - *y:* initial point on the axis of the Y of the text.
  ## - *color:* if color = 1 lights the pixels, if color = 0 turns off the pixels.
  ## - *charType:* choose the type of character you want to use.
  ## - *size:* choose the size with which to multiply the character (only integers).
  ## - *direct:* for internal use of the library.
  let

    #self.fbRatioSize = 3#int(1.25*float(setxy.sizeW))
    dotCharMax = int(((self.fbWidth/8)+5)*5) #calcola i punti massimi utilizzabili dai caratteri (tile per lo schift x)
    #ratioSize = int(1.25*float(self.xSizeFont))
  var
    fraWidth = self.fbWidth
    fraHeight = self.fbHeight
    xChar: int
    #self.xSizeFont, txHeight: int
    txHeight: int
    tY = y
    tText = text
  if direct == true:
    self.loadCharsFb(charType)# deve tirare su (aggiornare) i font ogni volta che si invoca test
  while (len(tText)*5)+int(float(x)*0.9) >= dotCharMax+1: #(1/ratioSize)) >= dotCharMax+1: #x deve valere x*0.8 altrimenti calcola sballato
    #print(tText)
    tText = tText[0..^2]
    if len(tText) == 0:
      break

  if self.fbRotation in [uint8(1), uint8(3)] == true:
    fraWidth=fraHeight; fraHeight=fraWidth
  for chunk in tText.split('\n'):
    #self.xSizeFont = setxy.sizeW
    txHeight = self.ySizeFont
    for index, charFor in pairs(chunk):
      xChar = x+(index*(int(self.xSizeFont+1)))*size
      if xChar+(self.xSizeFont*size) > 0 and xChar < int(fraWidth) and y+(txHeight*size) > 0 and y < int(fraHeight):
        self.drawChar(dcChar=charFor, x=xChar, y=y, color=color, txHeight=txHeight, size=size)
    tY += txHeight*size

proc imageFb*(self: Framebuffer; x, y, color: int; nameImg="img1"; direct=true) =
  self.loadImageFb(nameImg=nameImg)
  self.drawImage(xPos=x, yPos=y, color=color)

# ---------- Da qui parte lc conversione della classepy BitMapFont ---------------
proc loadCharsFb*(self: Framebuffer; charType="std") = #:tuple[sizeW, sizeH: int] =
  let loadFont = initChar(charType) #chiama il modulo dove è definito seix sizey e fonts
  self.fbFont = loadFont.byteChar #carica  i font
  self.xSizeFont = loadFont.xSize
  self.ySizeFont = loadFont.ySize
  #result = (loadFont.xSizeFont, loadFont.ySizeFont)

proc loadImageFb*(self: Framebuffer; nameImg="img1") = #carica immagine (Ver 0.8.0)
#invenbtya qualcosa del tipo se immagine = a quella vecchia non ricaricare
  let loadImage = initImg(nameImg = nameImg)
  self.fbImg = loadImage.byteImg
  self.xSizeImg = loadImage.xSizeImg
  self.ySizeImg = loadImage.ySizeImg
  
proc drawChar(self: Framebuffer; dcChar: char; x, y, color, txHeight: int; size=1) =
  var
    dcIndexFont: uint8
    dcLine: byte
    prova = 0
  for charX in 0..self.xSizeFont-1: #-1 qui ci va!!!
    dcIndexFont = uint8(ord(dcChar)-(32))
    dcLine = self.fbFont[dcIndexFont][prova] #(0xaa) #1010101 per test
    for charY in 0..txHeight-1: #qui -1 non so ma per ora lo metto
      if ((dcLine shr charY) and 0x1) == 1 :
        self.fillRect(x=x+charX*size, y=y+charY*size, width=size, height=size, color=color)
    if prova > 3:
      prova = 0
    else:
      prova += 1

proc drawImage(self: Framebuffer; xPos, yPos, color: int) = #traccia immagina a display (Ver 0.8.0).
  var 
    cont= 1
    x=xPos
    y=yPos
  if x+self.xSizeImg > self.fbWidth or x < 1: #posiziona xmax correttamente indipendente da grandezza immagine.
    x=1
  if y+self.ySizeImg > self.fbHeight or y < 1: #posiziona ymax correttamente indipendente da grandezza immagine.
    y=1
  for colonneImg in 0..<self.ySizeImg: #ok valore corretto
    for byteImg in 0..<self.xSizeImg: #ok valore corretto
      #print($cont & ": " & "Immagine: " & $self.fbImg[byteImg])
      cont.inc()
      if ((self.fbImg[byteImg] shr colonneImg) and 0x01) == 1:
        discard self.pixel(x=x+byteImg, y=y+colonneImg, color=some(color))
        
    
      
