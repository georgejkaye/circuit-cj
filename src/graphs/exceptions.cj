package graphs

import debug.*

class AlreadyOwnedException <: Exception {
    init(function : String, e : Element, h1 : Hypergraph, h2 : Hypergraph) {
        ErrorMsg(function, "Element ${e.GetId()} already has an owner ${h1.GetName()}, so it can't be owned by ${h2.GetName()}")
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

class InputsNotInHypergraphException <: Exception {
    init(function : String, h : Hypergraph) {
        ErrorMsg(function, "Not all inputs of ${h.GetName()} are vertices in ${h}")
    }
}
class OutputsNotInHypergraphException <: Exception {
    init(function : String, h : Hypergraph) {
        ErrorMsg(function, "Not all outputs of ${h.GetName()} are vertices in ${h}")
    }
}
class OutputInputMismatchException <: Exception {
    init(function : String, f : Hypergraph, g : Hypergraph) {
        ErrorMsg(function, "The outputs of hypergraph ${f.GetName()} (${f.GetOutputs()} do not match the inputs of hypergraph ${g.GetName()} (${g.GetOutputs()})")
    }
}

class NegativeTraceException <: Exception {
    init(function : String, n : Int64) {
        ErrorMsg(function, "Cannot perform a negative trace ${n}")
    }
}

class NotEnoughInputsException <: Exception {
    init(function : String, n : Int64, h : Hypergraph) {
        ErrorMsg(function, "Needed ${n} inputs but ${h.GetName()} only has ${h.GetInputs()}")
    }
}

class NotEnoughOutputsException <: Exception {
    init(function : String, n : Int64, h : Hypergraph) {
        ErrorMsg(function, "Needed ${n} outputs but ${h.GetName()} only has ${h.GetOutputs()}")
    }
}