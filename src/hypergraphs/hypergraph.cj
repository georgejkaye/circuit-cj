package hypergraph

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
        let s2 = name == "" ? "" : " - ${this.name}"
        return "Source s${this.id}${s2}"
    }
}

/**
 * Target vertices are inwards facing ports: they are the targets of edges.
 * Target vertices currently don't have anything particularly special about them
 */
external class Target <: Vertex {
    override func ToString() { return "Target t${this.id}" }
}

/**
 * Labels have a name, domain and codomain
 */
external class Label <: Atom {
    private let name : String
    private let dom : UInt64
    private let cod : UInt64
    init(name : String, dom : UInt64, cod : UInt64) {
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    func ToString() { return "Label ${this.id} - ${this.name} : ${this.dom} → ${this.cod}" }
    func GetName() { return name }
}

/**
 * Edges are atoms
 */
open class Edge <: Atom {
    open func ToString() { return "Edge e${this.id}" }
}

/**
 * Most edges are 'regular edges': they have a label
 */
external class RegularEdge <: Edge {
    private let label : Label
    init(label : Label) {
        this.label = label
    }
    override func ToString() { return "Edge e${this.id} - ${this.label.GetName()}" }
}
/**
 * Identity edges are introduced between links when we resolve them
 * They do not have labels
 */
class IdentityEdge <: Edge {
    override func ToString() { return "Edge e${this.id} - identity edge" }
}
/**
 * A link spec contains information about a link
 * It has an id, a name, and a width 
 */
external class LinkSpec <: Atom {
    private let name : String
    private let width : UInt64
    init(name : String, width : UInt64) {
        this.name = name
        this.width = width
    }
    open func ToString() { return "LinkSpec ${this.id} - ${this.name} width ${this.width}" }
    func GetName() { return name }
}
/**
 * A link edge has no label, but it does have an associated link spec
 */
external class LinkEdge <: Edge {
    private let spec : LinkSpec
    init(spec : LinkSpec){
        this.spec = spec
    }
    override func ToString() { return "Link e${this.id} - ${this.spec.GetName()}" }
}

// TODO: Can these not be done just for atom?
// It currently doesn't compile
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

/* Hypergraph */
external class Hypergraph {
    private let sourceVertices : List<Source>
    private let targetVertices : List<Target>
    private let conns          : Map<Target, Source>
    private let edges          : List<Edge>
    private let sources        : Map<Edge, List<Source>>
    private let targets        : Map<Edge, List<Target>>
    init(sourceVertices : List<Source>, 
         targetVertices : List<Target>, 
         conns          : Map<Target, Source>,
         edges          : List<Edge>, 
         sources        : Map<Edge, List<Source>>, 
         targets        : Map<Edge, List<Target>>
    ){
        this.sourceVertices = sourceVertices
        this.targetVertices = targetVertices
        this.conns = conns
        this.edges = edges
        this.sources = sources
        this.targets = targets
    }
}

external func Test() {
    return 0
}