#[
Driver for digital potentiometer Ad5245 write in Nim.
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6

author Andrea Martin (Martinix75)
https://github.com/Martinix75/Raspberry_Pico/tree/main/Libs/Ad5245
]#

import picostdlib/[i2c]
from math import round

const ad5245Ver* = "1.1.1"
const resW = 2*50 #value of teh wiper contact resistence.

type #new type for the ad5245
  Ad5245 = ref object
    address: uint8
    i2c: I2cInst
    resValue: int
    
#---------- Proc Prototype ----------
proc newAd5245*(i2c: I2cInst, address: uint8, resValue: int): Ad5245
proc writeAd5245(self: Ad5245, data: uint8, instruction: uint8 = 0)
proc setValue*(self: Ad5245, data: var uint8)
proc setInstruction*(self: Ad5245, instruction: uint8)
proc setResWA*(self: Ad5245, ohmValue: var int)
proc setResWB*(self: Ad5245, ohmValue: var int)
proc setVoltage*(self: Ad5245, vOut: var float, voltA: float, voltB: float = 0.0)
proc calculateValWA(self: Ad5245, ohmValue: int): uint8
proc calculateValWB(self: Ad5245, ohmValue: int): uint8
proc getResWA*(self: Ad5245): int
proc getResWB*(self: Ad5245): int
proc getValue*(self: Ad5245): uint8
#---------- End Poc Prototype --------

#---------- Start Private Pocs -------
proc writeAd5245(self: Ad5245, data: uint8, instruction: uint8 = 0) = #write 2 Byte in Ad5245 gneric procedure.
  let arrayData = [instruction, data] #make array with two bytes (instruction , data)
  let addressElement1 = arrayData[0].unsafeAddr #find the address of the first element in the array
  writeBlocking(self.i2c, self.address, addressElement1, 2, true) #write in to I2C (2 Bytes)
  
proc calculateValWA(self: Ad5245, ohmValue: int): uint8 = # calculate the value to go to the Ad5245 calculating (W-A)
  result = uint8(round(-(((256*ohmValue)-(256*resW)-(256*self.resValue))/self.resValue)-2))

proc calculateValWB(self: Ad5245, ohmValue: int): uint8 = # calculate the value to go to the Ad5245 calculating (W-B)
  result = uint8(round(((256*ohmValue)-(256*resW))/self.resValue))+1
#---------- End Private Pocs ---------

#---------- Start Pubblic Procs ------
proc newAd5245*(i2c: I2cInst, address: uint8, resValue: int): Ad5245 = #initialize the type Ad5245
  ## Ad5245 initialize
  ##
  runnableExamples:
    newAd5245(i2c=i2c0, address=0x2C, resValue=5000)
  ## **Parameters:**
  ## - *i2c* = name of the block where the display connected (i2c0 or i2c1).
  ## - *address* = hardware address of the display.
  ## - *resValue* = value in Ohm of the potentiometer.
  result = Ad5245(i2c: i2c, address: address, resValue: resValue) #blok and adress 

proc setInstruction*(self: Ad5245, instruction: uint8) = #proc from write instructions see manale Ad5245
  let valueoOk = [uint8(64), uint8(32)] # 64 = RS (restet wiper to midle scale) 32 = SD open A-W
  if instruction in valueoOk:
    self.writeAd5245(data = uint8(0), instruction = instruction)
    
proc setValue*(self: Ad5245, data: var uint8) = #set the value 0 = RESmin, 255 = RESmax
  ## Set the numerical value (0-255) of the potentiometer.
  ##
  runnableExamples:
    self.setValue(75)
  ## **Parameters:**
  ## - *data* = set the numerical value that the potentiometer can take (it is not the Hominic value)
  self.writeAd5245(data) #call proc for write in Ad5245
  
proc setResWA*(self: Ad5245, ohmValue: var int) = #proc to set the value of the nominal resistance between B and W
  ## Set the resistance (in Ohm) between the W terminal and A.
  ##
  runnableExamples:
    self.setResWA(2500)
  ## **Parameters:**
  ## - *homValue* = value in Ohm of the resistance to be set between W and A.
  if ohmValue > self.resValue:
    ohmValue = self.resValue
    self.writeAd5245(self.calculateValWA(ohmValue))
  elif ohmValue <= 0:
    self.setInstruction(32)
  else:
    self.writeAd5245(self.calculateValWA(ohmValue))

