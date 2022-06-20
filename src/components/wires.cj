package components

import graphs.*

public func Wire(width : Int64) : WireEnd {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    WireEnd(vertex)
}

public func Split(w : WireEnd, l : Int64, r : Int64) : (WireEnd, WireEnd) {
    let v = w.GetVertex()
    if (v.GetWidth() != l + r) {
        throw IncompatibleWidthException("Split", v, l, r)
    }
    let edge = Edge(DECOMPRESSOR(l, r), [v], [l, r])
    (WireEnd(edge.GetTarget(0)), WireEnd(edge.GetTarget(1)))
}

public func Combine(l : WireEnd, r : WireEnd) : WireEnd {
    let v = l.GetVertex()
    let w = r.GetVertex()
    CombineGraphs([l, r])
    let edge = Edge(COMPRESSOR(v.GetWidth(), w.GetWidth()), [v, w], [v.GetWidth() + w.GetWidth()])
    WireEnd(edge.GetTarget(0))
}

public func GetBit(w : WireEnd, i : Int64) {
    let width = w.GetVertex().GetWidth()
    if (width < i) {
        throw InsufficientWidthException("GetBit", w, i)
    }
    if (i == 0) {
        let (l, r) = Split(w, 1, width - 1)    
        l
    } else if (i == width-1) {
        let (l, r) = Split(w, width - 1, 1)
        r
    } else {
        let (l1, r1) = Split(w, i - 1, width - i + 1)
        let (l2, r2) = Split(r1, 1, width - i)
        l2
    }
}

public func Lsb(w : WireEnd) : WireEnd {
    let (l,r) = Split(w, 1, w.GetVertex().GetWidth() - 1)
    l
}

public func Msbs(w : WireEnd) : WireEnd {
    let (l,r) = Split(w, 1, w.GetVertex().GetWidth() - 1)
    r
}

public func LsbAndMsbs(w : WireEnd) : (WireEnd, WireEnd) {
    Split(w, 1, w.GetVertex().GetWidth() - 1)
}

