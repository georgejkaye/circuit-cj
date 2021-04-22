package hypergraphs
import core.*

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
    let name : String
    init() { this.name = ""}
    init(name: String) { this.name = name }
}
append Source with ToString {
    func toString(s : Source) {
        let s2 = (s.name == "") ? "" : " - ${s.name}"
        return "Source s${s.id}${s2}" 
    }
}
// TODO should be redundant if inheritance works
func AtomListToString(xs : ArrayList<Source>){ 
        var str = "["
    for (x in xs) {
        str = "${str} ${x.id}"
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

/**
 * Hypergraph
 */
class Hypergraph {
    private let edges   : Set<Edge>
    private let inputs  : ArrayList<Target>
    private let outputs : ArrayList<Source>
    private let conns   : Map<Target, Source>

    init(edges    : Set<Edge>, 
         inputs   : ArrayList<Target>,
         outputs  : ArrayList<Source>,
         conns    : Map<Target, Source>
    ){
        this.edges    = edges
        this.inputs   = inputs
        this.outputs  = outputs
        this.conns    = conns
    }

    func GetEdges() { edges }
    func GetInputs() { inputs }
    func GetOutputs() { outputs }
    func GetConns() { conns }
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
        for ((t, s) in f.GetConns()) {
            connstr = "${connstr}(${t.id} ${s.id}) "
        }
        "${inputString}\n${str}${outputString}\n${connstr}"
    }
}