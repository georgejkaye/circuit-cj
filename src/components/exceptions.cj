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
        ErrorMsg(function, "Label ${label} has type ${label.GetInputPorts()} → ${label.GetOutputPorts()}, but ${inputs} → ${outputs} was expected")
    }
}
public class NotDanglingWireException <: Exception {
    init(function : String, w : WireEnd) {
        ErrorMsg(function, "Tried to use ${w} as a feedback wire but it has connected in-edges")
    }
}
class IncompatibleInputsException <: Exception {
    init(function : String, inputs : Array<Int64>, f : InterfacedHypergraph) {
        ErrorMsg(function, "Tried to give ${inputs} as input type but ${f.GetName()} needs ${f.GetInputType()}")
    }
}