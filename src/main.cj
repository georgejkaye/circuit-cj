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

    let acc = Accumulator(width: 4, initial: 3)
    WriteDotToFile(acc, "acc")

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