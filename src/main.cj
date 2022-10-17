import graphs.WriteDotToFile
import settings.*
import components.*
import debug.SetDebugMessages
import examples.gate.*

import syntax.*
import signatures.gate.*

main() {
    SetDebugMessages(true)
    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(false)

    let sig = gateLevelSignature

    let v = UseUnsignedSignalFromInt(10, width: 4)
    let circ = MakeSubcircuit(
        Array<InterfaceWire<GateLevelValue, GateLevelPrimitive>>(),
        [InterfaceWire(v, "")],
        ""
    )

    WriteDotToFile(circ, 1, "unsigned-1")





    // let wf = MakeWaveform([1, 2], FINITE_CLOSED, width: 4, signed: false)
    // WriteDotToFile(wf, 0, "wf-0")
    // WriteDotToFile(wf, 1, "wf-1")

    // let acc = Accumulator(width: 4, initial: 1)
    // WriteDotToFile(acc, 0, "acc-0")
    // WriteDotToFile(acc, 1, "acc-1")
    // let applied = Apply(acc, [wf])
    // WriteDotToFile(applied, 0, "acc-0")
    // WriteDotToFile(applied, 1, "acc-1")
    // RunCycle(applied)
    // WriteDotToFile(applied, 0, "acc-uf")

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
