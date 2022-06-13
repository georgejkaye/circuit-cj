package graphs

/**
 * Merge two vertices together, such that any edges that had either vertex
 * as a source or target is updated with the merged vertex
 * @return A tuple (merged vertex, removed vertex)
 */
func MergeVertices(v : Vertex, w : Vertex) : (Vertex, Vertex) {
    func SetVertices(edges : ArrayList<(Edge , Int64)>, fn : (Edge, Vertex, Int64) -> Unit) : Unit {
        for (ei in edges) {
            let (e, i) = ei
            fn(e, v, i)
        }
    }
    SetVertices(w.GetInEdges(), { e , v, i => e.RemoveAndSetTarget(i, v)})
    SetVertices(w.GetOutEdges(), { e , v, i => e.RemoveAndSetSource(i, v)})
    (v, w)
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
    if (f.GetInputs() < x) {
        throw NotEnoughInputsException("Trace", x, f)
    }
    if (f.GetOutputs() < x) {
        throw NotEnoughOutputsException("Trace", x, f)
    }
    f.Deactivate()
    let fInputs = f.GetInputVertices()
    let fEdges = f.GetEdges()
    let fOutputs = f.GetOutputVertices()
    let fVertices = f.GetVertices()
    for (i in 0..x) {
        // HACK .remove() might not return the right element
        let input = fInputs[0]
        fInputs.remove(0)
        let output = fOutputs[0]
        fOutputs.remove(0)
        let (mergedVertex, removedVertex) = MergeVertices(input, output)
        for (j in 0..fInputs.size()) {
            if (fInputs[j] == removedVertex) {
                fInputs[j] = mergedVertex
            }
        }
        for (j in 0..fOutputs.size()) {
            if (fOutputs[j] == removedVertex) {
                fOutputs[j] = mergedVertex
            }
        }
        fVertices.removeIf({ v => v == removedVertex })
    }
    Hypergraph(fVertices, fEdges, fInputs, fOutputs)
}