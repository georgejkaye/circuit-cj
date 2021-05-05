/**
 * exceptions.cj
 *
 * This file contains exceptions
 */

package hypergraphs

import debug.*

/**
 * Miscellaneous exceptions
 */

class InaccessibleCodeException <: Exception {
    init(function : String){
        Error(function, "This code should not be accessible")
    }
}

/**
 * Hypergraph exceptions
 */

class VertexNotInGraphException <: Exception {
    init(function : String, v : Vertex){
        Error(function, "Vertex ${v.id} is not in the graph")
    }
}

class WireNotInGraphException <: Exception {
    init(function : String, w : Wire){
        Error(function, "Wire ${w} is not in the graph")
    }
}

class BusNotInGraphException <: Exception {
    init(function : String, b : Bus){
        Error(function, "Bus ${b} is not in the graph")
    }
    init(function : String, s : String){
        Error(function, "Bus ${s} is not in the graph")
    }
}

/**
 * Type error exceptions 
 */

class BadDomainException <: Exception {
    init(function : String, m : Int64, dom : Int64){
        Error(function, "Number of ports (${m}) does not match the domain of the label (${dom})")
    }
}
class BadCodomainException <: Exception {
    init(function : String, n : Int64, cod : Int64){
        Error(function, "Number of ports (${n}) does not match the codomain of the label (${cod})")
    }
}
class TypeMismatchException <: Exception {
    init(function : String, f : Hypergraph, g : Hypergraph){
        Error(function, "Outputs of '${f.GetName()}' (${f.GetN()}) do not match inputs of '${g.GetName()}' (${g.GetM()})")
    }
    init(function : String, f : Hypergraph, n : Int64) {
        Error(function, "Outputs of '${f.GetName()}' (${f.GetN()}) do not match required inputs (${n})")
    }
}
class BadValueException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String){
        Error(function, "Expected input ${wire} to be a value i.e. type 0->n but '${name}' has type ${n1}->n")
    }
}

/**
 * Port exceptions
 */

class BadOutputLabelsException <: Exception {
    init(function : String, m : Int64, n : Int64){
        Error(function, "Length of ports list (${m}) does not match the outputs(${n})")
    }
}
class PortNotFoundException <: Exception {
    init(function : String, f : Hypergraph, s : String){
        Error(function, "Hypergraph '${f.GetName()}' does not have a port named '${s}'")
    }
}

/**
 * Operation exceptions
 */
class NegativeWireException <: Exception {
    init(function : String){
        Error(function, "Number of wires cannot be negative")
    }
}
class NegativeTraceException <: Exception {
    init(function : String){
        Error(function, "Cannot trace negative number of wires")
    }
}
class TooMuchTraceException <: Exception {
    init(function : String){
        Error(function, "Tried to trace more wires than outputs")
    }
}

/**
 * File exceptions
 */
class CouldNotOpenFileException <: Exception {
    init(function : String, file : String){
        Error(function, "Could not open file ${file}")
    }
}

class BadInputException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String, n2 : Int64){
        Error(function, "Expected input '${wire}'' to be of type n->${n1} but '${name}' has type n->${n2}")
    }
}

class NotEnoughBitsException <: Exception {
    init(function : String){
        Error(function, "Must be at least one bit")
    }
}