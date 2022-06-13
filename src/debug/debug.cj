/**
 * debug.cj
 *
 * This file contains functions that can be used to print debug information to the console
 */
package debug

/**
 * Debug settings
 */

/** Whether the debug messages are printed */
var debugMessages = true
/**
 * Toggle the debug messages on and off
 */
public func ToggleDebugMessages(){
    debugMessages = !debugMessages
}
/**
 * Set if the debug messages are on or off
 * @param b Whether the debug messages are on or off
 */
public func SetDebugMessages(b : Bool){
    debugMessages = b
}
/**
 * Check if the debug messages are on
 */
public func DebugMessagesOn(){
    debugMessages
}

enum MessageType{ DEBUG | ERROR | WARNING | INFO }
extend MessageType <: ToString {
    public func toString(){
        match(this){
            case DEBUG   => "[DEBUG]"
            case ERROR   => "[ERROR]"
            case WARNING => "[WARNING]"
            case INFO    => "[INFO]"
        }
    }
}

func PrintMessage(mt : MessageType, function : String, msg : String) : Unit {
    print("${mt}: ${function}: ${msg}\n")
}

public func Debug(fnc: String, msg : String) : Unit {
    if(DebugMessagesOn()){
        PrintMessage(DEBUG, fnc, msg)
    }
}

public func ErrorMsg(fnc : String, msg : String) : Unit {
    PrintMessage(ERROR, fnc, msg)
}

public func Warning(fnc: String, msg: String) : Unit {
    PrintMessage(WARNING, fnc, msg)
}

public func Info(fnc : String, msg: String) : Unit {
    PrintMessage(INFO, fnc, msg)
}