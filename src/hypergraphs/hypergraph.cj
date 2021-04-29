/**
 * hypergraphs.cj
 *
 * This file contains the definition of hypergraphs and their components
 */

package hypergraphs

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
 * A bus is a bundle of wires with a name
 */
class Bus <: Atom {
    let name : Option<String>
    var width : Int64
    init() {
        this.name = None<String>
        this.width = 0
    }
    init(name : String) {
        this.name = name
        this.width = 0
    }
    /**
     * Add a wire to the bundle of wires and get its position
     * @return The position of the new wire in the bundle
     */
    func AddWire(){
        let nextindex = this.width
        this.width++
        nextindex
    }
}
append Bus with ToString, Equatable, Hashable {
    func toString(b : Bus){
        let name = match(b.name){
            case Some(name) => name
            case $None      => "b${b.id}"
        }
        "bus ${name}"
    }
    operator func ==(lhs : Bus, rhs : Bus) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Bus, rhs : Bus) : Bool { lhs.id != rhs.id }
    func hashCode(b : Bus) : UInt64 { b.id }
}

/**
 * A wire corresponds to one vertex in the graph
 * It has a parent bus and the position it occupies in that bus
 */
class Wire <: Atom {
    let bus : Bus
    let i : Int64
    init(bus: Bus, i : Int64){
        this.bus = bus
        this.i = i
    }
    init(){
        this.bus = Bus()
        this.i = 0
    }
}
append Wire with ToString, Equatable {
    func toString(w : Wire){
        let name = match(w.bus.name){
            case Some(name) => name
            case $None      => "b${w.bus.id}"
        }
        "${name}[${w.i}]"
    }
    operator func ==(lhs : Wire, rhs : Wire) : Bool { lhs.bus == rhs.bus && lhs.i == rhs.i }
    operator func !=(lhs : Wire, rhs : Wire) : Bool { lhs.id != rhs.id || lhs.i != rhs.i }
}

/**
 * Get the bus that corresponds to a given string from a list of buses
 * @param name  The name to look for
 * @param buses The list of buses to check through
 * @return An optional containing the corresponding bus, or None if not found
 */
func GetBus(name : String, buses : ArrayList<Bus>){
    for (bus in buses){
        match(bus.name){
            case Some(text) => {
                if(name == text){ return bus }
            }
            case $None      => {}
        }
    }
    None<Bus>
}

/**
 * Get the bus that contains a given wire from a list of buses
 * @param wire  The wire to look for
 * @param buses The list of buses to check through
 * @return An optional containing the corresponding bus, or None if not found
 */
func GetBus(wire : Wire, buses : ArrayList<Bus>){
    for (bus in buses){
        if(bus == wire.bus){ return bus }
    }
    None<Bus>
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
class Source <: Vertex {
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
            wires = (wires == "" ? "${wire}" : "${wires}, ${wire}")
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
            wires = wires == "" ? " (${wire}" : "${wires}, ${wire}"
        }
        wires = wires == "" ? "" : "${wires})"
        str = "${str}${wires}"
    }
    str = "${str} ]"
    str
}


/**
 * Target vertices are inwards facing ports: they are the targets of edges.
 * Target vertices currently don't have anything particularly special about them
 */
