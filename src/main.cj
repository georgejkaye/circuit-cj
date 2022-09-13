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
    SetDebugDot(false)

    // let circ = Accumulator(width: 2, initial: 1)
    // WriteDotToFile(circ, 0, "acc")
    // InstantFeedback(circ)
    // WriteDotToFile(circ, 0, "acc-fb")

    let zero = InfiniteWaveform(TrueSignal())
    let circ = MakeSubcircuit([], [InterfaceWire(zero, "Z")], "test")

    WriteDotToFile(circ, 0, "test")
    InstantFeedback(circ)
    WriteDotToFile(circ, 0, "test-fb")

    return 0
}
