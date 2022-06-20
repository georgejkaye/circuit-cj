from circuits import graphs.*
from circuits import syntax.*
from circuits import prelude.*
from circuits import settings.*
from circuits import components.*

from circuits import examples.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(true)
    SetDotNumberRepresentation(DEC)

    let adder = HalfAdder()
    WriteDotToFile(adder, "adder")

    let circuit = Accumulator(width: 8, initial: 23)
    WriteDotToFile(circuit, "circuit")

    return 0
}