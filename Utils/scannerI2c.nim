import picostdlib/[gpio, i2c]
import picostdlib
from strutils import toHex
import picousb 

const i2cScanner = "1.0.0"
proc scan(i2cc: I2cInst, sda, scl: uint8): seq[string]
proc scanBlock(i2cc: I2cInst, pins: array[6, array[2, int]], ch: string )
proc vision(listAdd: seq[string])

proc scanBlock(i2cc: I2cInst, pins: array[6, array[2, int]], ch: string ) =
  var
    globalSeq: seq[string]
    sda: uint8
    scl: uint8
  print("Now Sacanning Blok " & ch & "..." &  '\n')
  for x in countup(0, len(pins)-1):
    sda = uint8(pins[x][0])
    scl = uint8(pins[x][1])
    print("*")
    globalSeq.add(scan(i2cc = i2cc, sda = sda,scl = scl))
  vision(globalSeq)

proc scan(i2cc: I2cInst, sda, scl: uint8): seq[string] =
  let
    data = "#"
    dataAdd = data[0].unsafeAddr
    dataLen = csize_t(data.len() * sizeof(data[0]))
    sdaF = sda.Gpio 
    sclF = scl.Gpio
  var
    i2cx: I2cInst = i2cc 
    valHex:string
    adduint8: uint8

  i2cx.init(100000)
  sdaF.setFunction(I2C); sdaF.pullUp()
  sclF.setFunction(I2c); sclF.pullUp()
  for devAdd in countup(1, 126):
    adduint8  = uint8(devAdd)
    var readAdd = i2cx.readBlocking(adduint8, dataAdd, dataLen, true)
    sleep(10)
    #print($readAdd)
    if readAdd > 0:
      valHex = toHex(devAdd)
      result.add("0x" & valHex[6..^1]  & " Gpio(" & $sdaF & " & " & $sclF & ")")
  sclF.setFunction(NULL); sclF.disablePulls()
  sdaF.setFunction(NULL); sdaF.disablePulls()
  i2cx.deinit()
  sleep(10)

proc vision(listAdd: seq[string]) =
  let lenList  = len(listAdd)
  print("" & '\n')
  if lenList == 0:
    print("No Devices Found in This Blok!!" & '\n' & '\n')
  else: 
   print($lenlist & " Device Found " & $listAdd & '\n')



stdioInitAll()


let usb = PicoUsb()
let a = [[0,1],[4,5],[8,9],[12,13],[16,17],[20,21]]
let b = [[2,3],[6,7],[10,11],[14,15],[18,19],[26,27]]
while  true:
  if usb.readLine != "":
    print('\n' & "=====================" & '\n')
    print("Start i2c Scanner ver " & i2cScanner & '\n')
    print("=====================" & '\n' & '\n')
    scanBlock(i2cc = i2c0, pins = a, ch = "i2c0")
    scanBlock(i2cc = i2c1, pins = b, ch = "i2c1")
    sleep(50)
  
    #in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc hardware_pwm) add--> (hardware_i2c)
    # use "go" to stat a scanner in your serial terminal (ex: cutecom); line termination = none
