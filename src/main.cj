from circuits import graphs.*
from circuits import syntax.*
from circuits import prelude.*
from circuits import settings.*
from circuits import components.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(false)
    SetDotNumberRepresentation(DEC)

    let width = 4

    let fb = MakeWire(width: 4)
    let input = MakeWire(width: 4)

    let reg = SimpleRegister(4, false, fb)
    let adderSpec = Specification("adder", [width, width], [width])
    let adder = BlackBox(adderSpec, [reg, input])[0]

    Feedback(adder, fb)

    let circuit = MakeCircuit([input], [adder])
    WriteDotToFile(circuit, "circuit")

    return 0
}