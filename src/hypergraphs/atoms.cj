/**
 * atoms.cj
 *
 * This file contains the definition of atoms that make up hypergraphs
 */

package hypergraphs

import debug.*

/**
 * Base atom class, every element of a hypergraph (vertex, edge, label) is an atom
 * Each atom has a unique id, and this is what comparisons should be performed on
 */
open class Atom {
    let id : UInt64
    init() { 
        this.id = genId()
    }
}
append Atom with Equatable, Hashable {
    operator func ==(lhs : Atom, rhs : Atom) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Atom, rhs : Atom) : Bool { lhs.id != rhs.id }
    func hashCode(a : Atom) : UInt64 { a.id }
}

/** The next id available */
var nextid : UInt64 = 0

/**
 * Generate the next unique id for an atom
 * @return The next id
 */
func genId(){
    let id = nextid
    nextid++
    id
}

/** 
 * Get a string representing a list of atoms 
 * The string is formatted like [ 1 2 3 ]
 * @param xs The list of atoms
 * @return A string containing a space-separated list of the atom ids
 */
func AtomListToString(xs : ArrayList<Atom>){
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
    }
    str = "${str} ]"
    str
}

/**
 * Base vertex class 
 */
open class Vertex <: Atom {}
append Vertex with ToString {
    func toString(v : Vertex) : String { "Vertex v${v.id}" }
}

/**
 * Source vertices are outwards facing ports: they are the sources of edges.
 * Sources have names so that we can reference them later and connect them to new edges
 */
external class Source <: Vertex {
    /** The wires that the vertex represents */
    let wires : ArrayList<Wire>
    init() { this.wires = ArrayList<Wire>([Wire()])}
    init(wire: Wire) { this.wires = ArrayList<Wire>([wire]) }
    init(wires: ArrayList<Wire>) { this.wires = wires }

    /** 
     * Add a wire to this vertex
     * @param wire The wire to add 
     */
    func AddWire(wire : Wire) { this.wires.add(wire) }
    /** 
     * Add a list of wires to this vertex
     * @param wires The wires to add 
     */
    func AddWires(wires : ArrayList<Wire>) { this.wires.addAll(wires) }
}
append Source with ToString, Equatable, Hashable {
    func toString(s : Source) {
        var wires = ""
        for (wire in s.wires){
            let wiretext = match(wire.bus.name){
                case Some(str) => str
                case $None     => ""
            }
            wires = if(wires == "") { "${wiretext}" } else { "${wires}, ${wiretext}" }
        }
        return "Source s${s.id} ${wires}" 
    }
    operator func ==(lhs : Source, rhs : Source) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Source, rhs : Source) : Bool { lhs.id != rhs.id }
    func hashCode(t : Source) : UInt64 { t.id }
}

/** 
 * Get a string representing a list of source vertices
 * The string is formatted like [ 1 (a[0],b[1]) 2 (a[1]) 3 (b[0]) ]
 * @param xs The list of sources
 * @return A string containing a space-separated list of the sources
 */
func SourceListToString(xs : ArrayList<Source>){ 
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
        var wires = ""
        for(wire in x.wires){
            let wirename = match(wire.bus.name){
                case Some(name) => "${name}[${wire.i}]"
                case $None      => ""
            }
            wires = if(wirename == "") { wires } else if(wires == "") { " ${wirename}" } else { "${wires}, ${wirename}" }
        }
        wires = if(wires == "") { "" } else { "(${wires})" }
        str = "${str}${wires}"
    }
    str = "${str} ]"
    str
}


/**
 * Target vertices are inwards facing ports: they are the targets of edges.
 * Target vertices currently don't have anything particularly special about them
 */
external class Target <: Vertex {}
append Target with ToString, Equatable, Hashable {
    func toString(t : Target) { "Target t${t.id}" }
    operator func ==(lhs : Target, rhs : Target) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Target, rhs : Target) : Bool { lhs.id != rhs.id }
    func hashCode(t : Target) : UInt64 { t.id }
}

/** 
 * Get a string representing a list of target vertices
 * TODO: Currently this method is just the same as AtomListToString
 * The string is formatted like [ 1 2 3 ]
 * @param xs The list of targets
 * @return A string containing a space-separated list of the targets
 */
func TargetListToString(xs : ArrayList<Target>){ 
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
    }
    str = "${str} ]"
    str
}

/**
 * Edges have an associated generator, and lists of sources and targets
 */
external open class Edge <: Atom {
    let generator : Generator
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(generator : Generator, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.generator = generator
        this.sources = sources
        this.targets = targets
    }
    init(generator : Generator, sources : List<Source>, targets: List<Target>){
        this(generator, ArrayList<Source>(sources), ArrayList<Target>(targets))
    }
    init(generator : Generator, sources : ArrayList<Source>){
        this(generator, sources, ArrayList<Target>())
    }
    init(generator : Generator, targets : ArrayList<Target>){
        this(generator, ArrayList<Source>(), targets)
    }
}
append Edge with ToString, Equatable, Hashable {
    func toString(e : Edge) { 
        "Edge e${e.id} - ${e.generator}" 
    }
    operator func ==(lhs : Edge, rhs : Edge) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Edge, rhs : Edge) : Bool { lhs.id != rhs.id }
    func hashCode(t : Edge) : UInt64 { t.id }
}

/** 
 * Get a string representing a list of edges
 * The string is formatted like [ 1 (edge AND) 2 (in link x) 3 (out link y) ]
 * @param xs The list of edges
 * @return A string containing a space-separated list of the edges
 */
func EdgeListToString(xs : ArrayList<Edge>){ 
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id} (${x.generator})"
    }
    str = "${str} ]"
    str
}

/**
 * Vertices connect to ports, either on an edge or on the interface 
 */
enum Port { 
    | EdgePort(Edge, Int64) 
    | InterfacePort(Int64) 
}
