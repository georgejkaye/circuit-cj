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

    let cpu = SimpleCPU()
    WriteDotToFile(cpu, 0, "cpu-0")
    WriteDotToFile(cpu, 1, "cpu-1")
    WriteDotToFile(cpu, 2, "cpu-2")

    let alu = ALU(8)
    WriteDotToFile(alu, 0, "alu-0")
    WriteDotToFile(alu, 1, "alu-1")
    WriteDotToFile(alu, 2, "alu-2")

    let a = MakeWire(8)
    let b = MakeWire(8)
    let and = MakeBitwiseGate(AND, 8)
    WriteDotToFile(and, 0, "and-0")
    WriteDotToFile(and, 1, "and-1")

    return 0
}
