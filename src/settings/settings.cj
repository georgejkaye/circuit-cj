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
var debugMessages = false
/**
 * Toggle the debug messages on and off
 */
external func ToggleDebugMessages(){
    debugMessages = !debugMessages
}
/**
 * Set if the debug messages are on or off
 * @param b Whether the debug messages are on or off
 */
external func SetDebugMessages(b : Bool){
    debugMessages = b
}
/**
 * Check if the debug messages are on
 */
external func DebugMessagesOn(){
    debugMessages
}

/** 
 * Dot settings 
 */

/* The string to use as a tab */
external let tab = "  "

/* Whether to display debug information on the dot graph */
var debugDot = false
/**
 * Toggle the debug dot on and off
 */
external func ToggleDebugDot(){
    debugDot = !debugDot
}
/**
 * Set if the generated dot should contain debug information
 */
external func SetDebugDot(b : Bool){
    debugDot = b
}
/**
 * Check if debug dot information should be printed
 */
external func DebugDotOn(){
    debugDot
}

/* The director the dot files are put in */
var dotDir = ""  
/**
 * Set the directory the dot files are put in
 * @param dir The new directory
 */
external func SetDotDir(dir : String){
    dotDir = dir
}
/**
 * Get the dot output file path (relative to the project root) with extension
 * @param filename The string to use as the filename
 * @return The file path with directory and .dot extension
 */
external func GetDotFile(filename : String){
    if(dotDir == ""){
        "${filename}.dot"
    } else {
        "${dotDir}/${filename}.dot"
    }
}