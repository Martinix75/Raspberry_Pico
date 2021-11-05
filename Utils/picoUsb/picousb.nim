import picostdlib
const picousbVer* = "0.1.0"

type
    PicoUsb*  = ref object 
      setBool:bool
      stringX:string

proc readLineInternal(self:PicoUsb,time:uint32=200)= #proc lettura generale di una stringa.
    var readCh:char
    while true: #gira finche non trovi 0xff (255).
      readCh = getCharWithTimeout(time) #salva il carattere nella variabile.
      if readCh == '\255': #se trivi 255..
        break #interrompi il while!
      else: #se non trovi 255...
        self.stringX.add($readCh) #aggiungi il carattere in stringX dopo averlo convertito.

proc setRedy(self:PicoUsb)= #proc per settare se ce qualcosa o no nel buffer usb.
    readLineInternal(self) #leggi usando la funzione privata.
    if self.stringX.len > 0: #se la stringa non è "vuota..
        self.setBool = true #setta la variabile a true.
    else: #altriment....
        self.setBool = false #false se la stringa è vuota.

#----- pubblic functions --------
proc isRedy*(self:PicoUsb):bool= #proc per il controllo dello stato.
    setRedy(self) #chaima la funzione per settare la variabile.
    return self.setBool #ritorna il valore.

proc readLine*(self:PicoUsb,time:uint32=200):string=
    readLineInternal(self, time) #leggi con al funziona apposita.
    result = self.stringX #manda la stringa completa.
    self.stringX = "" #resetta (porta a 0) stringx.