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

/**
 * Target vertices are inwards facing ports: they are the targets of edges.
 * Target vertices currently don't have anything particularly special about them
 */
external class Target <: Vertex {
    override func ToString() { "Target t${this.id}" }
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
    func GetName() { name }
}

/**
 * Edges are atoms
 */
external open class Edge <: Atom {
    let sources : ArrayList<Source>
    let targets : ArrayList<Target>
    init(sources : ArrayList<Source>, targets : ArrayList<Target>){
        this.sources = sources
        this.targets = targets
    }
    open func ToString() { "Edge e${this.id}" }
}
/**
 * Most edges are 'regular edges': they have a label
 */
external class RegularEdge <: Edge {
    private let label : Label
    init(label : Label, sources : ArrayList<Source>, targets : ArrayList<Target>) {
        super(sources, targets)
        this.label = label
    }
    override func ToString() { "Edge e${this.id} - ${this.label.GetName()}" }
}
/**
 * Identity edges are introduced between links when we resolve them
 * They do not have labels
 */
class IdentityEdge <: Edge {
    init(sources : ArrayList<Source>, targets : ArrayList<Target>) {
        super(sources, targets)
    }
    override func ToString() { "Edge e${this.id} - identity edge" }
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
    open func ToString() { "LinkSpec ${this.id} - ${this.name} width ${this.width}" }
    func GetName() { name }
}
/**
 * A link edge has no label, but it does have an associated link spec
 */
external class LinkEdge <: Edge {
    private let spec : LinkSpec
    init(spec : LinkSpec, sources : ArrayList<Source>, targets : ArrayList<Target>){
        super(sources, targets)
        this.spec = spec
    }
    override func ToString() { "Link e${this.id} - ${this.spec.GetName()}" }
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

/* Hypergraph */
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
        var s = ""
        for (e in edges) {
            s = "${s} ${e.id} ("
            match (e) {
                case .RegularEdge => e.label.name
                case .IdentityEdge => "id"
                case .LinkEdge => "link ${e.spec.name}"
            }
            s = "${s} ${lab}"
            s = "${s} ${e.id} (${e.label.name}) : ("
            for (v in e.sources) {
                s = "${s} ${v.id}"
            }
            s = "${s} ) ("
            for (v in e.targets) {
                s = "${s} ${v.id}"
            }
            s = "S{s} )"
        }
        s
    }
}

// TODO I want everything in separate files, because that is how neat code is done
// But I haven't figured out how to use packages yet
// And using Maps for classes defined in this file causes segfaults for some reason
// Eventually I'll spread everything into its own file

/*************************************************************************************************************************
 * Components                                                                                                            *
 **************************************************************************************************************************/

class BadOutputPortsException <: Exception {}
class BadDomainException <: Exception {}
class BadCodomainException <: Exception {}

func OpMToN(m : UInt64, n : UInt64, label : Label, ports : ArrayList<String>){

    if(m != label.dom){
        throw BadDomainException()
    }
    if(n != label.cod){
        throw BadCodomainException()
    }

    //print("${outputs.size()}")

    //if(outputs.size() != n){
    //    throw BadOutputPortsException()
   // }

    let inputs = ArrayList<Target>(Int64(m), {x => Target()})
    let sources = ArrayList<Source>(Int64(m), {x => Source()})
    let targets = ArrayList<Target>(Int64(n), {x => Target()})
    let outputs = ArrayList<Source>(Int64(n), {x => Source(ports.get(x))})

    let op = RegularEdge(label, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i : Int64 in 0..m) {
        print("${sources.get(i).ToString()}\n")
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i : Int64 in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }

    let graph = Hypergraph(#{op}, inputs, outputs, conns.toMap())
    //print(graph.ToString())
}
//func OpMToN(m : UInt64, n : UInt64, label : Label){ OpMToN(m,n,label,ArrayList<String>(n,"")) }

func AndGate(out : String) { OpMToN(2,1,Label("AND", 2, 1),ArrayList<String>([out])) }

external func Test() {
    AndGate("out")
    return 0
}