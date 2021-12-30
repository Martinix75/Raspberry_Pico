import picostdlib/[gpio, time]
import picostdlib
import random

stdioInitAll()
sleep(2000)
randomize()
const slp = 50
print("Test Number Generator " & randomGenVer & '\n')
sleep(1000)
for _ in 0..5:
  print("1- Creating a Sequence With 15 Chars" & '\n')
  for c in 0..50:
    var x = randomChar()
    print($x & ", ")
    sleep(slp)
  print("" & '\n')

  print("2- Creating a Sequence With 15 Integer Numbers" & '\n')
  for c in 0..50:
    var x = randomInt()
    print($x & ", ")
    sleep(slp)
  print("" & '\n')

  print("3- Creating a Sequence With 15 Normalized Numbers" & '\n')
  for c in 0..50:
    var x = random()
    print( $x & ", ")
    sleep(slp)
  print("" & '\n')
  print("-------------------------" & '\n')
print("End!" & '\n')
 
