package graphs

import debug.*

class SourceAlreadyExistsException <: Exception {
    init(function : String, e : Edge, i : UInt64, v : Vertex){
        ErrorMsg(function, "Edge ${e} already has a source ${i}, namely ${v}")
    }
}

class TargetAlreadyExistsException <: Exception {
    init(function : String, e : Edge, i : UInt64, v : Vertex){
        ErrorMsg(function, "Edge ${e} already has a target ${i}, namely ${v}")
    }
}