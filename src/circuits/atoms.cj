/**
 * atoms.cj
 *
 * This file contains the definition of atoms that make up hypergraphs
 */
package circuits

import debug.*

/**
 * Base atom class, every element of a hypergraph (vertex, edge, label) is an atom
 * Each atom has a unique id, and this is what comparisons should be performed on
 */
open class Atom {
    static var nextid : UInt64 = 0
    let id : UInt64
    init() { 
        this.id = nextid
        nextid++
    }
    open func toString(){
        "Atom ${id}"
    }
}
append Atom with Equatable, Hashable {
    operator func ==(lhs : Atom, rhs : Atom) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Atom, rhs : Atom) : Bool { lhs.id != rhs.id }
    func hashCode(a : Atom) : UInt64 { a.id }
}
/** 
 * Get a string representing a list of atoms 
 * The string is formatted like [ 1 2 3 ]
 * @param xs The list of atoms
 * @return A string containing a space-separated list of the atom ids
 */
func AtomListToString(xs : ArrayList<Atom>){
    PrintList(xs, {x : Atom => "${x.id}"})
}
/**
 * Base vertex class 
 */
abstract class Vertex <: Atom {
    private var port : Option<Port> = None<Port>
    func SetPort(p : Port){
        this.port = Some<Port>(p)
    }
    func SetPort(e : Edge, i : Int64){
       SetPort(EdgePort(e, i))
    }
    func SetPort(i : Int64){
        SetPort(InterfacePort(i))
    }
    func RemovePort(){
        this.port = None<Port>
    }
    func GetPort(){
        match(port){
            case Some(p) => p
            case $None   => throw NoAssociatedEdgeException("GetPort", this)
        }
    }
    func HasPort(){
        match(port){
            case Some(p) => true
            case $None   => false
        }
    }
    func GetLeftPort() : Port
    func GetRightPort() : Port
    func GetLeftEdge(){
        match(GetLeftPort()){
            case EdgePort(e, i) => e
            case InterfacePort(i) => throw NotEdgePortException("GetLeftEdge", GetLeftPort())
        }
    }
    func GetRightEdge(){
        match(GetRightPort()){
            case EdgePort(e, i) => e
            case InterfacePort(i) => throw NotEdgePortException("GetRightEdge", GetRightPort())
        }
    }
}
append Vertex with ToString {
    func toString(v : Vertex){
        v.toString()
    }
}
/**
 * Source vertices are outwards facing ports: they are the sources of edges.
 * Sources have names so that we can reference them later and connect them to new edges
 */
external class Source <: Vertex {
    private var conn : Option<Target> 
    /** The wires that the vertex represents */
    let wires : ArrayList<Wire>
    init() { 
        this.conn = None<Target>
        this.wires = ArrayList<Wire>([Wire()])
    }
    init(wire: Wire) { 
        this.conn = None<Target>
        this.wires = ArrayList<Wire>([wire]) 
    }
    init(wires: ArrayList<Wire>) { 
        this.conn = None<Target>
        this.wires = wires 
    }
    func RemoveConn() {
        if(HasConn()){
            let t = GetConn()
            this.conn = None<Target>
            t.RemoveConn()
        }
    }
    func SetConn(t : Target) {
        if(HasConn()){
            GetConn().RemoveConn()
        }
        this.conn = Some<Target>(t)
        if(!t.HasConn() || t.HasConn() && t.GetConn() != this){
            t.SetConn(this)
        }
    }
    func GetConn() : Target {
        match(conn){
            case Some(t) => t
            case $None   => throw MissingConnectionException("GetConn", this)
        }
    }
    func HasConn(){
        match(conn){
            case Some(t) => true
            case $None   => false
        }
    }
    func GetRightPort(){
        GetPort()
    }
    func GetLeftPort(){
        GetConn().GetPort()
    }
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
    override func toString() {
        var wireString = ""
        for (wire in wires){
            let wireText = match(wire.bus.name){
                case Some(str) => str
                case $None     => ""
            }
            wireString = if(wireString == "") { "${wireText}" } else { "${wireString}, ${wireText}" }
        }
        return "Source s${id} ${wireString}" 
    }
}
append Source with ToString {
    func toString(s : Source){
        s.toString()
    }
}
append Source with Equatable, Hashable {
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
    PrintList(xs, {s : Source =>
        var idString = "${s.id}"
        var wireString = ""
        for(wire in s.wires){
            let wirename = match(wire.bus.name){
                case Some(name) => "${name}[${wire.i}]"
                case $None      => ""
            }
            wireString = if(wirename == "") { wireString } else if(wireString == "") { "${wirename}" } else { "${wireString}, ${wirename}" }
        }
        wireString = if(wireString == "") { "" } else { " (${wireString})" }
        "${idString}${wireString}"
    })
}
/**
 * Target vertices are inwards facing ports: they are the targets of edges.
 * Target vertices currently don't have anything particularly special about them
 */
