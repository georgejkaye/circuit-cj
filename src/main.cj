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
    SetDebugDot(false)

    let alu = ALU(2)
    WriteDotToFile(alu, 1, "alu")

    let circ = AddSub(2)
    WriteDotToFile(circ, 0, "circ-0")
    WriteDotToFile(circ, 1, "circ-1")

    return 0
}
