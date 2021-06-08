import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
 
    let circ = Accumulator(width: 2, initial: 2)
    WriteDotToFile(circ, "circ")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}