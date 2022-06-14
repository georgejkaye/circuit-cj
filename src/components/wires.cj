package components

public func MakeWire(width!: Int64 = 1) : Vertex {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    vertex
}

public func Split(v : Vertex, l : Int64, r : Int64) : (Vertex, Vertex) {
    if (v.GetWidth() != l + r) {
        throw IncompatibleWidthException("Split", v, l, r)
    }

    let left = Vertex(l)
    let right = Vertex(r)

    let edge = Edge(DECOMPRESSOR(l, r), [v], [left, right])
    let h = v.GetOwner().getOrThrow({ => NotOwnedException("Split", v)})

    h.AddEdge(edge)
    (left, right)
}

public func Combine(l : Vertex, r : Vertex) : Vertex {
    CombineGraphs([l, r])
    let v = Vertex(l.GetWidth() + r.GetWidth())
    let edge = Edge(COMPRESSOR(l.GetWidth(), r.GetWidth()), [l, r], [v])
    let h = l.GetOwner().getOrThrow({ => NotOwnedException("Combine", v)})
    h.AddEdge(edge)
    v   
}