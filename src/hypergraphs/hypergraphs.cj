package hypergraphs

/* Ids for everything */
var id : UInt64 = 0
func genId() : UInt64 {
    let next = id
    id++
    return id
}

/* Base atom class, every element of a hypergraph (vertex, edge, label) is an atom */
open class Atom {
    let id : UInt64
    init() { this.id = genId() }
}

/* Vertices */
open class Vertex <: Atom {
    open func ToString() { "Vertex v${this.id}" }
}
class Source <: Vertex {
    private let name : String
    init() { this.name = ""}
    init(name: String) { this.name = name }
    override func ToString() { 
        let s2 = name == "" ? "" : " - ${this.name}"
        return "Source s${this.id}${s2}"
    }
}
class Target <: Vertex {
    override func ToString() { return "Target t${this.id}" }
}

/* Labels */
class Label <: Atom {
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

/* Edges */
open class Edge <: Atom {
    open func ToString() { return "Edge e${this.id}" }
}
class RegularEdge <: Edge {
    private let label : Label
    init(label : Label) {
        this.label = label
    }
    override func ToString() { return "Edge e${this.id} - ${this.label.GetName()}" }
}
class IdentityEdge <: Edge {
    override func ToString() { return "Edge e${this.id} - identity edge" }
}
class LinkSpec {
    private let id : UInt64
    private let name : String
    private let width : UInt64
    init(name : String, width : UInt64) {
        this.id = genId()
        this.name = name
        this.width = width
    }
    open func ToString() { return "LinkSpec ${this.id} - ${this.name} width ${this.width}" }
    func GetName() { return name }
}

class LinkEdge <: Edge {
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
    func hashCode(t : Target) : UInt64 { id }
}
append Edge with Hashable, Equatable {
    operator func ==(lhs : Edge, rhs : Edge) : Bool { lhs.id == rhs.id }
    operator func !=(lhs : Edge, rhs : Edge) : Bool { lhs.id != rhs.id }
    func hashCode(t : Edge) : UInt64 { id }
}

/* Hypergraph */
class Hypergraph {
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
    print("Beginning the test\n")
    let and = Label("AND", 2, 1)
    let e1 = RegularEdge(and)
    print(e1.ToString() + "\n")
    let s1 = Source()
    let s2 = Source("foo")
    print(s1.ToString() + "\n")
    print(s2.ToString() + "\n")
    return 0
}

external func Hello (){ print("Hello!") }