from circuits import settings.*
from circuits import syntax.*
from circuits import graphs.WriteDotToFile
from circuits import components.*
from circuits import examples.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(false)
    SetDotNumberRepresentation(DEC)

    let alu = ALU(2)
    WriteDotToFile(alu, 0, "alu")
    WriteDotToFile(alu, 1, "alu-expand-1")
    WriteDotToFile(alu, 2, "alu-expand-2")

    return 0
}
