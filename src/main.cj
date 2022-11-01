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
    return 0
}

