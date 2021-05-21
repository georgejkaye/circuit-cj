import hypergraphs.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotFolder("dot")

    let a = SignedValueFromInt(1, width: 1)
    let b = SignedValueFromInt(0, width: 1)
    // WriteDotToFile(v, "msbs")
    // //let acc = Accumulator(width: 4, initial: 3)
    // //let bit = 
    // //WriteDotToFile(bit, "acc")

    // let and : Hypergraph = AndGate()
    // WriteDotToFile(and, "and")
    // let not : Hypergraph = NotGate()
    // WriteDotToFile(not, "not")
    // let circ = (AndGate() * NotGate() * NotGate()) + ((NotGate() + NotGate()) * AndGate()) //((NotGate() + NotGate()) * AndGate())
    // WriteDotToFile(circ, "circ")

    //let plus = HalfAdder(a: a, b: b, sum: "sum", carry: "carry")
    //WriteDotToFile(plus, "plus")
    //let plus2 = HalfAdder(a: a, b: b, sum: "sum2", carry: "carry2") 
    //WriteDotToFile(plus2, "plus2")

    //let comb = HalfAdderCombinator()
    //WriteDotToFile(comb, "comb")

    // let add = HalfAdderFunctional()
    // WriteDotToFile(add, "func")

    //let runsum = serial_multiplier_bit(width: 4)
    //WriteDotToFile(runsum, "dot/runsum.dot")
    
    let acc = Accumulator(width: 2, initial: 1)
    WriteDotToFile(acc, "dot/acc.dot")

    //let circ = Concat([plus, plus2])
    //WriteDotToFile(circ, "circ")

    return 0
}