proc setResWB*(self: Ad5245, ohmValue: var int) = #proc to set the value of the nominal resistance between A and W
  ## Set the resistance (in Ohm) between the W terminal and B.
  ##
  runnableExamples:
    self.setResWB(1500)
  ## **Parameters:**
  ## - *homValue* = value in Ohm of the resistance to be set between W and B.
  if ohmValue > self.resValue:
    ohmValue = self.resValue
    self.writeAd5245(self.calculateValWB(ohmValue))
  elif ohmValue <= 0:
    self.setInstruction(32)
  else:
    self.writeAd5245(self.calculateValWB(ohmValue))

proc setVoltage*(self: Ad5245, vOut: var float, voltA: float, voltB: float = 0.0) = #proc for set the voltage (partiton of V).
  ## Set the desidered voltage on the pin W (works as a voltage divider).
  ##
  runnableExamples:
    self.setVoltage(vOut = 1.5, voltA = 3.3)
  ## **Parameters:**
  ## - *vOut* = desired output voltage.
  ## - *voltA* = input voltage on pin A (<= Power supply voltage of the AD5245).
  ## - *voltB* = voltage present on PIN B (usually = 0V).
  if vOut >= (voltA-voltB):
    vOut = voltA-0.1
  var value = uint8(((-256*vOut)-(256*voltA))/(voltB-voltA))
  self.setValue(data = value)
  
proc getResWA*(self: Ad5245): int = #proc for read value write in ad5245 in Ohm
  ## Return the value in Ohm set between W and A.
  ##
  runnableExamples:
    self.getResWA()
  ## **Return:**
  ## - *int (Hom).*
  let resValueFloat = float(self.resValue)
  var readValue: array[0..1, int]
  let addressElement1 = readValue[0].unsafeAddr
  discard readBlocking(self.i2c, self.address, addressElement1, 1, false)
  result = int((((256-readValue[0])/256)*resValueFloat)+resW) #from value calculate value of resistance

proc getResWB*(self: Ad5245): int = #proc for read value write in ad5245 in Ohm
  ## Return the value in Ohm set between W and B.
  ##
  runnableExamples:
    self.getResWA()
  ## **Return:**
  ## - *int (Ohm).*
  let resValueFloat = float(self.resValue)
  var readValue: array[0..1, int]
  let addressElement1 = readValue[0].unsafeAddr
  discard readBlocking(self.i2c, self.address, addressElement1, 1, false)
  result = int((((readValue[0])/256)*resValueFloat)+resW) #from value calculate value of resistance

proc getValue*(self: Ad5245): uint8 = #return the value write in register.
  ## return the numerical value writen in the  register.
  ## 
  runnableExamples:
    self.getValue()
  ## **Return:**
  ## - *uint8 (0-255).*
  var readValue: array[0..1, uint8]
  let addressElement1 = readValue[0].unsafeAddr
  discard readBlocking(self.i2c, self.address, addressElement1, 1, false)
  result = readValue[0]
#---------- Start Pubblic Procs ---------

#[when isMainModule:
  import picostdlib/[stdio, gpio, time]
  from std/strutils import parseInt, parseFloat
  import picousb 
  stdioInitAll()
  setupI2c(blokk = i2c1, psda = 18.Gpio, pscl = 19.Gpio, freq = 100_000)#max 400khz
  let pot = newAd5245(i2c = i2c1, address = 0x2C, resValue = 5000)
  let usb = PicoUsb()
  var value: uint8
  var ohmm: int
  var voutk:  float
  while  true:
    if usb.isReady == true:
      print("Inserisci il valore in Vout desiderato")
      var valore:string = usb.readLine()
      if valore == "ver":
        print("Versione Lib Ad5245: " & ad5245Ver & '\n')
      else: 
        print("Ricevuto: " & $repr(valore))
        try:
          value= uint8(parseInt(valore))
          ohmm = parseInt(valore)
        except:
          voutk = parseFloat(valore)
          print("SVoutk= " & $voutk & '\n')
        pot.setResWA(ohmm)
        var resletta = pot.getResWA()
        print("Settato R= " & $resletta & " Ohm" & '\n')
        print("Valore Uint 8 nel registro: " & $pot.getValue() & '\n')
      sleep(50)]#
