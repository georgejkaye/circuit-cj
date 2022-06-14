package components

/**
 * Merge two vertices together, such that any edges that had either vertex
 * as a source or target is updated with the merged vertex
 * @return A tuple (merged vertex, removed vertex)
 */
public func MergeVertices(v : WireEnd, w : WireEnd) : Unit {
    let vertex = w.GetVertex()
    v.GetVertex().AddAllInEdges(vertex.GetInEdges())
    v.GetVertex().AddAllOutEdges(vertex.GetOutEdges())
    w.SetVertex(v.GetVertex())
    match(vertex.GetOwner()) {
        case None => ()
        case Some(g) => g.RemoveVertex(vertex)
    }
}

public func CombineGraphs(ws : Array<WireEnd>) : Hypergraph {
    CombineGraphs(map({ w : WireEnd => w.GetVertex() }, ws))
}

public func WiresToVertices(ws : Array<WireEnd>) : Array<Vertex> {
    map({ w : WireEnd => w.GetVertex() }, ws)
}

public class WireEnd <: Identifiable & ToString {
    let id : Identifier = Identifier()
    var vertex : Vertex
    public init(v : Vertex) {
        this.vertex = v
    }
    public func GetVertex() : Vertex {
        this.vertex
    }
    public func SetVertex(v : Vertex) : Unit {
        match(this.vertex.GetOwner()) {
            case None => ()
            case Some(h) => 
                h.RemoveVertex(this.vertex)
                h.AddVertex(v)
        }
        for ((e, i) in this.vertex.GetInEdges()) {
            e.SetTarget(i, v)
        }
        for ((e, i) in this.vertex.GetOutEdges()) {
            e.SetSource(i, v)
        }
        this.vertex = v
    }
    public func GetId() : Int64 {
        this.id.GetId()
    }
    public func toString() : String {
        "wire ${this.id} (pointing at ${this.vertex})"
    }
}

public func Wire(width : Int64) : WireEnd {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    WireEnd(vertex)
}

public func Split(v : Vertex, l : Int64, r : Int64) : (Vertex, Vertex) {
    if (v.GetWidth() != l + r) {
        throw IncompatibleWidthException("Split", v, l, r)
    }
    let edge = Edge(DECOMPRESSOR(l, r), [v], [l, r])
    (edge.GetTarget(0), edge.GetTarget(1))
}

public func Combine(l : Vertex, r : Vertex) : Vertex {
    CombineGraphs([l, r])
    let edge = Edge(COMPRESSOR(l.GetWidth(), r.GetWidth()), [l, r], [l.GetWidth() + r.GetWidth()])
    edge.GetTarget(0)
}