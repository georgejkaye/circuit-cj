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

    let t = TrueSignal()
    let f = FalseSignal()

    let and = AndGate(t, f)

    let circuit = MakeCircuit([], [and])
    WriteDotToFile(circuit, "values")

    return 0
}