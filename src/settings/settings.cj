/**
 * settings.cj
 *
 * This file contains various settings and options
 */

package settings

import debug.*

/** 
 * Dot settings 
 */

/* The string to use as a tab */
public let tab = "  "

/* Whether to display debug information on the dot graph */
var debugDot = false

func DebugDotInfo(){
    Info("ToggleDebugDot", "Dot debug information has been toggled ${if(debugDot) { "on" } else { "off" }}")
}

/**
 * Toggle the debug dot on and off
 */
public func ToggleDebugDot(){
    debugDot = !debugDot
    DebugDotInfo()
}
/**
 * Set if the generated dot should contain debug information
 */
public func SetDebugDot(b : Bool){
    debugDot = b
    DebugDotInfo()
}
/**
 * Check if debug dot information should be printed
 */
public func IsDebugDot(){
    debugDot
}

public enum NumberRepresentation {
    | BIN
    | DEC
}

var dotNumberRepresentation = BIN
public func GetDotNumberRepresentation() : NumberRepresentation {
    dotNumberRepresentation
}

public func SetDotNumberRepresentation(rep : NumberRepresentation) : Unit {
    dotNumberRepresentation = rep
}

/* The director the dot files are put in */
var dotDir = ""  
/**
 * Set the directory the dot files are put in
 * @param dir The new directory
 */
public func SetDotDir(dir : String){
    dotDir = dir
    Info("SetDotDir", "The dot directory has been set to ${dir}")
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