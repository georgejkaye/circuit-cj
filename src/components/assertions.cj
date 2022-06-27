package components

import debug.*

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

func AssertWireArraysCompatible(ws : Array<Wire>, vs : Array<Wire>) : Array<Int64> {
    if (ws.size() != vs.size()) {
        throw DifferentNumberOfWiresException(ws, vs)
    }
    Array<Int64>(ws.size()) {
        i : Int64 =>
            AssertWiresSameWidth(ws[i], vs[i])
    }
}