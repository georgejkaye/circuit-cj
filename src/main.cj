import graphs.WriteDotToFile
import settings.*
import components.*
import debug.SetDebugMessages
import examples.gate.*

import syntax.*
import signatures.gate.*

import rewrite.RunCycle

main() {
    SetDebugMessages(true)
    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let sig = gateLevelSignature

    let v0 = [FALSE, FALSE, FALSE, FALSE]
    let v1 = [FALSE, FALSE, FALSE, TRUE]
    let v2 = [FALSE, TRUE, FALSE, TRUE]
    let wf = MakeWaveform([2, 3, 4], FINITE_CLOSED, width: 4)

    let acc = Accumulator(width: 4, initial: 1)
    WriteDotToFile(acc, 0, "acc-0")
    WriteDotToFile(acc, 1, "acc-1")
    WriteDotToFile(acc, 2, "acc-2")
    let applied = Apply(acc, [wf])
    WriteDotToFile(applied, 0, "acc-0")
    WriteDotToFile(applied, 1, "acc-1")
    try {
        RunCycle(sig, applied, true)
        WriteDotToFile(applied, 0, "acc-cycle-1")
        RunCycle(sig, applied, true)
        WriteDotToFile(applied, 0, "acc-cycle-2")
    } catch(e : Exception) {
        WriteDotToFile(applied, 0, "break-0")
        WriteDotToFile(applied, 1, "break-1")
        throw NotImplemented("Crash!")
    }


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

