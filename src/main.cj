from circuits import graphs.Traverse
from circuits import graphs.WriteDotToFile
from circuits import examples.Accumulator

from circuits import settings.*

main(){

    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let circ = Accumulator(width: 8, initial: 17)
    WriteDotToFile(circ, 1, "acc-1")
    WriteDotToFile(circ, 2, "acc-2")
    Traverse(circ, 1)

    return 0
}
