import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
 
    let a = UnsignedValueFromInt(10, width: 4)
    WriteDotToFile(a, "a")
    let b = UnsignedValueFromInt(2, width: 4)
    WriteDotToFile(b, "b")

    let circ = Plus(a : UnsignedValueFromInt(10, width: 4), b: UnsignedValueFromInt(2, width: 4))

    WriteDotToFile(circ, "circ")
    let red = TestRewrites(circ)
    WriteDotToFile(red, "red")

    return 0
}