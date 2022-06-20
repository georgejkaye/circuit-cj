package graphs

public func MergeVertices(v : Vertex, w : Vertex) : (Vertex, Vertex) {
    
    let wInEdges = w.GetInEdges()
    let wOutEdges = w.GetOutEdges() 
    
    v.AddAllInEdges(w.GetInEdges())
    v.AddAllOutEdges(w.GetOutEdges())

    for ((e, i) in wInEdges) {
        e.SetTarget(i, v)
    }
    for ((e, i) in wOutEdges) {
        e.SetSource(i, v)
    }

    match(w.GetOwner()) {
        case None => ()
        case Some(g) => g.RemoveVertex(w)
    }
    (v, w)
}

public func Seq(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    if (f.GetOutputType() != g.GetInputType()){
        throw OutputInputMismatchException("Seq", f, g)
    }

    let (newF, newFInputs, newFOutputs) = f.Clone()
    let (newG, newGInputs, newGOutputs) = g.Clone()

    for (i in 0..f.GetOutputs()){
        MergeVertices(newFOutputs[i], newGInputs[i])
    }

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    gVertices.removeAll(newGInputs)

    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())

    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(newGraph, newFInputs, newGOutputs)
}

public func Par(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {

    let (newF, newFInputs, newFOutputs) = f.Clone()
    let (newG, newGInputs, newGOutputs) = g.Clone()

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())

    let newInputs = Array<Vertex>(f.GetInputs() + g.GetInputs()){
        i => if(i < newFInputs.size()) {
            newFInputs[i]
        } else {
            newGInputs[i - f.GetInputs()]
        }
    } 
    let newOutputs = Array<Vertex>(f.GetOutputs() + g.GetOutputs()){
        i => if(i < newFOutputs.size()) {
            newFOutputs[i]
        } else {
            newGOutputs[i - f.GetInputs()]
        }
    } 

    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(newGraph, newInputs, newOutputs)

}

public func Trace(f : InterfacedHypergraph, x : Int64) {
    if (x < 0) {
        throw NegativeTraceException("Trace", x)
    }
    if (f.GetInputs() < x) {
        throw NotEnoughInputsException("Trace", x, f)
    }
    if (f.GetOutputs() < x) {
        throw NotEnoughOutputsException("Trace", x, f)
    }
    let (newF, newFInputs, newFOutputs) = f.Clone()

    let newVertices = newF.GetVertices()
    let newEdges = newF.GetEdges()

    let newInputs = Array<Vertex>(f.GetInputs() - x) {
        i => newFInputs[i+x]
    }
    let newOutputs = Array<Vertex>(f.GetOutputs() - x) {
        i => newFOutputs[i+x]
    }

    for (i in 0..x) {
        // HACK .remove() might not return the right element
        let input = newFInputs[0]
        let output = newFOutputs[0]
        let (mergedVertex, removedVertex) = MergeVertices(input, output)
        for (j in 0..newInputs.size()) {
            if (newInputs[j] == removedVertex) {
                newInputs[j] = mergedVertex
            }
        }
        for (j in 0..newOutputs.size()) {
            if (newOutputs[j] == removedVertex) {
                newOutputs[j] = mergedVertex
            }
        }
        newVertices.removeIf({ v => v == removedVertex })
    }
    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(newGraph, newInputs, newOutputs)
}