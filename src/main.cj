from circuits import graphs.*
from circuits import syntax.*
from circuits import prelude.*
from circuits import settings.*
from circuits import components.*
from circuits import arithmetic.*
from circuits import examples.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(false)
    SetDotNumberRepresentation(DEC)

    let input1 = Wire(8)
    let input2 = Wire(8)

    let acc = Accumulator(initial: 24, width: 8)

    let not = NotGate(input1)
    let acced = Subcircuit(acc, [not])
    let and = AndGate(input2, acced[0])
    
    let circuit = MakeCircuit([input1, input2], [and])
    WriteDotToFile(circuit, "circuit")

    return 0
}