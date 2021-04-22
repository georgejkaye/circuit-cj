// TODO package hypergraphs when I figure out how packages work
package hypergraph
import core.*
//import core.ArrayList

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
external class Source <: Vertex {
    private let name : String
    init() { this.name = ""}
    init(name: String) { this.name = name }
    override func ToString() { 
        let s2 = (name == "") ? "" : " - ${this.name}"
        return "Source s${this.id}${s2}"
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
external class Target <: Vertex {
    override func ToString() { "Target t${this.id}" }
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
external class Label <: Atom {
    let name : String
    let dom : UInt64
    let cod : UInt64
    init(name : String, dom : UInt64, cod : UInt64) {
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    func ToString() { "Label ${this.id} - ${this.name} : ${this.dom} → ${this.cod}" }
}

/**
 * A link spec contains information about a link
 * It has an id, a name, and a width 
 */
external class LinkSpec <: Atom {
    let name : String
    let width : UInt64
    init(name : String, width : UInt64) {
        this.name = name
        this.width = width
    }
    open func ToString() { "LinkSpec ${this.id} - ${this.name} width ${this.width}" }
}

enum LinkKind { IN | OUT }
/** Edges can be one of three kinds: Regular (a normal edge), Identity (a special edge with no label), or Link */
enum EdgeKind { REGULAR(Label) | IDENTITY | LINK(LinkSpec, LinkKind) }

/**
 * Edges are atoms
 */
external open class Edge <: Atom {
    let kind : EdgeKind
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(kind : EdgeKind, sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.kind = kind
        this.sources = sources
        this.targets = targets
    }
    open func ToString() { "Edge e${this.id}" }
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
external class RegularEdge <: Edge {
    private let label : Label
    init(label : Label, sources : ArrayList<Source>, targets : ArrayList<Target>) {
        super(REGULAR(label), sources, targets)
        this.label = label
    }
    override func ToString() { "Edge e${this.id} - ${this.label.name}" }
}

/**
 * Identity edges are introduced between links when we resolve them
 * They do not have labels
 */
class IdentityEdge <: Edge {
    init(sources : ArrayList<Source>, targets : ArrayList<Target>) {
        super(IDENTITY, sources, targets)
    }
    override func ToString() { "Edge e${this.id} - identity edge" }
}

/**
 * A link edge has no label, but it does have an associated link spec
 */
external open class LinkEdge <: Edge {
    let spec : LinkSpec
    init(kind : LinkKind, spec : LinkSpec, sources : ArrayList<Source>, targets : ArrayList<Target>){
        super(LINK(spec, kind), sources, targets)
        this.spec = spec
    }
    override open func ToString() { "Link e${this.id} - ${this.spec.name}" }
}

/**
 * In links
 */
external class InLinkEdge <: LinkEdge {
    init(spec : LinkSpec, sources : ArrayList<Source>){
        super(IN, spec, sources, ArrayList<Target>())
    }
    override func ToString() { "In link e${this.id} - ${this.spec.name}" }
}

/**
 * Out links
 */
external class OutLinkEdge <: LinkEdge {
    init(spec : LinkSpec, targets : ArrayList<Target>){
        super(OUT, spec, ArrayList<Source>(), targets)
    }
    override func ToString() { "Out link e${this.id} - ${this.spec.name}" }
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
external class Hypergraph {
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

    func ToString() {
        var str = ""
        let inputString = "inputs ${AtomListToString(inputs)}"
        for (e in edges) {
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
        let outputString = "outputs ${AtomListToString(outputs)}"
        var connstr = "connections "
        for ((t, s) in conns) {
            connstr = "${connstr}(${t.id} ${s.id}) "
        }
        "${inputString}\n${str}${outputString}\n${connstr}"
    }
}