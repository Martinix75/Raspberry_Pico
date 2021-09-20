import picostdlib/[gpio, i2c]
import picostdlib
import strutils
import sets
import picousb 

stdioInitAll()
const i2cScanner = "0.1.0"
const sda = 0.Gpio #set GP0 = sda
const scl = 1.Gpio #set GP1 = scl
let usb = PicoUsb()
#const addDev = 39
var dato = "scan"
var adx: HashSet[string] #make hashset for the strings

i2c0.init(100000) #init block i2c0
sda.setFunction(I2C); sda.pullUp() #set GPO i2c, pull up on
scl.setFunction(I2C); scl.pullUp() #set GPO i2c, pull up on
let dataAdd = dato[0].unsafeAddr #found adress of first element in seq/string/array...
let lenData = csize_t(dato.len*sizeof(dato[0])) #calculates the size of the data 

while true:
  if usb.readLine == "go": #wait for the "go" from serial
    print("Start i2c Scanner..." & '\n')
    for addDevx in 1..126: #scan address fron 1 to 126 (int)
      var addDev = uint8(addDevx) #convert int--> uint8
      var result = i2c0.readBlocking(addDev, dataAdd, lenData, true) #no device retyrn -2 else 4(in this case)
      #print("val: "& $f & '\n')
      if result > 0:
        var hex = toHex(addDevx) #convert uint8 --> string
        adx.incl(hex) #add a found address
    
  
      sleep(100)
    var numElem = adx.len() #calculates the number of elements in num
    print("I Found " & $numElem & " Devices @ Aderess: "   & $adx & "HEX" & '\n')

    #in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc hardware_pwm) add--> (hardware_i2c)
    # use "go" to stat a scanner in your serial terminal (ex: cutecom); line termination = none