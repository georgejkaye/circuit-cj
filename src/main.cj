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

    // let cpu = SimpleCPU()
    // WriteDotToFile(cpu, 0, "cpu")
    // WriteDotToFile(cpu, 1, "cpu-expand-1")

    let alu = ALU(8)
    WriteDotToFile(alu, 0, "alu-0")
    WriteDotToFile(alu, 1, "alu-1")
    WriteDotToFile(alu, 2, "alu-2")

    return 0
}
