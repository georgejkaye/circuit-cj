package components

import debug.*

public class NotEnoughBitsException <: Exception {
    init(function: String, attempted : Int64, actual : Int64, required : Int64) {
        ErrorMsg(function, "Attempted to represent ${attempted} in ${actual} bits, but ${required} are required")
    }
}

public class NegativeNumberException <: Exception {
    init(function : String, number : Int64) {
        ErrorMsg(function, "Attempted to represent negative number ${number} in an unsigned value")
    }
}
public class IncompatibleLabelInterfaceException <: Exception {
    init(function : String, label : Label, inputs : Int64, outputs : Int64) {
        ErrorMsg(function, "Label ${label} has type ${label.GetInputType()} → ${label.GetOutputType()}, but ${inputs} → ${outputs} was expected")
    }
}
public class NotDanglingWireException <: Exception {
    init(function : String, w : Wire) {
        ErrorMsg(function, "Tried to use ${w} as a feedback wire but it has connected in-edges")
    }
}
class IncompatibleInputsException <: Exception {
    init(function : String, inputs : Array<Int64>, f : InterfacedHypergraph) {
        ErrorMsg(function, "Tried to give ${inputs} as input type but ${f.GetName()} needs ${f.GetInputType()}")
    }
}
class IncompatibleWidthException <: Exception {
    init(function : String, w : Wire, i : Int64) {
        ErrorMsg(function, "${w} has width ${w.GetWidth()} but ${i} was required")
    }
}
class WiresNotAllSameWidthException <: Exception {
    init(function : String, i : Int64, w : Wire) {
        ErrorMsg(function, "Trying to apply a gate for each of ${i} bits but ${w} has width ${w.GetWidth()}")
    }
}
class WiresNotSameWidthException <: Exception {
    init(w : Wire, v : Wire) {
        ErrorMsg("", "Wires ${w} (${w.GetWidth()} bits) and ${v} (${v.GetWidth()} bits) are not the same width")
    }
}
class DifferentNumberOfWiresException <: Exception {
    init(ws : Array<Wire>, vs: Array<Wire>) {
        ErrorMsg("", "Needed wire arrays to be the same size but they were ${ws.size()} and ${vs.size()}")
    }
}
class NoWiresException <: Exception {
    init() {
        ErrorMsg("", "No wires to do anything with")
    }
}
class BadNumberOfWiresException <: Exception {
    init(ws : Array<Wire>, n : Int64) {
        ErrorMsg("", "Required ${n} wires but given ${ws.size()}")
    }
}