/**
 * settings.cj
 *
 * This file contains various settings and options
 */

package settings

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

/** 
 * Dot settings 
 */

/* The string to use as a tab */
public let tab = "  "

/* Whether to display debug information on the dot graph */
var debugDot = false
/**
 * Toggle the debug dot on and off
 */
public func ToggleDebugDot(){
    debugDot = !debugDot
}
/**
 * Set if the generated dot should contain debug information
 */
public func SetDebugDot(b : Bool){
    debugDot = b
}
/**
 * Check if debug dot information should be printed
 */
public func DebugDotOn(){
    debugDot
}

/* The director the dot files are put in */
var dotDir = ""  
/**
 * Set the directory the dot files are put in
 * @param dir The new directory
 */
public func SetDotDir(dir : String){
    dotDir = dir
    println("The dot directory has been set to ${dir}")
}
/**
 * Get the dot output file path (relative to the project root) with extension
 * @param filename The string to use as the filename
 * @return The file path with directory and .dot extension
 */
public func GetDotFile(filename : String){
    if(dotDir == ""){
        "${filename}.dot"
    } else {
        "${dotDir}/${filename}.dot"
    }
}