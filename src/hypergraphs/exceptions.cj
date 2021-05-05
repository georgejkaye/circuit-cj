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
    init(){
        Debug("This code should not be accessible")
    }
}

/**
 * Hypergraph exceptions
 */

class VertexNotInGraphException <: Exception {
    init(v : Vertex){
        Debug("Vertex ${v.id} is not in the graph")
    }
}

class WireNotInGraphException <: Exception {
    init(w : Wire){
        Debug("Wire ${w} is not in the graph")
    }
}

class BusNotInGraphException <: Exception {
    init(b : Bus){
        Debug("Bus ${b} is not in the graph")
    }
    init(s : String){
        Debug("Bus ${s} is not in the graph")
    }
}

/**
 * Type error exceptions 
 */

class BadDomainException <: Exception {
    init(m : Int64, dom : Int64){
        Debug("Number of ports (${m}) does not match the domain of the label (${dom})")
    }
}
class BadCodomainException <: Exception {
    init(n : Int64, cod : Int64){
        Debug("Number of ports (${n}) does not match the codomain of the label (${cod})")
    }
}
class TypeMismatchException <: Exception {
    init(function : String, f : Hypergraph, g : Hypergraph){
        Debug("${function}: Outputs of '${f.GetName()}' (${f.GetN()}) do not match inputs of '${g.GetName()}' (${g.GetM()})")
    }
    init(function : String, f : Hypergraph, n : Int64) {
        Debug("${function}: Outputs of '${f.GetName()}' (${f.GetN()}) do not match required inputs (${n})")
    }
}
class BadValueException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String){
        Debug("${function}: Expected input ${wire} to be a value i.e. type 0->n but '${name}' has type ${n1}->n")
    }
}

/**
 * Port exceptions
 */

class BadOutputLabelsException <: Exception {
    init(function : String, m : Int64, n : Int64){
        Debug("${function}: Length of ports list (${m}) does not match the outputs(${n})")
    }
}
class PortNotFoundException <: Exception {
    init(f : Hypergraph, s : String){
        Debug("Hypergraph '${f.GetName()}' does not have a port named '${s}'")
    }
}

/**
 * Operation exceptions
 */
class NegativeWireException <: Exception {
    init(function : String){
        Debug("${function}: Number of wires cannot be negative")
    }
}
class NegativeTraceException <: Exception {
    init(){
        Debug("Cannot trace negative number of wires")
    }
}
class TooMuchTraceException <: Exception {
    init(){
        Debug("Tried to trace more wires than outputs")
    }
}

/**
 * File exceptions
 */
class CouldNotOpenFileException <: Exception {
    init(file : String){
        Debug("Could not open file ${file}")
    }
}

class BadInputException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String, n2 : Int64){
        Debug("${function}: Expected input '${wire}'' to be of type n->${n1} but '${name}' has type n->${n2}")
    }
}

class NotEnoughBitsException <: Exception {
    init(){
        Debug("Must be at least one bit")
    }
}