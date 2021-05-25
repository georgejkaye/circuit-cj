/**
 * debug.cj
 *
 * This file contains functions that can be used to print debug information to the console
 */
package debug

import settings.*

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

func PrintMessage(mt : MessageType, function : String, msg : String) : Unit {
    print("${mt}: ${function}: ${msg}\n")
}

external func Debug(fnc: String, msg : String) : Unit {
    if(DebugMessagesOn()){
        PrintMessage(DEBUG, fnc, msg)
    }
}

external func ErrorMsg(fnc : String, msg : String) : Unit {
    PrintMessage(ERROR, fnc, msg)
}

external func Warning(fnc: String, msg: String) : Unit {
    PrintMessage(WARNING, fnc, msg)
}

external func Info(fnc : String, msg: String) : Unit {
    PrintMessage(INFO, fnc, msg)
}