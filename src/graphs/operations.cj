package graphs

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

    fold_left_n(
        { acc : Unit, cur : Vertex, i : Int64 => 
            let es = cur.GetOutEdges()
            fold_left(
                { acc : Unit, cur : (Edge, Int64) => 
                    let (e, j) = cur
                    e.RemoveAndSetSource(j, fOutputs[i])
                },
                (),
                es
            )
        },
        (),
        gInputs
    )

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