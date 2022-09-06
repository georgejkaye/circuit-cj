/**
 * graphs/operations.cj
 *
 * Operations on interfaced hypergraphs
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

/**
 * Merge two vertices v and w such that v has the in/out-edges of w.
 * Updates the corresponding edges appropriately; w will be orphaned
 * after this operation. If both v and w already have an in edge, throws
 * an exception: we do not permit vertices to have multiple in edges
 *
 * @param v The primary vertex to merge into
 * @param w The secondary vertex that will be merged
 * @return A pair (new,old) of the merged vertex and the old vertex
 */
public func MergeVertices<T, U>(t : T, u : U, feedback: Bool) : (Vertex, Vertex) where T <: ContainsVertex, U <: ContainsVertex {
    let inEdge = AssertAtMostOneInEdge(t, u)
    let v = t.GetVertex()
    let w = u.GetVertex()
    match (inEdge) {
        case None => ()
        case Some(ec) =>
            ec.edge.SetTarget(ec.index, v)
    }
    let wOutEdges = w.GetOutEdges()
    // Clone the collection since we'll be removing vertices from the set
    let outEdges = Array<EdgeConnection>(wOutEdges)
    for (ec in outEdges) {
       ec.edge.SetSource(ec.index, v, feedback)
    }
    // Make sure the old vertex isn't part of a hypergraph any more
    w.GetOwner().RemoveVertex(w)
    (v, w)
}
/**
 * Depending on a flag, clone an interfaced hypergraph, or just get a
 * tuple of its underlying graph and its interfaced
 * @param f The interfaced hypergraph
 * @param clone Whether or not to clone it
 * @return A tuple (graph, inputs, outputs)
 */
func CloneOrRetain(
    f : InterfacedHypergraph,
    clone : Bool
) : (Hypergraph, Array<InterfaceVertex>, Array<InterfaceVertex>) {
    if(clone) {
        let (newGraph, newInputs, newOutputs, _, _) = f.Clone()
        (newGraph, newInputs, newOutputs)
    } else {
        (f.GetGraph(), f.GetInputVertices(), f.GetOutputVertices())
    }
}
/**
 * Sequentially compose two interfaced hypergraphs with compatible interfaces
 * @param f The first interfaced hypergraph m->n
 * @param g The second interfaced hypergraph n->p
 * @param clone Whether to clone the hypergraphs involved. If this is false, the
 *              original two hypergraphs will be deformed after this operation
 * @return The composed hypergraph m->p
 */
func Seq(
    f : InterfacedHypergraph,
    g : InterfacedHypergraph,
    clone : Bool
) : InterfacedHypergraph {
    AssertCompatibleInputOutput(f, g)
    // If necessary, clone the graphs
    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)
    // The outputs of f and the inputs of g must be merged pointwise
    for (i in 0..f.GetOutputs()){
        MergeVertices(newFOutputs[i], newGInputs[i], false)
    }
    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()
    // The 'unmerged' inputs of g must be removed from the graph to avoid duplicates
    gVertices.removeAll(map({ iv : InterfaceVertex => iv.GetVertex() }, newGInputs))
    // Create the new sets of vertices are edges
    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())
    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(
        newGraph,
        newFInputs,
        newGOutputs,
        "${f.GetName()} \u{2A1F} ${g.GetName()}}"
    )
}
/**
 * Sequentially compose two interfaced hypergraphs with compatible interfaces
 * @param f The first interfaced hypergraph m->n
 * @param g The second interfaced hypergraph n->p
 * @return The composed hypergraph m->p
 */
public func Seq(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    Seq(f, g, true)
}
/**
 * Compose two interfaced hypergraphs in parallel (i.e. stack one on top of
 * each other).
 * @param f The 'first' hypergraph, to go on top
 * @param g The 'second' hypergraph, to go on bottom
 * @param clone Whether to clone the hypergraphs involved. If this is false, the
 *              original two hypergraphs will be deformed after this operation
 * @return The result of the parallel composition
 */
func Par(f : InterfacedHypergraph, g : InterfacedHypergraph, clone : Bool) : InterfacedHypergraph {
    // If necessary, clone the graphs
    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)
    // All the vertices of the original graph are preserved
    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()
    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())
    // Concatenate the inputs and outputs
    let newInputs = Array<InterfaceVertex>(f.GetInputs() + g.GetInputs(), {
        i => if(i < newFInputs.size()) {
            newFInputs[i]
        } else {
            newGInputs[i - f.GetInputs()]
        }
    })
    let newOutputs = Array<InterfaceVertex>(f.GetOutputs() + g.GetOutputs(), {
        i => if(i < newFOutputs.size()) {
            newFOutputs[i]
        } else {
            newGOutputs[i - f.GetInputs()]
        }
    })
    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(
        newGraph,
        newInputs,
        newOutputs,
        "${f.GetName()} \u{2A02} ${g.GetName()}}"
    )

}
/**
 * Compose two interfaced hypergraphs in parallel (i.e. stack one on top of
 * each other).
 * @param f The 'first' hypergraph, to go on top
 * @param g The 'second' hypergraph, to go on bottom
 * @return The result of the parallel composition
 */
public func Par(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    Par(f, g, true)
}