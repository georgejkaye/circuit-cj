import hypergraphs.*
import examples.*
import debug.*
import settings.*

func main(){
    // let a = SignedValueFromInt(1, width: 3)
    // let b = SignedValueFromInt(2, width: 3)
    // let v = Msbs(a)
    // WriteDotToFile(v, "dot/msbs.dot")

    SetDotFolder("dot")

    //let acc = Accumulator(width: 4, initial: 3)
    //let bit = 
    //WriteDotToFile(bit, "acc")

    let and : Hypergraph = AndGate()
    WriteDotToFile(and, "and")
    let not : Hypergraph = NotGate()
    WriteDotToFile(not, "not")
    let circ = (AndGate() * NotGate() * NotGate()) + ((NotGate() + NotGate()) * AndGate()) //((NotGate() + NotGate()) * AndGate())
    WriteDotToFile(circ, "circ")

    // let plus = Plus(a: a, b: b)
    // WriteDotToFile(plus, "dot/plus.dot")

    // let runsum = serial_multiplier_bit(width: 4)
    // WriteDotToFile(runsum, "dot/runsum.dot")

    // // let f = Fork()
    // // let s = Stub()
    // // let g = Seq(f, Par(NotGate(), s))
    // // WriteDotToFile(g, "dot/g.dot")
    // // let h = Seq(f, Par(NotGate(), s))
    // // WriteDotToFile(h, "dot/h.dot")
    // // let output = Concat([g,h])
    // // WriteDotToFile(output, "dot/output.dot")

    // //let a = UnsignedValueFromInt(24, width: 8)
    // //let msbs = Msbs(8)
    // //let lsb = Lsb(7)
    // //let c = Seq([a, msbs, lsb])

    
    // let acc = Accumulator(width: 8, initial: 1)
    // WriteDotToFile(acc, "dot/acc.dot")

    return 0
}