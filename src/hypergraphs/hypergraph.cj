/**
 * hypergraphs.cj
 *
 * This file contains the definition of hypergraphs and their components
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
            wires = (wires == "" ? "${wiretext}" : "${wires}, ${wiretext}")
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
            wires = wirename == "" ? wires : wires == "" ? " ${wirename}" : "${wires}, ${wirename}"
        }
        wires = wires == "" ? "" : "(${wires})"
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

func UpdateBuses(busMaps : MapBuilder<Bus, MapBuilder<Int64, Source>>, busList : ArrayList<Bus>, wireList : ArrayList<Wire>, v : Source){
        for(wire in v.wires){
            wireList.add(wire)
            let bus = wire.bus
            match(busMaps.toMap().get(bus)){
                case Some(ws) => {
                    let x = ws.add(wire.i, v)
                }
                case $None     => {
                    let mb = MapBuilder<Int64, Source>()
                    mb.add(wire.i, v)
                    busMaps.add(bus, mb)
                    let x = busList.add(bus)
                }
            }
        }

        (busMaps, busList, wireList)
    }

/**
 * Hypergraph
 */
external class Hypergraph <: Atom {

    private let name    : String

    private let edges   : ArrayList<Edge>
    private let inputs  : ArrayList<Target>
    private let outputs : ArrayList<Source>
    private let connsr  : MapBuilder<Target, Source>
    private let connsl  : MapBuilder<Source, Target> 

    // TODO should be sets but I don't know how to make them dynamically
    private let sources : ArrayList<Source>
    private let targets : ArrayList<Target>

    // The map between target vertices and the edge they are the target of
    private let lefts   : Map<Target, Port>
    // The map between source vertices and the edge they are the source of
    private let rights  : Map<Source, Port>

    private let m       : Int64
    private let n       : Int64

    private let buses         : ArrayList<Bus>
    private let wires         : ArrayList<Wire>
    private let busVertexMaps : Map<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>

    init(edges    : ArrayList<Edge>, 
          inputs   : ArrayList<Target>,
          outputs  : ArrayList<Source>,
          conns    : MapBuilder<Target, Source>
    ) {
         this(None<String>, edges, inputs, outputs, conns)
    }

    init(name    : Option<String>,
         edges   : List<Edge>, 
         inputs  : List<Target>, 
         outputs : List<Source>, 
         conns   : MapBuilder<Target,Source>
    ){
        this(name, ArrayList<Edge>(edges), ArrayList<Target>(inputs), ArrayList<Source>(outputs), conns)
    }

    init(name     : Option<String>,
         edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : MapBuilder<Target, Source>
    ){

        this.name = match(name){
            case Some(text) => text == "" ? "h${this.id}" : text
            case $None      => "h${this.id}"
        }

        this.edges    = edges
        this.inputs   = inputs
        this.outputs  = outputs
        this.connsr    = conns

        this.m = inputs.size()
        this.n = outputs.size()

        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()

        let leftMap = MapBuilder<Target, Port>()
        let rightMap = MapBuilder<Source, Port>()
        var busList = ArrayList<Bus>()
        var wireList = ArrayList<Wire>()
        var busMaps = MapBuilder<Bus, MapBuilder<Int64, Source>>()

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
            (busMaps, busList, wireList) = UpdateBuses(busMaps, busList, wireList, v)
        }

        // HACK: for some reason it segfaults if you try to loop over the empty list
        if(edges.size() != 0) {
            for(e in edges){
                // Add sources to the list of sources
                for(i in 0..e.sources.size()){
                    let v = e.sources.get(i)
                    sources.add(v)
                    rightMap.add(v, EdgePort(e,i))
                    // Update the buses list with any intermediate buses
                    (busMaps, busList, wireList) = UpdateBuses(busMaps, busList, wireList, v)
                    
                }
                // Add targets to the list of targets
                for(i in 0..e.targets.size()){
                    let v = e.targets.get(i)
                    targets.add(v)
                    leftMap.add(v, EdgePort(e,i))
                }
            }
        }
        // We can use the right conns map to define the left conns map
        this.connsl = MapBuilder<Source, Target>() 
        // TODO use for((t,s) in connsr) when convinced it works
        for(v in targets){
            connsl.add(GetConnR(v), v)
        }
        let busMapLists = MapBuilder<Bus, MapBuilder<Int64, Source> * ArrayList<Source>>()
        // TODO use for((bus, targetList) in busMaps) when convinced it works)
        for(bus in busList){
            match(busMaps.toMap().get(bus)){
                case $None => throw BusNotInGraphException("Hypergraph", bus)
                case Some(mb) => {
                    let vertexList = ArrayList<Source>()
                    let wires = bus.wires
                    for(wire in wires){
                        let v = match(mb.toMap().get(wire.i)) {
                            case Some(s) => s
                            case $None   => throw WireNotInGraphException("Hypergraph", wire)
                        }
                        vertexList.add(v)
                    }
                    busMapLists.add(bus, (mb, vertexList))
                }
            }
        }

        this.lefts = leftMap.toMap()
        this.rights = rightMap.toMap()

        this.busVertexMaps = busMapLists.toMap()
        this.buses        = busList
        this.wires        = wireList
    }

    func GetName() { name }

    func GetEdges() { edges }
    func GetInputs() { inputs }
    func GetOutputs() { outputs }
    func GetConnsR() { connsr }
    func GetConnsL() { connsl }

    func GetM() { m }
    func GetN() { n }

    func GetSources() { sources }
    func GetTargets() { targets }

    func GetWires() { wires }
    func GetBuses() { buses }

    /**
     * Get the vertex that corresponds to this wire, or throw an exception if it doesn't exist
     * @param w The wire
     * @return The vertex that corresponds to this wire
     */
    func GetWireVertex(w : Wire) { 
        match(GetWireVertexOption(w)){
            case Some(v) => v
            case $None   => throw WireNotInGraphException("GetWireVertex", w)
        }
    }   
    /**
     * Get an option containing either the vertex that corresponds to this wire, or None
     * @param w The wire
     * @return Some(vertex) if it exists in this graph, or None otherwise
     */
    func GetWireVertexOption(w : Wire){
        match(busVertexMaps.get(w.bus)){
             case Some((mb, vs)) => mb.toMap().get(w.i)
             case $None    => None<Source>
        }
    }
    /**
     * Get the index-vertex map of vertices belonging to a given bus 
     * @param s The bus
     * @return  The index-vertex map of vertices belonging to this bus
     */  
    func GetBusVertexMap(b : Bus){
        busVertexMaps.get(b)
    }
    /**
     * Get the index-vertex map of vertices belonging to a given bus 
     * @param s The name of the bus
     * @return  The index-vertex map of vertices belonging to this bus
     */  
    func GetBusVertexMap(s : String) {
        let b = GetBus(s)
        GetBusVertexMap(b)
    }
    /**
     * Get the list of vertices belonging to a given bus and append them to an existing list
     * @param b  The bus
     * @param vs The list of vertices to append to
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(b : Bus, vs : ArrayList<Source>){
        match(busVertexMaps.get(b)){
            case Some((mb, ss)) => vs.addAll(ss)
            case $None          => throw BusNotInGraphException("GetBusVertexList", b)
        }
        vs
    }
    /**
     * Get the list of vertices belonging to a given bus and append them to an existing list
     * @param s  The name of the bus
     * @param vs The list of vertices to append to
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(s : String, vs : ArrayList<Source>){
        let b = GetBus(s)
        GetBusVertexList(b, vs)
    }
    /**
     * Get the list of vertices belonging to a given bus 
     * @param b The bus
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(b : Bus){
        let vs = ArrayList<Source>()
        GetBusVertexList(b, vs)
    }
    /**
     * Get the list of vertices belonging to a given bus 
     * @param s The name of the bus
     * @return The list of vertices that belong to this bus
     */
    func GetBusVertexList(s : String){
        let vs = ArrayList<Source>()
        GetBusVertexList(s, vs)
    }

    func GetConnR(t : Target) {
        match(connsr.toMap().get(t)){
            case $None => throw VertexNotInGraphException("GetConnR", t)
            case Some(s) => s
        }
    }
    func GetConnL(s : Source) {
        match(connsl.toMap().get(s)){
            case $None => throw VertexNotInGraphException("GetConnL", s)
            case Some(t) => t
        }
    }
    func GetEdge(s : Source) { 
        match(rights.get(s)){
            case $None => throw VertexNotInGraphException("GetEdge (source)", s)
            case Some(p) => p 
        }
    }
    func GetEdge(t : Target) { 
        match(lefts.get(t)){
            case $None => throw VertexNotInGraphException("GetEdge (target)", t)
            case Some(p) => p
        }
    }
    func ContainsBus(b : String) {
        let b = GetBus(b)
        match(busVertexMaps.get(b)){
            case Some(x) => return true
            case $None   => return false
        }
    }
    /** Follow the path from a target vertex to find its successor edge 
     * @param target The vertex to traverse from
     * @return The port reached by following this target
     */
    func NextEdge(target : Target){
        GetEdge(GetConnR(target))
    }
    /**
     * Follow the path from the ith target of an edge to find its successor edge
     * @param edge The edge to traverse from
     * @param i    The index of the target
     * @return The port reached by following this target.
     */
    func NextEdge(edge : Edge, i : Int64){
        if(i < 0 || i >= edge.targets.size()){
            throw BadTargetsException("NextEdge", edge, i)
        }
        NextEdge(edge.targets[i])
    }
    /** Follow the path from a source vertex to find its predecessor edge 
     * @param source The vertex to traverse from
     * @return The port reached by following this target
     */
    func PreviousEdge(source : Source){
        GetEdge(GetConnL(source))
    }
    /**
     * Follow the path from the ith source of an edge to find its predecessor edge
     * @param edge The edge to traverse from
     * @param i    The index of the source
     * @return The port reached by following this source.
     */
    func PreviousEdge(edge : Edge, i : Int64){
        if(i < 0 || i >= edge.sources.size()){
            throw BadSourcesException("NextEdge", edge, i)
        }
        PreviousEdge(edge.sources[i])
    }


    /**
     * Check that this hypergraph is disjoint with another
     * i.e. none of its atoms are the same
     * @param f The hypergraph to compare with
     * @return Whether the hypergraphs are disjoint
     */
    func Disjoint(f : Hypergraph){
        if(edges.size() != 0 && f.GetEdges().size() != 0){
            for(e in edges){
                for(ef in f.GetEdges()){
                    if(e.id == ef.id){
                        return false
                    }
                }
            }
        }
        if(targets.size() != 0 && f.GetTargets().size() != 0){
            for(t in targets){
                for(tf in f.GetTargets()){
                    if(t.id == tf.id){
                        return false
                    }
                }
            }
        }
        if(sources.size() != 0 && f.GetSources().size() != 0){
            for(s in sources){
                for(sf in f.GetSources()){
                    if(s.id == sf.id){
                        return false
                    }
                }
            }
        }
        return true
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
        // HACK: for some reason it segfaults if you try to loop over the empty list
        if(edges.size() != 0){
            for(e in edges){
                let s = e.sources
                let t = e.targets
                let s2 = ArrayList<Source>()
                let t2 = ArrayList<Target>()
                for (v in s){
                    let v2 = match(newSourceMap.get(v)){
                        case Some(v2) => v2
                        case $None    => throw VertexNotInGraphException("Clone", v)
                    }
                    s2.add(v2)
                }
                for (v in t){
                    let v2 = match(newTargetMap.get(v)){
                        case Some(v2) => v2
                        case $None    => throw VertexNotInGraphException("Clone", v)
                    }
                    t2.add(v2)
                }
                let e2 = Edge(e.generator, s2, t2)
                newEdges.add(e2)
            }
        }

        // Use the vertex maps to get the new inputs
        let newInputs = ArrayList<Target>()
        for(v in inputs){
            let v2 = match(newTargetMap.get(v)){
                case Some(v2) => v2
                case $None    => throw VertexNotInGraphException("Clone", v)
            }
            newInputs.add(v2)
        }
        // Use the vertex maps to get the new outputs
        let newOutputs = ArrayList<Source>()
        for(v in outputs){
            let v2 = match(newSourceMap.get(v)){
                case Some(v2) => v2
                case $None    => throw VertexNotInGraphException("Clone", v)
            }
            newOutputs.add(v2)
        }
        // Use the vertex maps to get the new connections
        let newConns = MapBuilder<Target, Source>()
        for(v in targets){
            let newT = match(newTargetMap.get(v)){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException("Clone", v)
            }
            let newS = match(newSourceMap.get(GetConnR(v))){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException("Clone", GetConnR(v))
            }
            newConns.add(newT, newS)
        }
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
           connstr = "${connstr}(${t.id} ${f.GetConnR(t).id}) "
        }
        "${f.GetName()}\n${inputString}\n${str}${outputString}\n${connstr}"
    }
}

