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

    let a = Wire(8)
    let b = Wire(8)

    let adder = RippleAdder(a, b)
    let circuit = MakeCircuit([a,b], [adder])
    WriteDotToFile(circuit, "adder")

    return 0
}