external class Target <: Vertex {
    private var conn : Option<Source>
    init() {
        this.conn = None<Source>
    }
    func RemoveConn() {
        if(HasConn()){
            let s = GetConn()
            this.conn = None<Source>
            s.RemoveConn()
        }
    }
    func SetConn(s : Source) {
        if(HasConn()){
            GetConn().RemoveConn()
        }
        this.conn = Some<Source>(s)
        if(!s.HasConn() || s.HasConn() && s.GetConn() != this){
            s.SetConn(this)
        }
    }
    func GetConn() : Source {
        match(conn){
            case Some(s) => s
            case $None   => throw MissingConnectionException("GetConn", this)
        }
    }
    func HasConn(){
        match(conn){
            case Some(s) => true
            case $None   => false
        }
    }
    func GetRightPort(){
        GetConn().GetPort()
    }
    func GetLeftPort(){
        GetPort()
    }
    override func toString() { "Target t${id}" }
}
append Target with ToString{
    func toString(t : Target){
        t.toString()
    }
}
append Target with Equatable, Hashable {
    operator func ==(lhs : Target, rhs : Target) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Target, rhs : Target) : Bool { lhs.id != rhs.id }
    func hashCode(t : Target) : UInt64 { t.id }
}
/** 
 * Get a string representing a list of target vertices
 * The string is formatted like [ 1 2 3 ]
 * @param xs The list of targets
 * @return A string containing a space-separated list of the targets
 */
func TargetListToString(xs : ArrayList<Target>){ 
    PrintList(xs, {t : Target => "${t.id}"})
}
/**
 * Edges have an associated generator, and lists of sources and targets
 */
external open class Edge <: Atom {
    let generator : Generator
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(gen : Generator, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.generator = gen
        if(sources.size() != Dom(gen)){
            throw BadDomainException("Edge", sources.size(), Dom(gen))
        }
        if(targets.size() != Cod(gen)){
            throw BadCodomainException("Edge", targets.size(), Cod(gen))
        }
        this.sources = sources
        this.targets = targets
        for(i in 0..Dom(gen)){
            sources[i].SetPort(EdgePort(this, i))
        }
        for(i in 0..Cod(gen)){
            targets[i].SetPort(EdgePort(this, i))
        }
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
    override func toString() { 
        "Edge e${id} - ${generator}" 
    }
    /**
     * Assuming this edge is a link, get its spec
     * Throws an exception if this is not a link edge
     * @return The link spec
     */
    func GetSpec(){
        match(generator){
            case INLINK(spec) => spec
            case OUTLINK(spec) => spec
            case _ => throw NonLinkEdgeException("GetSpec", this)
        }
    }
    /**
     * Assuming this edge is a value, get the value
     * Throws an exception if this is not a value edge
     * @return The value
     */
    func GetValue(){
        match(generator){
            case VALUE(v) => v
            case _        => throw NonValueEdgeException("GetValue", this)
        }
    }
}
append Edge with ToString {
    func toString(e : Edge){
        e.toString()
    }
}
append Edge with Equatable, Hashable {
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
    PrintList(xs, { e : Edge => "Edge e${e.id}"})
}
/**
 * Vertices connect to ports, either on an edge or on the interface 
 */
enum Port { 
    | EdgePort(Edge, Int64) 
    | InterfacePort(Int64) 
}

append Port with ToString {
    func toString(p : Port){
    match(p){
            case EdgePort(e, i)   => "Edge port ${e.id}[${i}]"
            case InterfacePort(i) => "Interface port ${i}"
        }
    }
}