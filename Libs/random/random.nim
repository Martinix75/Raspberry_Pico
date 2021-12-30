import picostdlib/[gpio, time]
import picostdlib
from math import round, pow
from sequtils import toSeq
from strutils import Letters

let randomGenVer* = "0.5.3"

var timeSeed: uint32 = 27121975

proc randomize*() = #Randomizes the variable with the bootstrap time 
  timeSeed = timeUs32()

proc random*(precision = 10): float = #make a random float number between 0..1 (set precision)
  const 
    a: uint32 = 1664525
    c: uint32 = 1013904223
    m: uint32 = uint32(pow(2.0, 31.0) - 1)
  timeSeed = uint32((a * timeSeed + c ) mod m)
  result = round(float(timeSeed) / float(m), precision)

proc randomInt*(min = 0, max = 100.0): int = #make a random integer numer between "min" and "max"
  while true:
    var numbIntRnd = int32(random() * max)
    if numbIntRnd >= min:
      return numbIntRnd

proc randomChar*(): char = #make a random char (a..z, A..Z)
  let seqLetters = toSeq(Letters)
  let numbIntRnd = randomInt(0,51)
  result = seqLetters[numbIntRnd]

#[ in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc) 
add--> (hardware_timer) ]#

#------------------------------------------------
when isMainModule:
  import sets
  stdioInitAll()
  sleep(2000)
  randomize()
  var kk: set[char]
  var mm: HashSet[int]
  print("Test Functios Char..." & '\n')
  for _ in 0..500:
    var jj = randomChar()
    if jj == 'a' or jj == 'A' or jj == 'z' or jj == 'Z':
      kk.incl(jj)
  print("--> " & $kk & '\n')
  print("Test Functios Int..." & '\n')
  for _ in 0..500:
    var jj = randomInt( 5, 50)
    if jj == 5 or jj == 50:
      mm.incl(jj)
  print("--> " & $mm & '\n')
  print("End!!" & '\n')


  
