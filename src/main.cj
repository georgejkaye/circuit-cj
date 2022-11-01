import graphs.WriteDotToFile
import settings.*
import components.*
import debug.SetDebugMessages
import examples.gate.*

import syntax.*
import signatures.gate.*

import rewrite.Rewriter

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

    // let acc = Accumulator(width: 4, initial: 1)
    // WriteDotToFile(acc, 0, "acc-0")
    // WriteDotToFile(acc, 1, "acc-1")
    // WriteDotToFile(acc, 2, "acc-2")
    // let applied = Apply(acc, [wf])
    // WriteDotToFile(applied, 0, "acc-0")
    // WriteDotToFile(applied, 1, "acc-1")

    // let rw = Rewriter(sig, applied)
    // try {
    //     rw.RunCycle(true)
    //     WriteDotToFile(applied, 0, "acc-cycle-1")
    //     rw.RunCycle(true)
    //     WriteDotToFile(applied, 0, "acc-cycle-2")
    // } catch(e : Exception) {
    //     WriteDotToFile(applied, 0, "break-0")
    //     WriteDotToFile(applied, 1, "break-1")
    //     throw NotImplemented("Crash!")
    // }

    let a = sig.UseWire(4)
    let b = sig.UseWire(4)
    let and = And(a, b)

    let wf2 = UseOpenWaveform([2,3,4], and, width: 4)
    let circ = MakeSubcircuit(
        Array<InterfaceWire<GateLevelValue, GateLevelPrimitive>>(),
        [InterfaceWire(wf2, "")],
        "test"
    )
    WriteDotToFile(circ, 1, "wf2")
    let rw = Rewriter(sig, circ)
    rw.RunCycle(1, true)
    WriteDotToFile(circ, 1, "wf2-1")
    rw.RunCycle(2, true)
    WriteDotToFile(circ, 1, "wf2-2")
    rw.RunCycle(3, true)
    WriteDotToFile(circ, 1, "wf2-3")
    rw.RunCycle(4, true)
    WriteDotToFile(circ, 1, "wf2-4")

    return 0
}

