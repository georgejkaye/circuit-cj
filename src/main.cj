import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")

    let comb = HalfAdderCombinator()
    WriteDotToFile(comb, "comb")

    let fun = HalfAdderFunctional()
    WriteDotToFile(fun, "fun")

    let acc = Accumulator(width: 4, initial: 6)
    // Draw without resolving links 
    WriteDotToFile(acc, "acc", resolve: false)
    // Draw with resolving links
    WriteDotToFile(acc, "res", resolve: true)

    let mult = serial_multiplier_bit(width: 4)
    // Draw without resolving links
    WriteDotToFile(mult, "mult", resolve: false)
    // Draw with resolving links
    WriteDotToFile(mult, "mult-resolved", resolve: true)
    // Expose only the "loop" bus
    WriteDotToFile(mult.Get("loop"), "mult-extract")

    return 0
}