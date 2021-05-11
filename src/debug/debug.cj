package debug

let debugMessages = false

enum MessageType{ DEBUG | ERROR | WARNING | INFO }
append MessageType with ToString {
    func toString(mt : MessageType){
        match(mt){
            case $DEBUG   => "[DEBUG]"
            case $ERROR   => "[ERROR]"
            case $WARNING => "[WARNING]"
            case $INFO    => "[INFO]"
        }
    }
}

func PrintMessage(mt : MessageType, function : String, msg : String){
    print("${mt}: ${function}: ${msg}\n")
}

external func Debug(fnc: String, msg : String){
    if(debugMessages){
        PrintMessage(DEBUG, fnc, msg)
    }
}

external func Error(fnc : String, msg : String){
    PrintMessage(ERROR, fnc, msg)
}

external func Warning(fnc: String, msg: String){
    PrintMessage(WARNING, fnc, msg)
}

external func Info(fnc : String, msg: String){
    PrintMessage(INFO, fnc, msg)
}