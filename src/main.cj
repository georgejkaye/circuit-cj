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

    let circuit = Accumulator(width: 2, initial: 0)
    WriteDotToFile(circuit, "accumulator")

    return 0
}
