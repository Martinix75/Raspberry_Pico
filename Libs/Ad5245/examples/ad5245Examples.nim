import picostdlib/[stdio, gpio, i2c, time]
import std/[strutils]
import ad5245
import picousb

stdioInitAll()
setupI2c(blokk = i2c1, psda = 18.Gpio, pscl = 19.Gpio, freq = 100_000) #max 400khz.
let potenz = newAd5245(i2c = i2c1, address = 0x2C, resValue = 5000) #set blol & address sugar mode.
let usb = PicoUsb() #for comication whit ad5425

var
  usbVal: string
  splitList: seq[string]
  tempNum8: uint8
  tempNumF: float
  tempNumI: int
while true:
  if usb.isReady == true:
    usbVal = usb.readLine()
    splitList = split(usbVal, '#')
    case splitList[0] 
    of "setvalue":
      tempNum8 = uint8(parseInt(splitList[1]))
      potenz.setValue(tempNum8)
      
    of "setreswa":
      tempNumI = parseInt(splitList[1])
      potenz.setResWA(tempNumI)
      
    of "setreswb":
      tempNumI = parseInt(splitList[1])
      potenz.setResWB(tempNumI)

    of "setvoltage":
      tempNumF = parseFloat(splitList[1])
      potenz.setVoltage(tempNumF, voltA=3.3)
      
    of "getreswa":
      print("The resistance between A&W is of: " & $potenz.getResWA() & " Ohm" & '\n')
 
    of "getreswb":
      print("The resistance between B&W is of: " & $potenz.getResWB() & " Ohm" & '\n')

    of "getvalue":
      print("The value in the register is of: " & $potenz.getvalue() & " Number" & '\n')

      
    of "ver":
      print("Lib ad5425 Version is: " & ad5245Ver & '\n')
    else:
      print("!!! Command NOT found !!!" & '\n')
  sleep(50)
