/**
 * graphs/vertex.cj
 *
 * @author George Kaye
 * @since 0.2
 */ 

package graphs

/**
 * An EdgeConnection specifies an edge that a vertex
 * is a source or target of, and which index it is. 
 */
public record EdgeConnection <: ToString & Equatable<EdgeConnection> {
    public EdgeConnection(
        public let edge : Edge,
        public let index : Int64
    ){}
    public func toString() : String {
        "${edge}[${index}]"
    }
    public operator func ==(right: EdgeConnection) : Bool {
        this.edge == right.edge && this.index == right.index
    }
    public operator func !=(right : EdgeConnection) : Bool {
        !(this == right)
    }
}

/**
 * A vertex is a wire in a circuit. 
 * Vertices can be the source at most one edge, but the target of an
 * arbitrary number of edges, which represents forking wires.
 */
public class Vertex <: Identifiable &
                        Equatable<Vertex> & 
                        Ownable<Hypergraph> &
                        Hashable &
                        ToString &
                        HasWidth
{
    let width : Int64
    let id : Int64 = GetNextId()
    var inEdge : Option<EdgeConnection> = None
    var outEdges : ArrayList<EdgeConnection> = ArrayList()
    var feedback : Int64 = 0
    var owner : Option<Hypergraph> = None
    public init(width: Int64){ 
        this.width = width    
        this.owner = Some(Hypergraph(HashSet<Vertex>([this]), HashSet<Edge>()))
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
    public func GetOutEdges() : ArrayList<EdgeConnection> {
        this.outEdges
    }
    public func SetInEdge(e : Edge, i : Int64) : Unit {
        SetInEdge(EdgeConnection(e, i))
    }
    public func SetInEdge(ec : EdgeConnection) : Unit {
        inEdge = ec
    }
    public func AddOutEdge(e : Edge, i : Int64) : Unit {
        outEdges.add(EdgeConnection(e, i))
    }
    public func AddAllOutEdges(es : ArrayList<EdgeConnection>) {
        outEdges.addAll(es)
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
    public func GetOwner() : Option<Hypergraph> {
        this.owner
    }
    public func SetOwner(f : Hypergraph) : Unit {
        this.owner = Some(f)
    }
    public func RemoveOwner() : Unit {
        this.owner = None
    }
    public func hashCode() : Int64 {
        this.id
    }
}

public interface ContainsVertex {
    func GetVertex() : Vertex
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