package graphs

import debug.*

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
        ErrorMsg(function, "Not all inputs of ${h} are vertices in ${h}")
    }
}
class OutputsNotInHypergraphException <: Exception {
    init(function : String, h : Hypergraph) {
        ErrorMsg(function, "Not all outputs of ${h} are vertices in ${h}")
    }
}