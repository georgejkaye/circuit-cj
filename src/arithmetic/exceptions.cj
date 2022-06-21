package arithmetic

import graphs.*
import components.*
import debug.*

class OneBitOperationException <: Exception {
    init(function : String, w : WireEnd) {
        ErrorMsg(function, "Wires must be one bit wide but ${w} is ${w.GetVertex().GetWidth()}")
    }
}

class InputsNotSameWidthException <: Exception {
    init(function : String, w : WireEnd, v : WireEnd) {
        ErrorMsg(function, "${w} and ${v} need to be the same size")
    }
}