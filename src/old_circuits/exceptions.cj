/**
 * exceptions.cj
 *
 * This file contains exceptions
 */

package circuits

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
class NotEvenBitsException <: Exception {
    init(function : String, input : Hypergraph){
        ErrorMsg(function, "Need an even number of bits to operate but the outputs of '${input.GetName()}' is odd")
    }
}

/**
 * Bus exceptions 
 */

class NoSuchBusException <: Exception {
    init(function : String, name : String){
        ErrorMsg(function, "Bus '${name}'' does not exist")
    }
}
class DuplicateBusException <: Exception {
    init(function : String, name : String){
        ErrorMsg(function, "Bus '${name}' already exists")
    }
}
class DuplicateWireException <: Exception {
    init(function : String, bus : Bus, i : Int64){
        ErrorMsg(function, "Bus '${bus.GetName()}' already has wire ${i}")
    }
}
class BusesNotSameSizeException <: Exception {
    init(function: String, m : Int64, n : Int64){
        ErrorMsg(function, "Buses must be the same size, but they are ${m} and ${n}")
    }
}

/**
 * HypergraphStructure exceptions
 */

class BadHypergraphException <: Exception {
    init(h : HypergraphStructure, wf : WellformednessStatus){
        match(wf){
            case TargetNotConnected(t)           => throw MissingConnectionException("Wellformedness", h, t)
            case SourceNotConnected(s)           => throw MissingConnectionException("Wellformedness", h, s)
            case TargetNotAssociated(t)          => throw NoAssociatedEdgeException("Wellformedness", h, t)
            case SourceNotAssociated(s)          => throw NoAssociatedEdgeException("Wellformedness", h, s)
            case IncorrectTargetAssignment(t, p) => throw IncorrectPortException("Wellformedness", h, t, p)
            case IncorrectSourceAssignment(s, p) => throw IncorrectPortException("Wellformedness", h, s, p)
            case DuplicateTarget(t)              => throw DuplicateVertexException("Wellformedness", h, t)
            case DuplicateSource(s)              => throw DuplicateVertexException("Wellformedness", h, s)
            case DuplicateTargetGlobalId(i)      => throw DuplicateTargetGlobalIdException("Wellformedness", h, i)
            case DuplicateSourceGlobalId(i)      => throw DuplicateSourceGlobalIdException("Wellformedness", h, i)
            case DuplicateEdgeGlobalId(i)        => throw DuplicateEdgeGlobalIdException("Wellformedness", h, i)
            case ConnectionNotInGraph(v1,v2)     => throw BadConnectionException("Wellformedness", h, v1, v2)
            case EdgeNotInGraph(v, e)            => throw BadEdgeException("Wellformedness", h, v, e)
            case IncorrectDomain(e, n)           => throw BadDomainException("Wellformedness", n, Dom(e.generator))
            case IncorrectCodomain(e, n)         => throw BadCodomainException("Wellformedness", n, Cod(e.generator))
            case _                               => throw InaccessibleCodeException("Wellformedness")
        }
    }
}

