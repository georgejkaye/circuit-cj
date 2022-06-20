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
    let adder = Adder(input1, input2)

    let acc = Accumulator(width: 8, initial: 23)


    let after_acc = Subcircuit(acc, [adder])
    let circuit1 = MakeCircuit([input1, input2], after_acc.toArray())
    WriteDotToFile(circuit1, "circuit1")

    let after_acc_2 = Subcircuit(acc, after_acc.toArray())
    after_acc_2.add(input2)
    let circuit = MakeCircuit([input1, input2], after_acc_2.toArray())
    WriteDotToFile(circuit, "circuit2")

    return 0
}