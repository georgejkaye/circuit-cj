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

    let acc = Accumulator(width: 2, initial: 1)
    WriteDotToFile(acc, 0, "acc-0-test")
    WriteDotToFile(acc, 1, "acc-1-test")

    return 0
}
