/**
 * exceptions.cj
 *
 * This file contains exceptions
 */

package hypergraphs

/**
 * Miscellaneous exceptions
 */

class InaccessibleCodeException <: Exception {
    init(){
        print("This code should not be accessible")
    }
}

/**
 * Hypergraph exceptions
 */

class VertexNotInGraphException <: Exception {
    init(v : Vertex){
        print("Vertex ${v.id} is not in the graph")
    }
}

class WireNotInGraphException <: Exception {
    init(w : Wire){
        print("Wire ${w} is not in the graph")
    }
}

class BusNotInGraphException <: Exception {
    init(b : Bus){
        print("Bus ${b} is not in the graph")
    }
    init(s : String){
        print("Bus ${s} is not in the graph")
    }
}

/**
 * Type error exceptions 
 */

class BadDomainException <: Exception {
    init(m : Int64, dom : Int64){
        print("Number of ports (${m}) does not match the domain of the label (${dom})")
    }
}
class BadCodomainException <: Exception {
    init(n : Int64, cod : Int64){
        print("Number of ports (${n}) does not match the codomain of the label (${cod})")
    }
}
class TypeMismatchException <: Exception {
    init(f : Hypergraph, g : Hypergraph){
        print("Outputs of '${f.GetName()}' (${f.GetN()}) do not match inputs of '${g.GetName()}' (${g.GetM()})")
    }
    init(f : Hypergraph, n : Int64) {
        print("Outputs of '${f.GetName()}' (${f.GetN()}) do not match required inputs (${n})")
    }
}

/**
 * Port exceptions
 */

class BadOutputLabelsException <: Exception {
    init(m : Int64, n : Int64){
        print("Length of ports list (${m}) does not match the outputs(${n})")
    }
}
class PortNotFoundException <: Exception {
    init(f : Hypergraph, s : String){
        print("Hypergraph '${f.GetName()}' does not have a port named '${s}'")
    }
}

/**
 * Operation exceptions
 */
class NegativeWireException <: Exception {
    init(){
        print("Number of wires cannot be negative")
    }
}
class NegativeTraceException <: Exception {
    init(){
        print("Cannot trace negative number of wires")
    }
}
class TooMuchTraceException <: Exception {
    init(){
        print("Tried to trace more wires than outputs")
    }
}

/**
 * File exceptions
 */
class CouldNotOpenFileException <: Exception {
    init(file : String){
        print("Could not open file ${file}")
    }
}