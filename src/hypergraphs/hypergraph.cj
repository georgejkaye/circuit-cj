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

func UpdateBuses(wireMap : MapBuilder<Bus, MapBuilder<Int64, Source>>, busList : ArrayList<Bus>, wireList : ArrayList<Wire>, v : Source){
        for(wire in v.wires){
            wireList.add(wire)
            let bus = wire.bus
            match(wireMap.toMap().get(bus)){
                case Some(ws) => {
                    let x = ws.add(wire.i, v)
                }
                case $None     => {
                    let mb = MapBuilder<Int64, Source>()
                    mb.add(wire.i, v)
                    wireMap.add(bus, mb)
                    let x = busList.add(bus)
                }
            }
        }

        (wireMap, busList, wireList)
    }

/**
 * Hypergraph
 */
external class Hypergraph <: Atom {

    private let name    : String

    private let edges   : ArrayList<Edge>
    private let inputs  : ArrayList<Target>
    private let outputs : ArrayList<Source>
    private let connsr  : Map<Target, Source>
    private let connsl  : Map<Source, Target> 

    // TODO should be sets but I don't know how to make them dynamically
    private let sources : ArrayList<Source>
    private let targets : ArrayList<Target>

    // The map between target vertices and the edge they are the target of
    private let lefts   : Map<Target, Port>
    // The map between source vertices and the edge they are the source of
    private let rights  : Map<Source, Port>

    private let m       : Int64
    private let n       : Int64

    private let buses        : ArrayList<Bus>
    private let wires        : ArrayList<Wire>
    private let busVertices  : Map<Bus, MapBuilder<Int64, Source>>

    init(edges    : ArrayList<Edge>, 
          inputs   : ArrayList<Target>,
          outputs  : ArrayList<Source>,
          conns    : Map<Target, Source>
    ) {
         this(None<String>, edges, inputs, outputs, conns)
    }

    init(name    : Option<String>,
         edges   : List<Edge>, 
         inputs  : List<Target>, 
         outputs : List<Source>, 
         conns   : Map<Target,Source>
    ){
        this(name, ArrayList<Edge>(edges), ArrayList<Target>(inputs), ArrayList<Source>(outputs), conns)
    }

    init(name     : Option<String>,
         edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : Map<Target, Source>
    ){

        this.name = match(name){
            case Some(text) => text == "" ? "h${this.id}" : text
            case $None      => "h${this.id}"
        }

        Debug("Hypergraph", "Creating hypergraph '${this.name}'")

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

        var busMap = MapBuilder<Bus, MapBuilder<Int64, Source>>()

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
            (busMap, busList, wireList) = UpdateBuses(busMap, busList, wireList, v)
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
                    (busMap, busList, wireList) = UpdateBuses(busMap, busList, wireList, v)
                    
                }
                // Add targets to the list of targets
                for(i in 0..e.targets.size()){
                    let v = e.targets.get(i)
                    targets.add(v)
                    leftMap.add(v, EdgePort(e,i))
                }
            }
        }

        this.lefts = leftMap.toMap()
        this.rights = rightMap.toMap()

        this.busVertices  = busMap.toMap()
        this.buses        = busList
        this.wires        = wireList

        let connslMap = MapBuilder<Source, Target>()
 
        for(v in targets){
            connslMap.add(GetConnR(v), v)
        }
        this.connsl = connslMap.toMap()
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

    func GetWireVertex(w : Wire) { 
        match(GetWireVertexOption(w)){
            case Some(v) => v
            case $None   => throw WireNotInGraphException("GetWireVertex", w)
        }
    }   

    func GetWireVertexOption(w : Wire){
        match(busVertices.get(w.bus)){
             case Some(ws) => ws.toMap().get(w.i)
             case $None    => None<Source>
        }
    }

    func GetBusVertices(b : Bus){
        busVertices.get(b)
    }

    func GetBusVertices(s : String) {
        let b = GetBus(s)
        GetBusVertices(b)
    }

    func GetConnR(t : Target) {
        match(connsr.get(t)){
            case $None => throw VertexNotInGraphException("GetConnR", t)
            case Some(s) => s
        }
    }
    func GetConnL(s : Source) {
        match(connsl.get(s)){
            case $None => throw VertexNotInGraphException("GetConnL", s)
            case Some(t) => t
        }
    }
    func GetEdge(s : Source) { 
        match(rights.get(s)){
            case $None => throw VertexNotInGraphException("GetEdge", s)
            case Some(p) => p 
        }
    }
    func GetEdge(t : Target) { 
        match(lefts.get(t)){
            case $None => throw VertexNotInGraphException("GetEdge", t)
            case Some(p) => p
        }
    }
    func ContainsBus(b : String) {
        let b = GetBus(b)
        match(busVertices.get(b)){
            case Some(x) => return true
            case $None   => return false
        }
    }

    /**
     * Check that this hypergraph is disjoint with another
     * i.e. none of its atoms are the same
     * @param f The hypergraph to compare with
     * @return Whether the hypergraphs are disjoint
     */
    func Disjoint(f : Hypergraph){
        Debug("Disjoint", "Checking that '${name}' and '${f.GetName()}' are disjoint")
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
        Debug("Clone", "Cloning hypergraph ${this.name}")
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
        let newConnsBuilder = MapBuilder<Target, Source>()
        for(v in targets){
            let newT = match(newTargetMap.get(v)){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException("Clone", v)
            }
            let newS = match(newSourceMap.get(GetConnR(v))){
                    case Some(v2) => v2
                    case $None     => throw VertexNotInGraphException("Clone", GetConnR(v))
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
        //Get(f,n)
    }
    /**
     * Syntax sugar for creating a hypergraph with only a certain bus from a hypergraph exposed.
     * All other outputs will be stubbed.
     * @param f The hypergraph to consider
     * @param n The name of the bus we want to isolate
     * @return A hypergraph with only the given bus exposed.
     */
    operator func [](f : Hypergraph, s : String){
        //Get(f,s)
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
        var leftstr = "left "
        for(t in f.GetTargets()) {
            leftstr = "${leftstr}(${t.id} => "
            match(f.GetEdge(t)){
                case EdgePort(e, i) => leftstr = "${leftstr}${e.id}:${i}) "
                case InterfacePort(i) => leftstr = "${leftstr}input:${i}) "
            }
        }
        var rightstr = "right "
        for(s in f.GetSources()) {
            rightstr = "${rightstr}(${s.id} => "
            match(f.GetEdge(s)){
                case EdgePort(e, i) => rightstr = "${rightstr}${e.id}:${i}) "
                case InterfacePort(i) => rightstr = "${rightstr}output:${i}) "
            }
        }
        "${f.GetName()}\n${inputString}\n${str}${outputString}\n${connstr}\n${leftstr}\n${rightstr}"
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