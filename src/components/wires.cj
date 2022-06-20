package components

import graphs.*

public func Wire(width : Int64) : WireEnd {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    WireEnd(vertex)
}

public func Split(w : WireEnd, vs : Array<Int64>) : Array<WireEnd> {
    let v = w.GetVertex()
    if (v.GetWidth() != sum(vs)) {
        throw IncompatibleWidthException("Split", v, vs)
    }
    let edge = Edge(BUNDLER([w.GetVertex().GetWidth()], vs), [v], vs)
    map({ v : Vertex => WireEnd(v) }, edge.GetTargets())
}

public func Combine(ws : Array<WireEnd>) : WireEnd {
    let widths = map({ w : WireEnd => w.GetVertex().GetWidth() }, ws)
    CombineGraphs(ws)
    let vertices = map({ w : WireEnd => w.GetVertex()}, ws )
    let edge = Edge(BUNDLER(widths, [sum(widths)]), vertices, [sum(widths)])
    WireEnd(edge.GetTarget(0))
}

public func GetBit(w : WireEnd, i : Int64) {
    let width = w.GetVertex().GetWidth()
    if (width < i) {
        throw InsufficientWidthException("GetBit", w, i)
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

public func LsbAndMsbs(w : WireEnd) : (WireEnd, WireEnd) {
    let splits = Split(w, [1, w.GetVertex().GetWidth() - 1])
    (splits[0], splits[1])
}

