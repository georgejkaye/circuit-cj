package components

import graphs.*

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