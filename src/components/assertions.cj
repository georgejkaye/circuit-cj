package components

import debug.*

func AssertNonEmpty<T>(array : Array<T>) {
    if(array.size() == 0) {
        throw NoWiresException()
    }
    array.size()
}

func AssertWireWidth(w : Wire, i : Int64) : Unit {
    if(w.GetWidth() != i){
        throw IncompatibleWidthException("", w, i)
    }
}

func AssertWiresSameWidth(w : Wire, v : Wire) : Int64 {
    if(w.GetWidth() != v.GetWidth()){
        throw WiresNotSameWidthException(w, v)
    }
    w.GetWidth()
}

func AssertWiresSameWidth(ws : Array<Wire>) : (Int64, Int64) {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    for(w in ws) {
        AssertWireWidth(w, width)
    }
    (ws.size(), width)
}

func AssertWireArraysCompatible(ws : Array<Wire>, vs : Array<Wire>) : Array<Int64> {
    if (ws.size() != vs.size()) {
        throw DifferentNumberOfWiresException(ws, vs)
    }
    Array<Int64>(ws.size()) {
        i : Int64 =>
            AssertWiresSameWidth(ws[i], vs[i])
    }
}

func AssertWiresTypecheck(ws : Array<Wire>, ns: Array<Int64>) : Unit {
    AssertNumberOfWires(ws, ns.size())
    for (i in 0..(ns.size())) {
        if(ws[i].GetWidth() != ns[i]) {
            throw IncorrectWireInputsException(ns, ws)
        }
    }
}

func AssertAllWiresWidth(ws : Array<Wire>, n: Int64) : Unit {
    fold_left(
        { acc : Unit, w : Wire => AssertWireWidth(w, n)},
        (),
        ws
    )
}

func AssertNumberOfWires(ws : Array<Wire>, n : Int64) {
    if(ws.size() != n) {
        throw BadNumberOfWiresException(ws, n)
    }
}
func AssertMinNumberOfWires(ws : Array<Wire>, n : Int64) {
    if(ws.size() < n) {
        throw BadNumberOfWiresException(ws, n)
    }
    ws.size()
}