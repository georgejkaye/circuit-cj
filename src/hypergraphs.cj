/* Ids for everything */
var id : UInt64 = 0
func genId() : UInt64 {
    let next = id
    id++
    return id
}

open class Vertex {
    protected let id : UInt64
    init() { this.id = genId() }
    open func ToString() { "Vertex v${this.id}" }
    operator func ==(lhs : Vertex, rhs : Vertex) { lhs.id == rhs.id }
    operator func <(lhs : Vertex, rhs : Vertex) { lhs.id < rhs.id }
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

class Label {
    private let id : UInt64
    private let name : String
    private let dom : UInt64
    private let cod : UInt64
    init(name : String, dom : UInt64, cod : UInt64) {
        this.id = genId()
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    func ToString() { return "Label ${this.id} - ${this.name} : ${this.dom} → ${this.cod}" }
    func GetName() { return name }
}

open class Edge {
    protected let id : UInt64
    init() { this.id = genId() }
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

func main(){
    let and = Label("AND", 2, 1)
    let e1 = RegularEdge(and)
    print(e1.ToString() + "\n")
    let s1 = Source()
    let s2 = Source("foo")
    print(s1.ToString() + "\n")
    print(s2.ToString() + "\n")
    return 0
}