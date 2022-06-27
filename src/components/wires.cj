package components

public func MakeEdge(label : Label, sources : Array<Wire>, targets: Array<Int64>, graph : Option<InterfacedHypergraph>) : Array<Wire> {
    let edge = Edge(label, WiresToVertices(sources), targets, graph)
    map({v : Vertex => Wire(v) }, edge.GetTargets())
}

public func MakeEdge(label : Label, sources : Array<Int64>, targets: Array<Int64>, graph : InterfacedHypergraph) : Array<Wire> {
    MakeEdge(label, WidthsToWires(sources), targets, Some(graph))
}

public func MakeEdge(label : Label, sources : Array<Wire>, targets: Array<Int64>, graph : InterfacedHypergraph) : Array<Wire> {
    MakeEdge(label, sources, targets, Some(graph))
}

public func MakeEdge(label : Label, sources : Array<Wire>, targets: Array<Int64>) : Array<Wire> {
    MakeEdge(label, sources, targets, None)
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

public func WiresToVertices(ws : Array<Wire>) : Array<Vertex> {
    map({ w : Wire => w.GetVertex() }, ws)
}
public func WiresToWidths(ws : Array<Wire>) : Array<Int64> {
    map({ w : Wire => w.GetWidth() }, ws)
}
public func VerticesToWires(vs : Array<Vertex>) : Array<Wire> {
    map({ v : Vertex => Wire(v) }, vs)
}
public func WidthsToWires(vs : Array<Int64>) : Array<Wire> {
    map({ i : Int64 => Wire(Vertex(i)) }, vs)
}

public class Wire <: Identifiable & ToString {
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
        "w${this.id}"
    }
}

public func MakeWire(width : Int64) : Wire {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    Wire(vertex)
}

public func Split(w : Wire, vs : Array<Int64>) : Array<Wire> {
    let v = w.GetVertex()
    if (v.GetWidth() != sum(vs)) {
        throw IncompatibleWidthException("Split", w, sum(vs))
    }
    let edge = Edge(BUNDLER([w.GetWidth()], vs), [v], vs)
    map({ v : Vertex => Wire(v) }, edge.GetTargets())
}

public func Combine(ws : Array<Wire>) : Wire {
    let widths = map({ w : Wire => w.GetWidth() }, ws)
    CombineGraphs(ws)
    let vertices = map({ w : Wire => w.GetVertex()}, ws )
    let edge = Edge(BUNDLER(widths, [sum(widths)]), vertices, [sum(widths)])
    Wire(edge.GetTarget(0))
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

public func Copy(a : Wire, w : Int64) : Wire {
    Combine(Array<Wire>(w){ i : Int64 => a })
}