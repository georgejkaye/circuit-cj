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
    WriteDotToFile(circ, 0, "acc-copy")

    return 0
}
