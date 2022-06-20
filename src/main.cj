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

    let circuit1 = Accumulator(width: 8, initial: 23)
    WriteDotToFile(circuit1, "circuit")
    // let circuit2 = Accumulator(width: 8, initial: 15)


    let newCircuit = Seq(circuit1, circuit1)
    WriteDotToFile(newCircuit, "circuit2")

    return 0
}