/**
 * Get the number of outputs of a list of hypergraphs 
 * @param fs The list of hypergraphs
 * @return The combined outputs of all hypergraphs in the list
 */
func GetListOutputs(fs : ArrayList<Hypergraph>){
    var n = 0
    for(f in fs){
        n += f.GetN()
    }
    n
}
/**
 * Get the number of outputs of a list of hypergraphs 
 * @param fs The list of hypergraphs
 * @return The combined outputs of all hypergraphs in the list
 */
func GetListOutputs(fs : List<Hypergraph>){
    var n = 0
    for(f in fs){
        n += f.GetN()
    }
    n
}

/**
 * Generic includes function for arraylists
 * Presumably this will make its way into the standard library at some points
 * @param xs The arraylist to search
 * @param a  The element to search for
 * @return Whether this element is in the arraylist
 */
func includes<T>(xs : ArrayList<T>, a : T) where T <: Equatable {
    for(x in xs){
        if(x == a){
            return true
        }
    }
    return false
}

func PrintList<T>(xs : ArrayList<T>) where T <: ToString {
    var str = "["
    for(x in xs){
        str = "${str} ${x}"
    }
    str = "${str} ]"
    str
}

func GetAll(f : Hypergraph, g : Generator){
    let edges = ArrayList<Edge>(f.GetEdges())
    edges.removeIf({x : Edge => x.generator == g})
    edges
}

func GetEndpoints(f : Hypergraph){
    let vs = ArrayList<Source>(f.GetOutputs())
    for(e in f.GetEdges()){
        if(e.targets.size() == 0){
            vs.addAll(e.sources)
        }
    }
    vs
}