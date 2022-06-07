package graphs

func MergeVertices(v : Vertex, w : Vertex) : Unit {
    func SetVertices(edges : ArrayList<(Edge , Int64)>, fn : (Edge, Vertex, Int64) -> Unit) : Unit {
        for (ei in edges) {
            let (e, i) = ei
            fn(e, v, i)
        }
    }
    SetVertices(w.GetInEdges(), { e , v, i => e.RemoveAndSetTarget(i, v)})
    SetVertices(w.GetOutEdges(), { e , v, i => e.RemoveAndSetSource(i, v)})
}

public func Seq(f : Hypergraph, g : Hypergraph) : Hypergraph {
    if (f.GetOutputs() != g.GetInputs()){
        throw OutputInputMismatchException("Seq", f, g)
    }

    f.Deactivate()
    g.Deactivate()

    let fVertices = f.GetVertices()
    let gVertices = g.GetVertices()

    let fInputs = f.GetInputVertices()
    let fOutputs = f.GetOutputVertices()
    let gInputs = g.GetInputVertices()
    let gOutputs = g.GetOutputVertices()

    for (i in 0..f.GetOutputs()){
        MergeVertices(fOutputs[i], gInputs[i])
    }

    gVertices.removeAll(g.GetInputVertices())

    let fEdges = f.GetEdges()
    let gEdges = g.GetEdges()

    fVertices.putAll(gVertices)
    fEdges.putAll(gEdges)

    Hypergraph(fVertices, fEdges, fInputs, gOutputs)
}

public func Par(f : Hypergraph, g : Hypergraph) : Hypergraph {
    f.Deactivate()
    g.Deactivate()

    let fVertices = f.GetVertices()
    let gVertices = g.GetVertices()

    let fInputs = f.GetInputVertices()
    let fOutputs = f.GetOutputVertices()
    let gInputs = g.GetInputVertices()
    let gOutputs = g.GetOutputVertices()

    let fEdges = f.GetEdges()
    let gEdges = g.GetEdges()

    fVertices.putAll(gVertices)
    fEdges.putAll(gEdges)

    fInputs.addAll(gInputs)
    fOutputs.addAll(gOutputs)

    Hypergraph(fVertices, fEdges, fInputs, fOutputs)

}

public func Trace(f : Hypergraph, x : Int64) {
    if (x < 0) {
        throw NegativeTraceException("Trace", x)
    }
    if (x < f.GetInputs()) {
        throw NotEnoughInputsException("Trace", x, f)
    }
    if (x < f.GetOutputs()) {
        throw NotEnoughOutputsException("Trace", x, f)
    }
    f.Deactivate()
    let fInputs = f.GetInputVertices()
    let fEdges = f.GetEdges()
    let fOutputs = f.GetOutputVertices()
    let fVertices = f.GetVertices()
    for (i in 0..x) {
        let input = fInputs.remove(0)
        let output = fOutputs.remove(0)
        MergeVertices(input, output)
        fVertices.removeIf({ v => v == output })
    }
    Hypergraph(fVertices, fEdges, fInputs, fOutputs)
}