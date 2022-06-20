package graphs

import debug.*

class AlreadyOwnedException<T> <: Exception where T <: ToString {
    init(function : String, t : T, h1 : Hypergraph, h2 : Hypergraph) {
        ErrorMsg(function, "Element ${t} already has an owner ${h1.GetName()}, so it can't be owned by ${h2.GetName()}")
    } 
}
class SourceAlreadyExistsException <: Exception {
    init(function : String, e : Edge, i : Int64, v : Vertex){
        ErrorMsg(function, "Edge ${e} already has a source ${i}, namely ${v}")
    }
}
class TargetAlreadyExistsException <: Exception {
    init(function : String, e : Edge, i : Int64, v : Vertex){
        ErrorMsg(function, "Edge ${e} already has a target ${i}, namely ${v}")
    }
}
class InputNotInHypergraphException <: Exception {
    init(function : String, f : Hypergraph, v : Vertex) {
        ErrorMsg(function, "Tried to set ${v} as an input of ${f.GetName()} but it is not present")
    }
}
class OutputNotInHypergraphException <: Exception {
    init(function : String, f : Hypergraph, v : Vertex) {
        ErrorMsg(function, "Tried to set ${v} as an output of ${f.GetName()} but it is not present")
    }
}
class InputsNotInHypergraphException <: Exception {
    init(function : String, h : InterfacedHypergraph) {
        ErrorMsg(function, "Not all inputs of ${h.GetName()} are vertices in ${h}")
    }
}
class OutputsNotInHypergraphException <: Exception {
    init(function : String, h : InterfacedHypergraph) {
        ErrorMsg(function, "Not all outputs of ${h.GetName()} are vertices in ${h}")
    }
}
class IncompatibleLabelException <: Exception {
    init(function : String, label : Label, sources : Array<Int64>, targets : Array<Int64>){
        ErrorMsg(function, "Tried to construct an edge using label ${label} type ${label.GetInputPorts()} → ${label.GetOutputPorts()} but given vertices of types ${sources} → ${targets}")
    }
}
class NegativeTraceException <: Exception {
    init(function : String, n : Int64) {
        ErrorMsg(function, "Cannot perform a negative trace ${n}")
    }
}
class NotEnoughInputsException <: Exception {
    init(function : String, n : Int64, h : InterfacedHypergraph) {
        ErrorMsg(function, "Needed ${n} inputs but ${h.GetName()} only has ${h.GetInputs()}")
    }
}
class NotEnoughOutputsException <: Exception {
    init(function : String, n : Int64, h : InterfacedHypergraph) {
        ErrorMsg(function, "Needed ${n} outputs but ${h.GetName()} only has ${h.GetOutputs()}")
    }
}
class CouldNotOpenFileException <: Exception {
    init(function : String, file : String) {
        ErrorMsg(function, "Could not open file ${file}")
    }
}
public class NotOwnedException<T,U> <: Exception where T <: Ownable<U> & ToString {
    init(function : String, t : T){
        ErrorMsg(function, "${t} needs an owner but doesn't have one")
    } 
}
class OutputInputMismatchException <: Exception {
    init(function : String, f : InterfacedHypergraph, g : InterfacedHypergraph) {
        ErrorMsg(function, "The outputs of hypergraph ${f.GetName()} (${f.GetOutputs()} do not match the inputs of hypergraph ${g.GetName()} (${g.GetOutputs()})")
    }
}
public class IncompatibleWidthException <: Exception {
    public init(function : String, v : Vertex, l : Int64, r : Int64) {
        ErrorMsg(function, "Tried to split ${v} into (${l},${r}) but it is only of width ${v.GetWidth()}")
    }
}
