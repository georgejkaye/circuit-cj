from circuits import graphs.Traverse
from circuits import graphs.WriteDotToFile
from circuits import examples.Accumulator

from circuits import settings.*
from circuits import graphs.Edge

from circuits import examples.ALU

main(){

    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let circ = ALU(8)
    WriteDotToFile(circ, 1, "alu")
    Traverse(circ, 1)

    return 0
}
