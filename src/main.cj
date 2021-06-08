import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
 
    let circ = True() + Accumulator(width: 1, initial: 0)
    WriteDotToFile(circ, "circ")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}