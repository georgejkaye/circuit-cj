import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")

    let acc = Accumulator(width: 4, initial: 6)
    WriteDotToFile(acc, "acc")
    WriteDotToFile(acc.ResolveLinks(), "res")

    let mult = serial_multiplier_bit(width: 4)
    WriteDotToFile(mult, "mult")
    WriteDotToFile(mult.ResolveLinks(), "mult-resolved")
    WriteDotToFile(mult.Get("loop"), "mult-extract")

    return 0
}