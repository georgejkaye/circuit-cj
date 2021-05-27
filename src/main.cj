import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")

    let circ = True() * False() + AndGate()

    WriteDotToFile(circ, "circ")
    print("${circ}\n")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}