class Target <: Vertex {}
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
open class Edge <: Atom {
    let generator : Generator
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(generator : Generator, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.generator = generator
        this.sources = sources
        this.targets = targets
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

/**
 * Hypergraph
 */
external class Hypergraph <: Atom {

    private let name    : String

    private let edges   : ArrayList<Edge>
    private let inputs  : ArrayList<Target>
    private let outputs : ArrayList<Source>
    private let conns   : Map<Target, Source>

    // TODO should be sets but I don't know how to make them dynamically
    private let sources : ArrayList<Source>
    private let targets : ArrayList<Target>

    // The map between target vertices and the edge they are the target of
    private let lefts   : Map<Target, Port>
    // The map between source vertices and the edge they are the source of
    private let rights  : Map<Source, Port>

    private let m       : Int64
    private let n       : Int64

    private let buses   : ArrayList<Bus>

    init(edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : Map<Target, Source>
    ) {
        this(None<String>, edges, inputs, outputs, conns)
    }

    init(name     : Option<String>,
         edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : Map<Target, Source>
    ){

        match(name){
            case Some(text) => this.name = text
            case $None      => this.name = "h${this.id}"
        }

        this.edges    = edges
        this.inputs   = inputs
        this.outputs  = outputs
        this.conns    = conns

        this.m = inputs.size()
        this.n = outputs.size()

        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()
        this.buses = ArrayList<Bus>()
        let leftMap = MapBuilder<Target, Port>()
        let rightMap = MapBuilder<Source, Port>()

        // Add inputs to the list of targets
        for(i in 0..inputs.size()){
            let v = inputs.get(i)
            targets.add(v)
            leftMap.add(v, InterfacePort(i))
        }
        // Add outputs to the list of sources
        for(i in 0..outputs.size()) {
            let v = outputs.get(i)
            sources.add(v)
            rightMap.add(v, InterfacePort(i))
            // Update the buses list with any output buses
            for(wire in v.wires){
                match(GetBus(wire, buses)){
                    case Some(bus) => {}
                    case $None     => buses.add(wire.bus)
                }
            }
        }

        for(e in edges){
            // Add sources to the list of sources
            for(i in 0..e.sources.size()){
                let v = e.sources.get(i)
                sources.add(v)
                rightMap.add(v, EdgePort(e,i))
                // Update the buses list with any intermediate buses
                for(wire in v.wires){
                    match(GetBus(wire, buses)){
                        case Some(bus) => {}
                        case $None     => buses.add(wire.bus)
                    }
                }
            }
            // Add targets to the list of targets
            for(i in 0..e.targets.size()){
                let v = e.targets.get(i)
                targets.add(v)
                leftMap.add(v, EdgePort(e,i))
            }
        }

        this.lefts = leftMap.toMap()
        this.rights = rightMap.toMap()

    }

    func GetName() { name }

    func GetEdges() { edges }
    func GetInputs() { inputs }
    func GetOutputs() { outputs }
    func GetConns() { conns }

    func GetM() { m }
    func GetN() { n }

    func GetSources() { sources }
    func GetTargets() { targets }

    func GetConn(t : Target) {
        match(conns.get(t)){
            case $None => throw VertexNotInGraphException(t)
            case Some(s) => s
        }
    }
    func GetEdge(s : Source) { 
        match(rights.get(s)){
            case $None => throw VertexNotInGraphException(s)
            case Some(p) => p 
        }
    }
    func GetEdge(t : Target) { 
        match(lefts.get(t)){
            case $None => throw VertexNotInGraphException(t)
            case Some(p) => p
        }
    }

    /**
     * Assign wires to the outputs of this graph
     * Throws BadOutputPortsException if the list of ports != the outputs
     * @param ports The list of wire names to assign
     */
    func NameOutputs(ports : ArrayList<String>){
        if(ports.size() != outputs.size()){
            throw BadOutputPortsException()
        }
        for(i in 0..ports.size()){
            let name = ports.get(i)
            let bus : Bus
            if(name == ""){
                bus = Bus()
                buses.add(bus)
            } else {
                let b = GetBus(name, buses)
                match(b){
                    case Some(x) => {
                        bus = x
                    }
                    case $None   => {
                        bus = Bus(name)
                        buses.add(bus)
                    }
                }
            }
            let wire = Wire(bus, bus.AddWire())
            outputs.get(i).AddWire(wire)
        }
    }

    /**
     * Refresh all the vertices and edges in this hypergraph, making
     * a completely new one with the same structure
     * @return The deep clone of the original hypergraph
     */
    func Clone(){
        // Make deep copies of the source vertices and make map between old and new
        let newSourceMapBuilder = MapBuilder<Source, Source>()
        for(v in sources){
            let v2 = Source(ArrayList<Wire>(v.wires)) 
            newSourceMapBuilder.add(v,v2)
        }
        // Make deep copies of the target vertices and make map between old and new
        let newTargetMapBuilder = MapBuilder<Target, Target>()
        for(v in targets){
            let v2 = Target()
            newTargetMapBuilder.add(v,v2)
        }
        let newSourceMap = newSourceMapBuilder.toMap()
        let newTargetMap = newTargetMapBuilder.toMap()

        // Make deep copies of the edges, and associate the newly copied vertices with them
        let newEdges = ArrayList<Edge>()
        for(e in edges){
            let s = e.sources
            let t = e.targets
            let s2 = ArrayList<Source>()
            let t2 = ArrayList<Target>()
            for (v in s){
                let v2 = match(newSourceMap.get(v)){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException(v)
                }
                s2.add(v2)
            }
            for (v in t){
                let v2 = match(newTargetMap.get(v)){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException(v)
                }
                t2.add(v2)
            }
            let e2 = Edge(e.generator, s2, t2)
            newEdges.add(e2)
        }

        // Use the vertex maps to get the new inputs
        let newInputs = ArrayList<Target>()
        for(v in inputs){
            let v2 = match(newTargetMap.get(v)){
                case Some(v2) => v2
                case $None    => throw VertexNotInGraphException(v)
            }
            newInputs.add(v2)
        }
        // Use the vertex maps to get the new outputs
        let newOutputs = ArrayList<Source>()
        for(v in outputs){
            let v2 = match(newSourceMap.get(v)){
                case Some(v2) => v2
                case $None    => throw VertexNotInGraphException(v)
            }
            newOutputs.add(v2)
        }
        // Use the vertex maps to get the new connections
        let newConnsBuilder = MapBuilder<Target, Source>()
        for(v in targets){
            let newT = match(newTargetMap.get(v)){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException(v)
            }
            let newS = match(newSourceMap.get(GetConn(v))){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException(GetConn(v))
            }
            newConnsBuilder.add(newT, newS)
        }
        let newConns = newConnsBuilder.toMap()
        Hypergraph(newEdges, newInputs, newOutputs, newConns)
    }

    /**
     * Syntax sugar for creating a hypergraph with only the nth output of a hypergraph exposed.
     * All other outputs will be stubbed.
     * @param f The hypergraph to consider
     * @param n The output we want to isolate
     * @return A hypergraph with only the nth output exposed
     */
    operator func [](f : Hypergraph, n : Int64){
        Get(f,n)
    }
    /**
     * Syntax sugar for creating a hypergraph with only a certain bus from a hypergraph exposed.
     * All other outputs will be stubbed.
     * @param f The hypergraph to consider
     * @param n The name of the bus we want to isolate
     * @return A hypergraph with only the given bus exposed.
     */
    operator func [](f : Hypergraph, s : String){
        Get(f,s)
    }

}
append Hypergraph with ToString {
    func toString(f : Hypergraph) : String {
        var str = ""
        let inputString = "inputs ${TargetListToString(f.GetInputs())}"
        for (e in f.GetEdges()) {
            let id = "e${e.id}"
            let gen = "${e.generator}"
            let sourceString = SourceListToString(e.sources)
            let targetString = TargetListToString(e.targets)
            str = "${str}${id} (${gen}) ${sourceString} ${targetString}\n"
        }
        let outputString = "outputs ${SourceListToString(f.GetOutputs())}"
        var connstr = "connections "
        for (t in f.GetTargets()) {
            connstr = "${connstr}(${t.id} ${f.GetConn(t).id}) "
        }
        "${f.GetName()}\n${inputString}\n${str}${outputString}\n${connstr}"
    }
}

func GetListOutputs(fs : ArrayList<Hypergraph>){
    var n = 0
    for(f in fs){
        n += f.GetN()
    }
    n
}
func GetListOutputs(fs : List<Hypergraph>){
    var n = 0
    for(f in fs){
        n += f.GetN()
    }
    n
}