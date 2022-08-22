from circuits import graphs.WriteDotToFile
from circuits import rewrite.RewriteCombinational

from circuits import settings.*
from circuits import components.*
from circuits import debug.SetDebugMessages

main(){

    SetDebugMessages(true)
    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(false)

    let a = FalseSignal()
    let v = FalseSignal()
    let w = TrueSignal()
    let and1 = And(a,v)
    let and2 = And(and1, w)
    let test = MakeSubcircuit(
        [],
        [InterfaceWire(and2, "Z")],
        "test"
    )
    WriteDotToFile(test, 0, "test")
    RewriteCombinational(test)
    WriteDotToFile(test, 0, "test-rewr")

    return 0
}
