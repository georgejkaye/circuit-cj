import graphs.WriteDotToFile
import rewrite.RewriteCombinational

import settings.*
import components.*
import debug.SetDebugMessages

import examples.*

main(){

    SetDebugMessages(true)
    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let circ = Accumulator(width: 2, initial: 1)
    WriteDotToFile(circ, 0, "acc-0")
    WriteDotToFile(circ, 1, "acc-1")

    return 0
}
