package graphs

func MergeVertices(v : Vertex, w : Vertex) : Unit {
    
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
}

public func Seq(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    if (f.GetOutputs() != g.GetInputs()){
        throw OutputInputMismatchException("Seq", f, g)
    }

    let (newF, newFInputs, newFOutputs) = CloneWithInterfaces(f)
    let (newG, newGInputs, newGOutputs) = CloneWithInterfaces(g)

    for (i in 0..f.GetOutputs()){
        MergeVertices(newFOutputs[i], newGInputs[i])
    }

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    gVertices.removeAll(newGInputs)

    let vertices = fVertices
    vertices.putAll(gVertices)
    let edges = newF.GetEdges()
    edges.putAll(newG.GetEdges())

    let newGraph = Hypergraph(vertices, edges)
    InterfacedHypergraph(newGraph, newFInputs, newGOutputs)
}

// public func Par(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {

//     let fVertices = f.GetVertices()
//     let gVertices = g.GetVertices()

//     let fInputs = f.GetInputVertices()
//     let fOutputs = f.GetOutputVertices()
//     let gInputs = g.GetInputVertices()
//     let gOutputs = g.GetOutputVertices()

//     let fEdges = f.GetEdges()
//     let gEdges = g.GetEdges()

//     fVertices.putAll(gVertices)
//     fEdges.putAll(gEdges)

//     fInputs.addAll(gInputs)
//     fOutputs.addAll(gOutputs)

//     InterfacedHypergraph(fVertices, fEdges, fInputs, fOutputs)

// }

// public func Trace(f : InterfacedHypergraph, x : Int64) {
//     if (x < 0) {
//         throw NegativeTraceException("Trace", x)
//     }
//     if (f.GetInputs() < x) {
//         throw NotEnoughInputsException("Trace", x, f)
//     }
//     if (f.GetOutputs() < x) {
//         throw NotEnoughOutputsException("Trace", x, f)
//     }
//     let fInputs = f.GetInputVertices()
//     let fEdges = f.GetEdges()
//     let fOutputs = f.GetOutputVertices()
//     let fVertices = f.GetVertices()
//     for (i in 0..x) {
//         // HACK .remove() might not return the right element
//         let input = fInputs[0]
//         fInputs.remove(0)
//         let output = fOutputs[0]
//         fOutputs.remove(0)
//         let (mergedVertex, removedVertex) = MergeVertices(input, output)
//         for (j in 0..fInputs.size()) {
//             if (fInputs[j] == removedVertex) {
//                 fInputs[j] = mergedVertex
//             }
//         }
//         for (j in 0..fOutputs.size()) {
//             if (fOutputs[j] == removedVertex) {
//                 fOutputs[j] = mergedVertex
//             }
//         }
//         fVertices.removeIf({ v => v == removedVertex })
//     }
//     InterfacedHypergraph(fVertices, fEdges, fInputs, fOutputs)
// }