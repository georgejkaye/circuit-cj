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

    let value = UnsignedValueFromInt(23, width: 8)

    let (lsb,msbs) = LsbAndMsbs(value)

    let circuit = MakeCircuit([], [lsb, msbs])
    WriteDotToFile(circuit, "circuit")

    return 0
}