package hypergraphs
// import core.*

class VertexNotInGraphException <: Exception {
    init(v : Vertex){
        print("Vertex ${v.id} is not in the graph")
    }
}

var nextid : UInt64 = 0
func genId(){
    let id = nextid
    nextid++
    id
}

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
    func AddWire(){
        let nextindex = this.width
        this.width++
        nextindex
    }
}
append Bus with ToString, Equatable {
    func toString(b : Bus){
        let name = match(b.name){
            case Some(name) => name
            case $None      => "b${b.id}"
        }
        "bus ${name}"
    }
    operator func ==(lhs : Bus, rhs : Bus) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Bus, rhs : Bus) : Bool { lhs.id != rhs.id }
}

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
append Wire with ToString, Equatable{
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

func FindWires(s : String, ws : ArrayList<Option<Wire>>){
    var x = 0
    for(wire in ws){
        match (wire){
            case Some(w) => match(w.bus.name){
                case Some(name) => if(name == s){ x++ }
                case $None      => {} 
            }
            case $None    => {}
        }
    }
    return x
}

func GetBus(wire : String, buses : ArrayList<Bus>){
    for (bus in buses){
        match(bus.name){
            case Some(name) => if(wire == name){ return bus }
            case $None      => {}
        }
    }
    None<Bus>
}
func GetBus(wire : Wire, buses : ArrayList<Bus>){
    for (bus in buses){
        if(bus == wire.bus){ return bus }
    }
    None<Bus>
}

/** 
 * Get a string representing a list of atoms 
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
 * Vertices are atoms
 */
open class Vertex <: Atom {
    open func ToString() { "Vertex v${this.id}" }
}

/**
 * Source vertices are outwards facing ports: they are the sources of edges.
 * Sources have names so that we can reference them later and connect them to new edges
 */
class Source <: Vertex {
    let wires : ArrayList<Wire>
    init() { this.wires = ArrayList<Wire>([Wire()])}
    init(wire: Wire) { this.wires = ArrayList<Wire>([wire]) }
    init(wires: ArrayList<Wire>) { this.wires = wires }
    func AddWire(wire : Wire) { this.wires.add(wire) }
    func AddWires(wires : ArrayList<Wire>) { this.wires.addAll(wires) }
}
append Source with ToString {
    func toString(s : Source) {
        var wires = ""
        for (wire in s.wires){
            wires = (wires == "" ? "${wire}" : "${wires}, ${wire}")
        }
        return "Source s${s.id} ${wires}" 
    }
}
// TODO should be redundant if inheritance works
func AtomListToString(xs : ArrayList<Source>){ 
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
class Target <: Vertex {
    override func ToString() { "Target t${this.id}" }
}
append Target with ToString {
    func toString(t : Target) { "Target t${t.id}" }
}

// TODO should be redundant if inheritance works
func AtomListToString(xs : ArrayList<Target>){ 
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
    }
    str = "${str} ]"
    str
}

/**
 * Edges are atoms
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
append Edge with ToString {
    func toString(e : Edge) { 
        "Edge e${e.id} - ${e.generator}" 
    }
}

// TODO should be redundant if inheritance works
func AtomListToString(xs : ArrayList<Edge>){ 
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
    }
    str = "${str} ]"
    str
}

// TODO: Can these not be done just for atom?
// It currently doesn't compile
append Source with Hashable, Equatable {
    operator func ==(lhs : Source, rhs : Source) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Source, rhs : Source) : Bool { lhs.id != rhs.id }
    func hashCode(t : Source) : UInt64 { t.id }
}
append Target with Hashable, Equatable {
    operator func ==(lhs : Target, rhs : Target) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Target, rhs : Target) : Bool { lhs.id != rhs.id }
    func hashCode(t : Target) : UInt64 { t.id }
}
append Edge with Hashable, Equatable {
    operator func ==(lhs : Edge, rhs : Edge) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Edge, rhs : Edge) : Bool { lhs.id != rhs.id }
    func hashCode(t : Edge) : UInt64 { t.id }
}

enum Port { EdgePort(Edge, Int64) | InterfacePort(Int64) }

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
    private let lefts   : Map<Target, Port>
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

        let leftMap = MapBuilder<Target, Port>()
        let rightMap = MapBuilder<Source, Port>()
        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()
        this.buses = ArrayList<Bus>()

        for(i in 0..inputs.size()){
            let v = inputs.get(i)
            targets.add(v)
            leftMap.add(v, InterfacePort(i))
        }
        for(i in 0..outputs.size()) {
            let v = outputs.get(i)
            sources.add(v)
            rightMap.add(v, InterfacePort(i))
            for(wire in v.wires){
                match(GetBus(wire, buses)){
                    case Some(bus) => {}
                    case $None     => buses.add(wire.bus)
                }
            }
        }

        for(e in edges){
            for(i in 0..e.sources.size()){
                let v = e.sources.get(i)
                sources.add(v)
                rightMap.add(v, EdgePort(e,i))
                for(wire in v.wires){
                    match(GetBus(wire, buses)){
                        case Some(bus) => {}
                        case $None     => buses.add(wire.bus)
                    }
                }
            }
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

    func Clone(){
        let newSourceMapBuilder = MapBuilder<Source, Source>()
        let newTargetMapBuilder = MapBuilder<Target, Target>()
        for(v in sources){
            let v2 = Source(ArrayList<Wire>(v.wires)) 
            newSourceMapBuilder.add(v,v2)
        }
        for(v in targets){
            let v2 = Target()
            newTargetMapBuilder.add(v,v2)
        }
        let newInputs = ArrayList<Target>()
        let newOutputs = ArrayList<Source>()
        for(v in outputs){
            let v2 = Source(ArrayList<Wire>(v.wires))
            newSourceMapBuilder.add(v,v2)
            newOutputs.add(v2)
        }
        for(v in inputs){
            let v2 = Target()
            newTargetMapBuilder.add(v,v2)
            newInputs.add(v2)
        }
        let newSourceMap = newSourceMapBuilder.toMap()
        let newTargetMap = newTargetMapBuilder.toMap()

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

    operator func [](f : Hypergraph, n : Int64){
        Get(f,n)
    }
    operator func [](f : Hypergraph, s : String){
        Get(f,s)
    }

}

append Hypergraph with ToString {
    func toString(f : Hypergraph) : String {
        var str = ""
        let inputString = "inputs ${AtomListToString(f.GetInputs())}"
        for (e in f.GetEdges()) {
            let id = "e${e.id}"
            let gen = "${e.generator}"
            let sourceString = AtomListToString(e.sources)
            let targetString = AtomListToString(e.targets)
            str = "${str}${id} (${gen}) ${sourceString} ${targetString}\n"
        }
        let outputString = "outputs ${AtomListToString(f.GetOutputs())}"
        var connstr = "connections "
        for (t in f.GetTargets()) {
            connstr = "${connstr}(${t.id} ${f.GetConn(t).id}) "
        }
        "${f.GetName()}\n${inputString}\n${str}${outputString}\n${connstr}"
    }
}