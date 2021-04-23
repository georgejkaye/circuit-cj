package hypergraphs
import core.*

class VertexNotInGraphException <: Exception {
    init(v : Vertex){
        print("Exception ${v.id}")
    }
}

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
    let names : ArrayList<String>
    init() { this.names = ArrayList<String>()}
    init(name: String) { this.names = ArrayList<String>([name]) }
    init(names: ArrayList<String>) { this.names = names }
    func AddName(name : String) { this.names.add(name) }
    func AddNames(names : ArrayList<String>) { this.names.addAll(names) }
}
append Source with ToString {
    func toString(s : Source) {
        var names = ""
        for (name in s.names){
            names = name == "" ? "${name}" : "${names}, ${name}"
        }
        return "Source s${s.id} ${names}" 
    }
}
// TODO should be redundant if inheritance works
func AtomListToString(xs : ArrayList<Source>){ 
    var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
        var names = ""
        for(name in x.names){
            names = names == "" ? " (${name}" : "${names}, ${name}"
        }
        names = names == "" ? "" : "${names})"
        str = "${str}${names}"
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
 * Labels have a name, domain and codomain
 */
class Label <: Atom {
    let name : String
    let dom : Int64
    let cod : Int64
    init(name : String, dom : Int64, cod : Int64) {
        this.name = name
        this.dom = dom
        this.cod = cod
    }
}
append Label with ToString {
    func toString(l : Label) { "Label ${l.id} - ${l.name} : ${l.dom} → ${l.cod}" }
}

/**
 * A link spec contains information about a link
 * It has an id, a name, and a width 
 */
class LinkSpec <: Atom {
    let name : String
    let width : Int64
    init(name : String, width : Int64) {
        this.name = name
        this.width = width
    }
}
append LinkSpec with ToString {
    func toString(spec : LinkSpec) { "LinkSpec ${spec.id} - ${spec.name} width ${spec.width}" }
}

enum LinkKind { IN | OUT }
/** Edges can be one of three kinds: Regular (a normal edge), Identity (a special edge with no label), or Link */
enum EdgeKind { REGULAR(Label) | IDENTITY | LINK(LinkSpec, LinkKind) }

/**
 * Edges are atoms
 */
open class Edge <: Atom {
    let kind : EdgeKind
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(kind : EdgeKind, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.kind = kind
        this.sources = sources
        this.targets = targets
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

/**
 * Most edges are 'regular edges': they have a label
 */
class RegularEdge <: Edge {
    let label : Label
    init(label : Label, sources : ArrayList<Source>, targets : ArrayList<Target>) {
        super(REGULAR(label), sources, targets)
        this.label = label
    }
}
append RegularEdge with ToString {
    func toString(e : RegularEdge) { "Edge e${e.id} - ${e.label.name}" }
}

/**
 * Identity edges are introduced between links when we resolve them
 * They do not have labels
 */
class IdentityEdge <: Edge {
    init(sources : ArrayList<Source>, targets : ArrayList<Target>) {
        super(IDENTITY, sources, targets)
    }
}
append IdentityEdge with ToString {
    func toString(e : IdentityEdge) { "Identity e${e.id}" }
}

/**
 * A link edge has no label, but it does have an associated link spec
 */
open class LinkEdge <: Edge {
    let spec : LinkSpec
    init(kind : LinkKind, spec : LinkSpec, sources : ArrayList<Source>, targets : ArrayList<Target>){
        super(LINK(spec, kind), sources, targets)
        this.spec = spec
    }
}

/**
 * In links
 */
class InLinkEdge <: LinkEdge {
    init(spec : LinkSpec, sources : ArrayList<Source>){
        super(IN, spec, sources, ArrayList<Target>())
    }
}
append InLinkEdge with ToString {
    func toString(e : InLinkEdge) { "Inlink e${e.id} - ${e.spec.name}" }
}

/**
 * Out links
 */
class OutLinkEdge <: LinkEdge {
    init(spec : LinkSpec, targets : ArrayList<Target>){
        super(OUT, spec, ArrayList<Source>(), targets)
    }
}
append OutLinkEdge with ToString {
    func toString(e : OutLinkEdge) { "Outlink e${e.id} - ${e.spec.name}" }
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
class Hypergraph {
    private let edges   : ArrayList<Edge>
    private let inputs  : ArrayList<Target>
    private let outputs : ArrayList<Source>
    private let conns   : Map<Target, Source>

    // TODO should be sets but I don't know how to make them dynamically
    private let sources : ArrayList<Source>
    private let targets : ArrayList<Target>
    private let lefts : Map<Target, Port>
    private let rights : Map<Source, Port>

    init(edges    : ArrayList<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : Map<Target, Source>
    ){
        this.edges    = edges
        this.inputs   = inputs
        this.outputs  = outputs
        this.conns    = conns

        let leftMap = MapBuilder<Target, Port>()
        let rightMap = MapBuilder<Source, Port>()
        this.sources = ArrayList<Source>()
        this.targets = ArrayList<Target>()

        for(i in 0..inputs.size()){
            targets.add(inputs.get(i))
            leftMap.add(inputs.get(i), InterfacePort(i))
        }
        for(i in 0..outputs.size()) {
            sources.add(outputs.get(i))
            rightMap.add(outputs.get(i), InterfacePort(i))
        }

        for(e in edges){
            for(i in 0..e.sources.size()){
                let v = e.sources.get(i)
                sources.add(v)
                rightMap.add(v, EdgePort(e,i))
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

    func GetEdges() { edges }
    func GetInputs() { inputs }
    func GetOutputs() { outputs }
    func GetConns() { conns }

    func GetSources() { sources }
    func GetTargets() { targets }

    func GetConn(t : Target) {
        match(conns.get(t)){
            case .None => throw VertexNotInGraphException(t)
            case .Some(s) => s
        }
    }
    func GetEdge(s : Source) { 
        match(rights.get(s)){
            case .None => throw VertexNotInGraphException(s)
            case .Some(p) => p 
        }
    }
    func GetEdge(t : Target) { 
        match(lefts.get(t)){
            case .None => throw VertexNotInGraphException(t)
            case .Some(p) => p
        }
    }

    func Clone(){
        let newSourceMapBuilder = MapBuilder<Source, Source>()
        let newTargetMapBuilder = MapBuilder<Target, Target>()
        for(v in sources){
            let v2 = Source(ArrayList<String>(v.names)) 
            newSourceMapBuilder.add(v,v2)
        }
        for(v in targets){
            let v2 = Target()
            newTargetMapBuilder.add(v,v2)
        }
        let newInputs = ArrayList<Target>()
        let newOutputs = ArrayList<Source>()
        for(v in outputs){
            let v2 = Source(ArrayList<String>(v.names))
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
                    case .Some(v2) => v2
                    case .None     => throw VertexNotInGraphException(v)
                }
                s2.add(v2)
            }
            for (v in t){
                let v2 = match(newTargetMap.get(v)){
                    case .Some(v2) => v2
                    case .None     => throw VertexNotInGraphException(v)
                }
                t2.add(v2)
            }
            let e2 = Edge(e.kind, s2, t2)
            newEdges.add(e2)
        }

        let newConnsBuilder = MapBuilder<Target, Source>()
        for(v in targets){
            let newT = match(newTargetMap.get(v)){
                    case .Some(v2) => v2
                    case .None     => throw VertexNotInGraphException(v)
            }
            let newS = match(newSourceMap.get(GetConn(v))){
                    case .Some(v2) => v2
                    case .None     => throw VertexNotInGraphException(GetConn(v))
            }
            newConnsBuilder.add(newT, newS)
        }
        let newConns = newConnsBuilder.toMap()
        Hypergraph(newEdges, newInputs, newOutputs, newConns)
    }

}

append Hypergraph with ToString {
    func toString(f : Hypergraph) : String {
        var str = ""
        let inputString = "inputs ${AtomListToString(f.GetInputs())}"
        for (e in f.GetEdges()) {
            let id = "e${e.id}"
            let label = match (e.kind) {
                case .REGULAR(label)   => label.name
                case .IDENTITY         => "id"
                case .LINK(spec, kind) => {
                    match (kind) {
                        case. IN  => "inlink ${spec.name}"
                        case. OUT => "outlink ${spec.name}"
                    }
                }
            }
            let sourceString = AtomListToString(e.sources)
            let targetString = AtomListToString(e.targets)
            str = "${str}${id} (${label}) ${sourceString} ${targetString}\n"
        }
        let outputString = "outputs ${AtomListToString(f.GetOutputs())}"
        var connstr = "connections "
        for (t in f.GetTargets()) {
            connstr = "${connstr}(${t.id} ${f.GetConn(t).id}) "
        }
        "${inputString}\n${str}${outputString}\n${connstr}"
    }
}