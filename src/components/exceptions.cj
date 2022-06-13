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
        ErrorMsg(function, "Label ${label} has type ${label.GetInputs()} → ${label.GetOutputs()}, but ${inputs} → ${outputs} was expected")
    }
}

class NotOwnedException<T,U> <: Exception where T <: Ownable<U> & ToString {
    init(function : String, t : T){
        ErrorMsg(function, "${t} needs an owner but doesn't have one")
    } 
}