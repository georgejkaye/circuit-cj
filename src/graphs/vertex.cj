/**
 * graphs/vertex.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

public enum VertexType {
    | SOURCE
    | TARGET
}
extend VertexType <: ToString {
    public func toString() : String {
        match(this) {
            case SOURCE => "source"
            case TARGET => "target"
        }
    }
}

/**
 * An EdgeConnection specifies an edge that a vertex
 * is a source or target of, and which index it is.
 */
public struct EdgeConnection <: ToString & Equatable<EdgeConnection> & Hashable {
    public EdgeConnection(
        public let edge : Edge,
        public let index : Int64,
        public let vertexType : VertexType
    ) {}
    public func toString() : String {
        let initial = match(this.vertexType) {
            case SOURCE => "s"
            case TARGET => "t"
        }
        "${edge}.${initial}${index}"
    }
    public operator func ==(right: EdgeConnection) : Bool {
        this.edge == right.edge && this.index == right.index
    }
    public operator func !=(right : EdgeConnection) : Bool {
        !(this == right)
    }
    // HACK: This won't be unique if you have something with more than
    // 100000 sources or targets
    public func hashCode() : Int64 {
        let code = edge.GetId() * 100000 + index
        match(vertexType) {
            case SOURCE => code
            case TARGET => -code
        }
    }
    public func GetWidth() : Int64 {
        let t = match(vertexType) {
            case SOURCE => edge.GetSource(index)
            case TARGET => edge.GetTarget(index)
        }
        t.GetWidth()
    }
}

/**
 * A vertex is a wire in a circuit.
 * Vertices can be the source at most one edge, but the target of an
 * arbitrary number of edges, which represents forking wires.
 */
public class Vertex <: Identifiable &
                        Equatable<Vertex> &
                        Hashable &
                        ToString &
                        HasWidth &
                        Socket
{
    let width : Int64
    let id : Int64 = GetNextId()
    var inEdge : Option<EdgeConnection> = None
    var outEdges : HashSet<EdgeConnection> = HashSet<EdgeConnection>()
    var feedback : Int64 = 0
    var owner : Hypergraph = Hypergraph()
    public init(width: Int64){
        this.width = width
        this.owner.AddVertex(this)
    }
    public init() {
        this(1)
    }
    public func GetId() : Int64 {
        this.id
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetInEdge() : Option<EdgeConnection> {
        this.inEdge
    }
    public func GetOutEdges() : HashSet<EdgeConnection> {
        this.outEdges
    }
    public func SetInEdge(e : Edge, i : Int64) : Unit {
        SetInEdge(EdgeConnection(e, i, TARGET))
    }
    public func SetInEdge(ec : EdgeConnection) : Unit {
        inEdge = ec
    }
    public func RemoveInEdge(e : Edge) : Unit {
        match(this.inEdge) {
            case None => ()
            case Some(ec) =>
                if (ec.edge == e) {
                    this.inEdge = None
                }
        }
    }
    public func RemoveOutEdge(e : Edge) : Unit {
        this.outEdges.removeIf({ec : EdgeConnection => ec.edge == e})
    }
    public func AddOutEdge(e : Edge, i : Int64) : Unit {
        outEdges.put(EdgeConnection(e, i, SOURCE))
    }
    public func AddAllOutEdges(es : HashSet<EdgeConnection>) {
        outEdges.putAll(es)
    }
    func IncrementFeedback() : Unit {
        this.feedback++
    }
    func DecrementFeedback() : Unit {
        this.feedback--
    }
    public func toString() : String {
        "v${this.GetId()}"
    }
    public operator func ==(right: Vertex) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Vertex) : Bool {
        this.GetId() != right.GetId()
    }
    public func GetOwner() : Hypergraph {
        this.owner
    }
    public func SetOwner(f : Hypergraph) : Unit {
        this.owner = f
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetName() : Option<String> {
        None
    }
}

public interface ContainsVertex {
    func GetVertex() : Vertex
}
extend Vertex <: ContainsVertex {
    public func GetVertex() : Vertex {
        this
    }
}
extend Int64 <: ContainsVertex {
    public func GetVertex() : Vertex {
        Vertex(this)
    }
}
extend Port <: ContainsVertex {
    public func GetVertex() : Vertex {
        Vertex(this.width)
    }
}