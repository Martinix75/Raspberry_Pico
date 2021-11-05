import picostdlib/[gpio]
import picostdlib
#import martin
import picousb

stdioInitAll()

var serialUsb = PicoUsb()
sleep (2800)
print("Picousb Ver: "& picousbVer)

while  true:
  if serialUsb.isRedy == true:
    var xx = serialUsb.readLine
    print(xx)
