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

public class IncompatibleInputsException <: Exception {
    init(function : String, attempted : Int64, actual : Int64) {
        ErrorMsg(function, "Tried to input ${attempted} wires by ${actual} are needed")
    }
}

public class IncompatibleLabelInterfaceException <: Exception {
    init(function : String, label : Label, inputs : Int64, outputs : Int64) {
        ErrorMsg(function, "Label ${label} has type ${label.GetInputPorts()} → ${label.GetOutputPorts()}, but ${inputs} → ${outputs} was expected")
    }
}

public class IncompatibleWidthException <: Exception {
    init(function : String, v : Vertex, l : Int64, r : Int64) {
        ErrorMsg(function, "Tried to split ${v} into (${l},${r}) but it is only of width ${v.GetWidth()}")
    }
}