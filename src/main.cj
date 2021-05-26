import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")

    let circ = Fork() * (Stub() + Identity()) * NotGate() * Fork() * (Identity() + Stub())
    WriteDotToFile(circ, "circ")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}