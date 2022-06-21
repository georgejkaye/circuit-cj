package components

import debug.*

func AssertWireWidth(w : WireEnd, i : Int64) : Unit {
    if(w.GetWidth() != i){
        throw IncompatibleWidthException("", w, i)
    }
}

func AssertWiresSameWidth(w : WireEnd, v : WireEnd) : Int64 {
    if(w.GetWidth() != v.GetWidth()){
        throw WiresNotSameWidthException(w, v)
    }
    w.GetWidth()
}