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
        ErrorMsg(function, "This code should not be accessible")
    }
}

/**
 * Bit exceptions
 */

class NotEnoughBitsException <: Exception {
    init(function : String){
        ErrorMsg(function, "Must be at least one bit")
    }
}
class NegativeNumberException <: Exception {
    init(function : String, number : Int64){
        ErrorMsg(function, "Expected a positive number but ${number} is positive")
    }
}

/**
 * Bus exceptions 
 */

class NoSuchBusException <: Exception {
    init(function : String, name : String){
        ErrorMsg(function, "Bus ${name} does not exist")
    }
}

class DuplicateBusException <: Exception {
    init(function : String, name : String){
        ErrorMsg(function, "Bus ${name} already exists")
    }
}

class DuplicateWireException <: Exception {
    init(function : String, bus : Bus, i : Int64){
        ErrorMsg(function, "Bus ${bus} already has wire ${i}")
    }
}
class BusesNotSameSizeException <: Exception {
    init(function: String, m : Int64, n : Int64){
        ErrorMsg(function, "Buses must be the same size, but they are ${m} and ${n}")
    }
}

/**
 * Hypergraph exceptions
 */

class BadHypergraphException <: Exception {
    init(function : String){
        ErrorMsg(function, "Trying to perform on operation on a non-complete hypergraph")
    }
}

class VertexNotInGraphException <: Exception {
    init(function : String, v : Vertex){
        ErrorMsg(function, "Vertex ${v.id} is not in the graph")
    }
}

class WireNotInGraphException <: Exception {
    init(function : String, w : Wire){
        ErrorMsg(function, "Wire ${w} is not in the graph")
    }
}

class BusNotInGraphException <: Exception {
    init(function : String, b : Bus){
        ErrorMsg(function, "Bus ${b} is not in the graph")
    }
    init(function : String, s : String){
        ErrorMsg(function, "Bus ${s} is not in the graph")
    }
}
class BadTargetsException <: Exception {
    init(function : String, edge : Edge, i : Int64){
        ErrorMsg(function, "Attempted to access ${i}th target but ${edge} only has ${edge.targets.size()}")
    }
}
class BadSourcesException <: Exception {
    init(function : String, edge : Edge, i : Int64){
        ErrorMsg(function, "Attempted to access ${i}th sources but ${edge} only has ${edge.sources.size()}")
    }
}
class NegativeInputsException <: Exception {
    init(function : String, n : Int64) {
        ErrorMsg(function, "Number of inputs cannot be negative, but ${n} requested")
    }
}
class NegativeOutputsException <: Exception {
    init(function : String, n : Int64) {
        ErrorMsg(function, "Number of outputs cannot be negative, but ${n} requested")
    }
}

/**
 * Type error exceptions 
 */

class BadDomainException <: Exception {
    init(function : String, m : Int64, dom : Int64){
        ErrorMsg(function, "Number of inputs (${m}) does not match the domain of the label (${dom})")
    }
}
class BadCodomainException <: Exception {
    init(function : String, n : Int64, cod : Int64){
        ErrorMsg(function, "Number of outputs (${n}) does not match the codomain of the label (${cod})")
    }
}
class TypeMismatchException <: Exception {
    init(function : String, f : Hypergraph, g : Hypergraph){
        ErrorMsg(function, "Outputs of '${f.GetName()}' (${f.GetN()}) do not match inputs of '${g.GetName()}' (${g.GetM()})")
    }
    init(function : String, f : Hypergraph, n : Int64) {
        ErrorMsg(function, "Outputs of '${f.GetName()}' (${f.GetN()}) do not match required inputs (${n})")
    }
}
class BadValueException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String){
        ErrorMsg(function, "Expected input ${wire} to be a value i.e. type 0->n but '${name}' has type ${n1}->n")
    }
}
class BadOutputException <: Exception {
    init(function : String, des : Int64, act : Int64 ){
        ErrorMsg(function, "Tried to get output ${des}, but there are only ${act}")
    }
}

/**
 * Port exceptions
 */

class BadOutputLabelsException <: Exception {
    init(function : String, m : Int64, n : Int64){
        ErrorMsg(function, "Length of labels list (${m}) does not match the outputs(${n})")
    }
}
class PortNotFoundException <: Exception {
    init(function : String, f : Hypergraph, s : String){
        ErrorMsg(function, "Hypergraph '${f.GetName()}' does not have a port named '${s}'")
    }
}

/**
 * Operation exceptions
 */
class NegativeWireException <: Exception {
    init(function : String){
        ErrorMsg(function, "Number of wires cannot be negative")
    }
}
class NegativeTraceException <: Exception {
    init(function : String){
        ErrorMsg(function, "Cannot trace negative number of wires")
    }
}
class TooMuchTraceException <: Exception {
    init(function : String){
        ErrorMsg(function, "Tried to trace more wires than outputs")
    }
}
class NegativeDurationException <: Exception {
    init(function : String, dur : Int64){
        ErrorMsg(function, "Duration of delay must be positive but ${dur} requested")
    }
}

/**
 * File exceptions
 */
class CouldNotOpenFileException <: Exception {
    init(function : String, file : String){
        ErrorMsg(function, "Could not open file ${file}")
    }
}

class BadInputException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String, n2 : Int64){
        ErrorMsg(function, "Expected input '${wire}' to be of type n->${n1} but '${name}' has type n->${n2}")
    }
}