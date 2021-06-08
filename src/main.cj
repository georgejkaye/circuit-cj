import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
 
    let circ = Register(width: 4, initial: 7)
    WriteDotToFile(circ, "circ")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}