class NoAssociatedEdgeException <: Exception {
    init(function : String, h : HypergraphStructure, s : Source){
        ErrorMsg(function, "The source ${s.id} does not have an associated edge")
    }
    init(function : String, h : HypergraphStructure, t : Target){
        ErrorMsg(function, "The target ${t.id} does not have an associated edge")
    }
    init(function : String, v : Vertex){
        ErrorMsg(function, "The vertex ${v.id} does not have an associated edge")
    }
}
class IncorrectPortException <: Exception {
    init(function : String, h : HypergraphStructure, s : Source, p : Port){
        ErrorMsg(function, "The source ${s.id} is incorrectly assigned to port ${p}")
    }
    init(function : String, h : HypergraphStructure, t : Target, p : Port){
        ErrorMsg(function, "The source ${t.id} is incorrectly assigned to port ${p}")
    }
}
class MissingConnectionException <: Exception {
    init(function : String, h : HypergraphStructure, v : Vertex) {
        ErrorMsg(function, "No connection found for ${v}")
    }
    init(function : String, v : Vertex) {
        ErrorMsg(function, "No connection found for ${v}")
    }
}
class BadConnectionException <: Exception {
    init(function : String, h : HypergraphStructure, v1 : Vertex, v2 : Vertex){
        ErrorMsg(function, "Connection of vertex ${v1.id} (${v2.id}) is not in the graph")
    }
}
class BadEdgeException <: Exception {
    init(function : String, h : HypergraphStructure, v : Vertex, e : Edge){
        ErrorMsg(function, "Edge of vertex ${v.id} (${e.id}) is not in the graph")
    }
}
class DuplicateVertexException <: Exception {
    init(function : String, h : HypergraphStructure, t : Target) {
        ErrorMsg(function, "The target ${t.id} is the target of multiple edges")
    }
    init(function : String, h : HypergraphStructure, s : Source) {
        ErrorMsg(function, "The source ${s.id} is the source of multiple edges")
    }
}
class DuplicateTargetGlobalIdException <: Exception {
    init(function : String, h : HypergraphStructure, id : UInt64){
        ErrorMsg(function, "The target global id ${id} is used multiple times in the graph")
    }
}
class DuplicateSourceGlobalIdException <: Exception {
    init(function : String, h : HypergraphStructure, id : UInt64){
        ErrorMsg(function, "The source global id ${id} is used multiple times in the graph")
    }
}
class DuplicateEdgeGlobalIdException <: Exception {
    init(function : String, h : HypergraphStructure, id : UInt64){
        ErrorMsg(function, "The edge global id ${id} is used multiple times in the graph")
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
        ErrorMsg(function, "Bus ${b.GetName()} is not in the graph")
    }
    init(function : String, s : String){
        ErrorMsg(function, "Bus ${s} is not in the graph")
    }
}
class BadTargetException <: Exception {
    init(function : String, edge : Edge, i : Int64){
        ErrorMsg(function, "Attempted to access ${i}th target but edge ${edge.id} (${edge.generator}) only has ${edge.targets.size()}")
    }
}
class BadSourceException <: Exception {
    init(function : String, edge : Edge, i : Int64){
        ErrorMsg(function, "Attempted to access ${i}th source but edge ${edge.id} (${edge.generator}) only has ${edge.sources.size()}")
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
class NotEdgePortException <: Exception {
    init(function : String, port : Port){
        ErrorMsg(function, "Port ${port} is not an edge port")
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
    init(function : String, f : HypergraphStructure, g : HypergraphStructure){
        ErrorMsg(function, "Outputs of '${f.GetId()}' (${f.GetN()}) do not match inputs of '${g.GetId()}' (${g.GetM()})")
    }
    init(function : String, f : HypergraphStructure, n : Int64) {
        ErrorMsg(function, "Outputs of '${f.GetId()}' (${f.GetN()}) do not match required inputs (${n})")
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
    init(function : String, v : Source){
        ErrorMsg(function, "Tried to get output ${v}, but it is not an output")
    }
}
class BadInputException <: Exception {
    init(function : String, des : Int64, act : Int64 ){
        ErrorMsg(function, "Tried to get input ${des}, but there are only ${act}")
    }
    init(function : String, v : Target){
        ErrorMsg(function, "Tried to get input ${v}, but it is not an input")
    }
}
class DifferentLengthArgumentsException <: Exception {
    init(function : String, a : Hypergraph, b : Hypergraph){
        ErrorMsg(function, "Arguments '${a.GetName()}' and '${b.GetName()}' must have the same number of outputs")
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
    init(function : String, f : HypergraphStructure, s : String){
        ErrorMsg(function, "HypergraphStructure '${f.GetId()}' does not have a port named '${s}'")
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

class BadInputGraphException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String, n2 : Int64){
        ErrorMsg(function, "Expected input '${wire}' to be of type n->${n1} but '${name}' has type n->${n2}")
    }
}

class NonLinkEdgeException <: Exception {
    init(function : String, e : Edge){
        ErrorMsg(function, "Tried to use edge ${e.id} as a link, but it is not one")
    }
}
class NonValueEdgeException <: Exception {
    init(function : String, e : Edge){
        ErrorMsg(function, "Tried to use edge ${e.id} as a value, but it is not one")
    }
}
class NonDelayEdgeException <: Exception {
    init(function : String, e : Edge){
        ErrorMsg(function, "Tried to use edge ${e.id} as a delay, but it is not one")
    }
}
class NonJoinEdgeException <: Exception {
    init(function : String, e : Edge){
        ErrorMsg(function, "Tried to use edge ${e.id} as a join, but it is not one")
    }
}
class NonProductiveException <: Exception {
    init(function : String, f : HypergraphStructure){
        ErrorMsg(function, "The hypergraph '${f.GetId()}' is not in productive form")
    }
}
class BadGeneratorException <: Exception {
    init(function : String, gen : Generator) {
        ErrorMsg(function, "Generator ${gen} is not handled here")
    }
}
class NoAssociatedHypergraphException <: Exception {
    init(function : String, elem : HypergraphElement){
        ErrorMsg(function, "Element ${elem} does not have an associated hypergraph")
    }
}