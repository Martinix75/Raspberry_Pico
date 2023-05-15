# modulo dove inserire le immagini!!! x test solo 1.
import picostdlib/[stdio, time] #solo per test
stdioInitAll() # solo per test poi cancella
type 
  ImageDisplay* = object
    #byteImg*: array[0..15, uint] #nonnsi sa quanti bit quindi usa uint e no byte!!
    byteImg*:seq[uint] #nonnsi sa quanti bit quindi usa uint e no byte!!
    xSizeImg*, ySizeImg*: int

const #qui metti le immagini...
  img1 = @[0x7FFF, 0x7FF8, 0x7FC0, 0x7E00, 0x7E00, 0x7E00, 0x43E0, 0x77FE, 0x6FFE, 0x43E0, 0x7E00, 0x7E00, 0x7E00, 0x7FC0, 0x7FF8, 0x7FFF]
  iom1 = @[0x7FE7, 0xFFF7, 0x7FE7, 0x0, 0x0, 0x3C0, 0xFF0, 0x1FF8, 0x3C3C, 0x781E, 0x700E,0xE007, 0xE007,0x700E,0x380E, 0x3c3C, 0x1FF8, 0xFF0,
          0x3C0, 0x0, 0x0, 0x7FFe, 0xFFFF, 0x7FFe, 0x0, 0x0, 0x3FE, 0x7FF, 0x3FE, 0x0, 0x0, 0x7FFE, 0xFFFF, 0x7FFE]

proc initImg*(nameImg = "img1"): ImageDisplay =
  #print("initImg....")
  var 
    ct: seq[int] #crea la sequenza dove contenere l'immagine scelta
    xSize, ySize : int #variabili per valori x e y (dimensioni immagine)
  case nameImg #da qui selezione l'immagine
  of "img1":
    ct = img1
    xSize=len(img1); ySize= 16
  of "iom1":
    ct = iom1
    xSize=len(iom1); ySize = 16
  else:
    print("no image!!")
  var tempArray = newSeq[uint](len(ct)) #sequanza tempoarane per conversione uint--> int
  #print("Len= " & $len(ct))
  for k in 0..<len(ct):
    tempArray[k] = uint(ct[k]) #converti int-->uint
  #print("End: " & $tempArray)
  result = ImageDisplay(byteImg: tempArray, xSizeImg: xSize, ySizeImg: ySize)
