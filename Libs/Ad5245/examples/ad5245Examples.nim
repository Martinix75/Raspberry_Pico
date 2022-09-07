import picostdlib/[stdio, gpio, i2c, time]
import std/[strutils]
import ad5245
import picousb

stdioInitAll()
setupI2c(blokk = i2c1, psda = 18.Gpio, pscl = 19.Gpio, freq = 100_000) #max 400khz.
let potenz = newAd5245(blokk = i2c1, address = 0x2C, resValue = 5000) #set blol & address sugar mode.
## newAd5245() create the potentiometer object
## arguments:
## blokk = it is the block on the PR2040 (i2c0 or i2c1 watch the manual)
## address = address to which the device replies
## resValue = the value in Ohm that has the device


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
      ## setValue() Set the resistive value on the device
      ## arguments:
      ## data = 0 = Ohm, 255 = maximum residence value (uint8)
      
    of "setreswa":
      tempNumI = parseInt(splitList[1])
      potenz.setResWA(tempNumI)
      ## setResWA() set the resistive value on the device between terminal W and A
      ## arguments:
      ## ohmValue = resistive value in Hom
      
    of "setreswb":
      tempNumI = parseInt(splitList[1])
      potenz.setResWB(tempNumI)
      ## setResWB() set the resistive value on the device between terminal W and B
      ## arguments:
      ## ohmValue = resistive value in Hom
      
    of "setvoltage":
      tempNumF = parseFloat(splitList[1])
      potenz.setVoltage(tempNumF, voltA=3.3)
      ## setVoltage() set the desired voltage on the PIN W (works as a voltage divider)
      ## arguments:
      ## vOut = Value of the deserved voltage (< voltA)
      ## voltA = input voltage (do not exceed 5vcc)
      ## voltB = voltage possibly present on B (of default = 0V --> GND)
      
    of "getreswa":
      print("The resistance between A&W is of: " & $potenz.getResWA() & " Ohm" & '\n')
      ## getResWA() return the value in Ohm set between W and A
      ## arguments:
      ## none
    of "getreswb":
      print("The resistance between B&W is of: " & $potenz.getResWB() & " Ohm" & '\n')
      ## getResWA() return the value in Ohm set between W and B
      ## arguments:
      ## none
      
    of "getvalue":
      print("The value in the register is of: " & $potenz.getvalue() & " Number" & '\n')
      ## getvalue() return the numerical value written in the register (0..255; Uint8)
      ## arguments:
      ## none
      
    of "ver":
      print("Lib ad5425 Version is: " & ad5245Ver & '\n')
    else:
      print("!!! Command NOT found !!!" & '\n')
  sleep(50)
