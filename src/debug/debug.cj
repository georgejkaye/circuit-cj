package debug

let debugMessages = true

external func Debug(msg : String){
    if(debugMessages){
        print("[DEBUG]: ${msg}\n")
    }
}