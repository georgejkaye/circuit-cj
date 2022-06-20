package graphs

/**
 * Merge two vertices together, such that any edges that had either vertex
 * as a source or target is updated with the merged vertex
 * @return A tuple (merged vertex, removed vertex)
 */
public func MergeWires(v : WireEnd, w : WireEnd) : Unit {  
    MergeVertices(v.GetVertex(), w.GetVertex())
    w.SetVertex(v.GetVertex())
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