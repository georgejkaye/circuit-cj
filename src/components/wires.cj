package components

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
    public func GetWidth() : Int64 {
        this.vertex.GetWidth()
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

public func Split(w : WireEnd, vs : Array<Int64>) : Array<WireEnd> {
    let v = w.GetVertex()
    if (v.GetWidth() != sum(vs)) {
        throw IncompatibleWidthException("Split", w, sum(vs))
    }
    let edge = Edge(BUNDLER([w.GetWidth()], vs), [v], vs)
    map({ v : Vertex => WireEnd(v) }, edge.GetTargets())
}

public func Combine(ws : Array<WireEnd>) : WireEnd {
    let widths = map({ w : WireEnd => w.GetWidth() }, ws)
    CombineGraphs(ws)
    let vertices = map({ w : WireEnd => w.GetVertex()}, ws )
    let edge = Edge(BUNDLER(widths, [sum(widths)]), vertices, [sum(widths)])
    WireEnd(edge.GetTarget(0))
}

public func GetBit(w : WireEnd, i : Int64) {
    let width = w.GetWidth()
    if (width < i) {
        throw IncompatibleWidthException("GetBit", w, i)
    }
    if (i == 0) {
        let ws = Split(w, [1, width - 1])    
        ws[0]
    } else if (i == width-1) {
        let ws = Split(w, [width - 1, 1])
        ws[1]
    } else {
        let ws = Split(w, [i, 1, width - i - 1])
        ws[1]
    }
}

public func Lsb(w : WireEnd) : WireEnd {
    LsbAndMsbs(w)[0]
}

public func Msbs(w : WireEnd) : WireEnd {
    LsbAndMsbs(w)[1]
}
public func Msb(w : WireEnd) : WireEnd {
    LsbsAndMsb(w)[1]
}
public func Lsbs(w : WireEnd) : WireEnd {
    LsbsAndMsb(w)[0]
}

public func LsbAndMsbs(w : WireEnd) : (WireEnd, WireEnd) {
    let splits = Split(w, [1, w.GetWidth() - 1])
    (splits[0], splits[1])
}
public func LsbsAndMsb(w : WireEnd) : (WireEnd, WireEnd) {
    let splits = Split(w, [w.GetWidth() - 1, 1])
    (splits[0], splits[1])
}

public func Copy(a : WireEnd, w : Int64) : WireEnd {
    Combine(Array<WireEnd>(w){ i : Int64 => a })
}