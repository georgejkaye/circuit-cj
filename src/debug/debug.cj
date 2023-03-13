/**
 * debug/debug.cj
 *
 * This file contains functions that can be used to print debug information
 *
 * @author George Kaye
 * @since 0.1
 */
package debug
/** Whether the debug messages are printed */
var debugMessages = false
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
enum MessageType{ DEBUG | ERROR | WARNING | INFO | TODO }
extend MessageType <: ToString {
    public func toString(){
        match(this){
            case DEBUG   => "[DEBUG]"
            case ERROR   => "[ERROR]"
            case WARNING => "[WARNING]"
            case INFO    => "[INFO]"
            case TODO    => "[TODO]"
        }
    }
}
/**
 * Print a message to the console, in the form of
 *
 * [TYPE] This is a message
 *
 * @param mt The message type
 * @param msg The message to print
 */
func PrintMessage(mt : MessageType, msg : String) : Unit {
    println("${mt}: ${msg}")
}
/**
 * Print a [DEBUG] message, if debug messages are enabled.
 *
 * @param msg The message to print
 */
public func Debug(msg : String) : Unit {
    if(DebugMessagesOn()){
        PrintMessage(DEBUG, msg)
    }
}
/**
 * Print an [ERROR] message.
 * Does *not* halt execution.
 *
 * @param msg The message to print
 */
public func ErrorMsg(msg : String) : Unit {
    PrintMessage(ERROR, msg)
}
/**
 * Print a [WARNING] message.
 *
 * @param msg The message to print
 */
public func Warning(msg: String) : Unit {
    PrintMessage(WARNING, msg)
}
/**
 * Print an [INFO] message.
 *
 * @param msg The message to print
 */
public func Info(msg : String) : Unit {
    PrintMessage(INFO, msg)
}
/**
 * Print a [TODO] message.
 *
 * @param msg The message to print
 */
public func TodoMessage(msg : String) : Unit {
    PrintMessage(TODO, msg)
}