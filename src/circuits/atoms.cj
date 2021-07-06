/**
 * atoms.cj
 *
 * This file contains the definition of atoms that make up hypergraphs
 */
package circuits

import debug.*

/**
 * Base class for objects that have a unique id
 */
open class Identifiable {
    static var nextid : UInt64 = 0
    let id : UInt64
    init() { 
        this.id = nextid
        nextid++
    }
}
extend Identifiable <: Hashable {
    func hashCode() : UInt64 { this.id }
}

/**
 * Base class for objects that are atoms: their equality is determined solely by their id
 * Atoms also have a concept of *global id*, where multiple atoms can correspond to the same actual object
 * e.g. the same gate in a circuit can be represented by different atoms in different graphs
 */
abstract class Atom <: Identifiable {
    let globalId : UInt64
    func GetString() : String
    init(){
        this.globalId = this.id
    }
    /**
     * Check if this atom has the same global id as another atom
     */
    func Same(a : Atom){
        a.globalId == globalId
    }
}
extend Atom <: ToString {
    func toString(){
        this.GetString()
    }
}
extend Atom <: Equatable {
    operator func ==(rhs : Atom) : Bool { this.id == rhs.id }
    operator func !=(rhs : Atom) : Bool { this.id != rhs.id }
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
 * Class of elements that may have an associated hypergraph
 */
abstract class HypergraphElement <: Atom {
    var hypergraph : Option<HypergraphStructure> = None<HypergraphStructure>
    func SetHypergraph(f : HypergraphStructure){
        this.hypergraph = Some(f)
    }
    func RemoveHypergraph(){
        this.hypergraph = None<HypergraphStructure>
    }
    func GetHypergraph() : HypergraphStructure {
        match(hypergraph){
            case Some(f) => f
            case $None   => throw NoAssociatedHypergraphException("GetHypergraph", this)
        }
    }
}

/**
 * Base vertex class 
 */
abstract class Vertex <: HypergraphElement {
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
    init(globalId : UInt64, wires : ArrayList<Wire>){
        this.globalId = globalId
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
    func AddWires(wires : ArrayList<Wire>) { 
        for(w in wires){
            if(!includes(this.wires, w)){
                this.wires.add(w)
            }
        }
    }
    func RemoveAllWires(){
        wires.clear()
    }
    func GetString() {
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
    init(globalId : UInt64){
        this.globalId = globalId
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
    func GetString() { "Target t${id}" }
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
external open class Edge <: HypergraphElement {
    let generator : Generator
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(globalId: Option<UInt64>, gen : Generator, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.globalId = match(globalId){
            case Some(i) => i
            case $None   => this.id 
        }
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
        if(IsInlink(gen)){
            let link = GetLink(gen)
            link.AddInLinkEdge(this)
        }
        if(IsOutlink(gen)){
            let link = GetLink(gen)
            link.AddOutLinkEdge(this)
        }
    }
    init(gen : Generator, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this(None<UInt64>, gen, sources, targets)
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
    func GetString() { 
        "Edge e${id} - ${generator}" 
    }
    /**
     * Get the source from this edge with a given index
     * Throws an exception if the index is bad
     * @param i The index of the source
     * @return The source vertex
     */
    func GetSource(i : Int64){
        if(i < 0 || i >= sources.size()){
            throw BadSourceException("GetSource", this, i)
        }
        sources[i]
    }
    /**
     * Get the target from this edge with a given index
     * Throws an exception if the index is bad
     * @param i The index of the target
     * @return The target vertex
     */
    func GetTarget(i : Int64){
        if(i < 0 || i >= targets.size()){
            throw BadTargetException("GetTarget", this, i)
        }
        targets[i]
    }
    /**
     * Set the source of this edge with a given index
     * Throws an exception if the index is bad
     * @param i The index of the source
     * @param s The new source vertex
     */
    func SetSource(i : Int64, s : Source){
        if(i < 0 || i >= sources.size()){
            throw BadSourceException("SetSource", this, i)
        }
        sources.set(i, s)
        s.SetPort(this, i)
    }
    /**
     * Set the target of this edge with a given index
     * Throws an exception if the index is bad
     * @param i The index of the target
     * @param t The new target vertex
     */
    func SetTarget(i : Int64, t : Target){
        if(i < 0 || i >= targets.size()){
            throw BadTargetException("SetTarget", this, i)
        }
        targets.set(i, t)
        t.SetPort(this, i)
        
    }
    /**
     * Is this edge an identity edge?
     * @return if the edge is an identity edge
     */
    func IsIdentity(){
        match(generator){
            case $IDENTITY => true
            case _         => false
        }
    }
    /**
     * Is this edge a delay edge?
     * @return if the edge is an delay edge
     */
    func IsDelay(){
        match(generator){
            case DELAY(n) => true
            case _        => false
        }
    }
    /**
     * Is this edge a value edge?
     * @return if the edge is a value edge
     */
    func IsValue(){
        match(generator){
            case VALUE(v) => true
            case _        => false
        }
    }
    /**
     * Is this edge a gate edge?
     * @return if the edge is a gate edge
     */
    func IsGate(){
        match(generator){
            case GATE(k) => true
            case _       => false
        }
    }
    /**
     * Is this edge an inlink edge?
     * @return if the edge is an inlink edge
     */
    func IsInlink(){
        match(generator){
            case INLINK(link) => true
            case _            => false
        }
    }
    /**
     * Is this edge an outlink edge?
     * @return if the edge is an outlink edge
     */
    func IsOutlink(){
        match(generator){
            case OUTLINK(link) => true
            case _             => false
        }
    }
    /**
     * Is this edge a stub edge?
     * @return if the edge is a stub edge
     */
    func IsStub(){
        match(generator){
            case STRUCTURAL(s) => match(s){
                case $StubMorph => true
                case _ => false
            }
            case _ => false
        }
    }
    /**
     * Assuming this edge is a link, get its link
     * Throws an exception if this is not a link edge
     * @return The link
     */
    func Getlink(){
        match(generator){
            case INLINK(link) => link
            case OUTLINK(link) => link
            case _ => throw NonLinkEdgeException("Getlink", this)
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
    /**
     * Assuming this edge is a delay edge, get the value of the delay
     * Throws an exception if it is not a delay edge
     * @return if the edge is an identity edge
     */
    func GetDelay(){
        match(generator){
            case DELAY(n) => n
            case _        => throw NonDelayEdgeException("GetDelay", this)
        }
    }
    /**
     * Check if it this edge has a given value
     * @return If the edge is this value
     */
    func HasValue(v : Value){
        match(generator){
            case VALUE(v2) => v2 == v
            case _         => false
        }
    }
    /**
     * Check if it this edge has a given generator
     * @return If the edge is this value
     */
    func HasGenerator(gen : Generator) : Bool {
        generator == gen
    }
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
/**
 * Check if this port leads to a value
 * @param p The port to check
 * @return Whether the port leads to a value
 */
func IsValue(p : Port){
    match(p){
        case EdgePort(e, i) => e.IsValue()
        case InterfacePort(i) => false
    }
}
/**
 * Check if this port leads to a delay
 * @param p The port to check
 * @return Whether the port leads to a delay
 */
func IsDelay(p : Port){
    match(p){
        case EdgePort(e, i) => e.IsDelay()
        case InterfacePort(i) => false
    }
}

func IsInterface(p : Port){
    match(p){
        case EdgePort(e, i) => false
        case InterfacePort(i) => true
    }
}

extend Port <: ToString {
    func toString(){
    match(this){
            case EdgePort(e, i)   => "Edge port ${e.id}[${i}]"
            case InterfacePort(i) => "Interface port ${i}"
        }
    }
}