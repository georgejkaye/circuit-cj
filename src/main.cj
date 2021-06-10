import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
 
    let circ = True() * Delay() * True() * Delay() + Join() * Join() + AndGate()
    WriteDotToFile(circ, "circ")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}