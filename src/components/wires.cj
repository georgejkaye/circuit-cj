package components

public class Wire <: Identifiable & ToString & ContainsVertex & HasWidth {
    let id : Identifier = Identifier()
    var vertex : Vertex
    public init(v : Vertex) {
        this.vertex = v
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
        "w${this.id}"
    }
    public func GetVertex() : Vertex {
        this.vertex
    }
}

public interface ContainsWire <: HasWidth {
    func GetWire() : Wire
}

extend Wire <: ContainsWire {
    public func GetWire() : Wire {
        this
    }
}

public func MakeWire(width : Int64) : Wire {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    Wire(vertex)
}

public record NamedWire <: ContainsWire & ToString & ContainsVertex {
    public NamedWire(
        let wire : Wire,
        let name : Option<String>
    ){}
    public func GetWire() : Wire {
        this.wire
    }
    public func GetVertex() : Vertex {
        this.wire.GetVertex()
    }
    public func toString() : String {
        "${this.wire} (${name})"
    }
    public func GetWidth() : Int64 {
        this.wire.GetWidth()
    }
}


public func MakeEdge<T,U>(
    label : Label,
    sources : Array<T>,
    targets: Array<U>,
    graph : Option<InterfacedHypergraph>
) : Array<Wire> where T <: ContainsVertex, U <: ContainsVertex {
    let sources = map({ t : T => t.GetVertex() }, sources)
    let targets = map({ u : U => u.GetVertex() }, targets)
    let edge = Edge(label, sources, targets, graph)
    map({v : Vertex => Wire(v) }, edge.GetTargets())
}

/**
 * Merge two vertices together, such that any edges that had either vertex
 * as a source or target is updated with the merged vertex
 * @return A tuple (merged vertex, removed vertex)
 */
public func MergeWires(v : Wire, w : Wire) : Unit {  
    MergeVertices(v.GetVertex(), w.GetVertex())
    w.SetVertex(v.GetVertex())
}

public func CombineGraphs(ws : Array<Wire>) : Hypergraph {
    CombineGraphs(map({ w : Wire => w.GetVertex() }, ws))
}

public func WiresToWidths(ws : Array<Wire>) : Array<Int64> {
    map({ w : Wire => w.GetWidth() }, ws)
}

public func Split(w : Wire, vs : Array<Int64>) : Array<Wire> {
    AssertWireWidth(w, sum(vs))
    MakeEdge(
        BUNDLER([w.GetWidth()], vs),
        [w],
        vs,
        None
    )
}

public func Split(w : Wire, l : Int64, r : Int64) : (Wire, Wire) {
    let split = Split(w, [l, r])
    (split[0], split[1])
}

public func Split(w : Wire) : Array<Wire> {
    Split(w, Array<Int64>(w.GetWidth()){ i : Int64 => 1})
}

public func Combine(ws : Array<Wire>) : Wire {
    let widths = map({ w : Wire => w.GetWidth() }, ws)
    CombineGraphs(ws)
    MakeEdge(
        BUNDLER(widths, [sum(widths)]),
        ws,
        [sum(widths)],
        None
    )[0]
}
public func Combine(lhs : Wire, rhs : Wire) : Wire {
    Combine([lhs, rhs])
}

public func GetBit(w : Wire, i : Int64) {
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

public func Lsb(w : Wire) : Wire {
    LsbAndMsbs(w)[0]
}

public func Msbs(w : Wire) : Wire {
    LsbAndMsbs(w)[1]
}
public func Msb(w : Wire) : Wire {
    LsbsAndMsb(w)[1]
}
public func Lsbs(w : Wire) : Wire {
    LsbsAndMsb(w)[0]
}

public func LsbAndMsbs(w : Wire) : (Wire, Wire) {
    let splits = Split(w, [1, w.GetWidth() - 1])
    (splits[0], splits[1])
}
public func LsbsAndMsb(w : Wire) : (Wire, Wire) {
    let splits = Split(w, [w.GetWidth() - 1, 1])
    (splits[0], splits[1])
}

public func Replicate(a : Wire, w : Int64) : Wire {
    Combine(Array<Wire>(w){ i : Int64 => a })
}