import graphs.WriteDotToFile
import rewrite.RewriteCombinational

import settings.*
import components.*
import debug.SetDebugMessages
import rewrite.*

import examples.*

main(){

    SetDebugMessages(true)
    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let circ = Accumulator(width: 2, initial: 1)
    WriteDotToFile(circ, 0, "acc")
    InstantFeedback(circ)
    Unfold(circ)
    WriteDotToFile(circ, 0, "acc-fb")

    // let zero = InfiniteWaveform(TrueSignal())
    // let other = UseWire(1)
    // let circ = MakeSubcircuit(
    //     [InterfaceWire(other, "A")],
    //     [InterfaceWire(zero, "Z"), InterfaceWire(other, "A")],
    //     "test"
    // )
    // let t = TrueSignal()
    // let w = UseWire(1)
    // let and = And(w, t)
    // Feedback(and, w)
    // let circ = MakeSubcircuit([], [InterfaceWire(and, "Z")], "test")

    // let a = UseWire(1)
    // let b = UseWire(1)
    // let c = UseWire(1)
    // let not1 = Not(b)
    // let not2 = Not(a)
    // Feedback(not1, a)
    // let circ = MakeSubcircuit([InterfaceWire(b, "B"), InterfaceWire(c, "C")], [InterfaceWire(c, "C"), InterfaceWire(not2, "Z")], "test")

    // WriteDotToFile(circ, 0, "test")
    // InstantFeedback(circ)
    // WriteDotToFile(circ, 0, "test-fb")
    // Unfold(circ)
    // WriteDotToFile(circ, 0, "test-uf")

    return 0
}
