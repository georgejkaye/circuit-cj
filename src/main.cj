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
    SetDebugDot(true)
    SetDotNumberRepresentation(DEC)

    let input1 = Wire(8)
    let input2 = Wire(8)

    let not = NotGate(input1)
    let and = AndGate(input2, not)
    
    let circuit = MakeCircuit([input1, input2], [and])
    WriteDotToFile(circuit, "circuit")

    return 0
}