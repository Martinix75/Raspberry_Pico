#[
Random generator for PR2040.
This is a port of https://github.com/Seeed-Studio/Grove_LCD_RGB_Backlight
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6
]#
## Simple random pseudo-number generator with Lehmer algorithm

import picostdlib/[gpio, time]
from math import round, pow
from sequtils import toSeq
from strutils import Letters

const randomGenVer* = "0.5.5"

var timeSeed: uint32 = 27121975

proc randomize*() = #Randomizes the variable with the bootstrap time 
  ## Randomizes the variable with the bootstrap time.
  ##
  runnableExamples:
    randomize()
  timeSeed = timeUs32()

proc random*(precision = 10): float = #make a random float number between 0..1 (set precision)
  ## Generates a random (float) number between 0 and 1
  ##
  runnableExamples:
    var floatRnd = random(3) --> 0.321
  ## **Parameters:**
  ## - precision = indicates how many numbers to use (10 = 0.1234567891)
  const 
    a: uint32 = 1664525
    c: uint32 = 1013904223
    m: uint32 = uint32(pow(2.0, 31.0) - 1)
  timeSeed = uint32((a * timeSeed + c ) mod m)#Lehmer random generator
  result = round(float(timeSeed) / float(m), precision)

proc randomInt*(min = 0, max = 100.0): int = #make a random integer numer between "min" and "max"
  ## Generates an entire random number, between a maximum and a minimum.
  ##
  runnableExamples:
    var intRnd = randomInt(5, 9) --> 7
  ## **Parameters:**
  ## - min = minimum integer of generated.
  ## - max = maximum integer of generated.
  while true:
    var numbIntRnd = int32(random() * max)
    if numbIntRnd >= min:
      return numbIntRnd

proc randomChar*(): char = #make a random char (a..z, A..Z)
  ## Generates a random character (a..z, A..Z).
  ##
  runnableExamples:
    var charRnd = randomChar() --> k
  let seqLetters = toSeq(Letters)
  let numbIntRnd = randomInt(0,51)
  result = seqLetters[numbIntRnd]
