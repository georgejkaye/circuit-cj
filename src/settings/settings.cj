/**
 * settings.cj
 *
 * This file contains various settings and options
 */

package settings

var dotDir = ""  

external func SetDotFolder(dir : String){
    dotDir = dir
}

external func GetDotFile(filename : String){
    if(dotDir == ""){
        "${filename}.dot"
    } else {
        "${dotDir}/${filename}.dot"
    }
}