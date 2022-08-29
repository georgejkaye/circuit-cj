from circuits import graphs.WriteDotToFile
from circuits import rewrite.RewriteCombinational

from circuits import settings.*
from circuits import components.*
from circuits import debug.SetDebugMessages

from circuits import examples.*

main(){

    SetDebugMessages(true)
    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let acc = Accumulator(width: 2, initial: 1)
    WriteDotToFile(acc, 0, "acc-0")
    WriteDotToFile(acc, 1, "acc-1")

    return 0
}
