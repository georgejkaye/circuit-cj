package debug

let debugMessages = true

enum MessageType{ DEBUG | ERROR }
append MessageType with ToString {
    func toString(mt : MessageType){
        match(mt){
            case $DEBUG => "[DEBUG]"
            case $ERROR => "[ERROR]"
        }
    }
}

func PrintMessage(mt : MessageType, function : String, msg : String){
    if(debugMessages){
        print("${mt}: ${function}: ${msg}\n")
    }
}

external func Debug(fnc: String, msg : String){
    PrintMessage(DEBUG, fnc, msg)
}

external func Error(fnc : String, msg : String){
    PrintMessage(ERROR, fnc, msg)
}