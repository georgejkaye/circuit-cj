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
public func MergeVertices<T, U>(t : T, u : U) : (Vertex, Vertex) where T <: ContainsVertex, U <: ContainsVertex {
    let inEdge = AssertAtMostOneInEdge(t, u)
    let v = t.GetVertex()
    let w = u.GetVertex()
    match (inEdge) {
        case None => ()
        case Some(ec) => 
            ec.edge.SetTarget(ec.index, v)
    }
    let wOutEdges = w.GetOutEdges() 
    v.AddAllOutEdges(w.GetOutEdges())
    for (e in wOutEdges) {
        e.edge.SetSource(e.index, v)
    }
    // Make sure the old vertex isn't part of a hypergraph any more
    match(w.GetOwner()) {
        case None => ()
        case Some(g) => g.RemoveVertex(w)
    }
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
        f.Clone()
    } else {
        (f.GetGraph(), f.GetInputVertices(), f.GetOutputVertices())
    }
}

/**
 * Sequentially compose two interfaced hypergraphs with compatible interfaces
 * @param f The first interfaced hypergraph m->n
 * @param g The second interfaced hypergraph n->p
 * @return The composed hypergraph m->p
 */
func Seq(
    f : InterfacedHypergraph,
    g : InterfacedHypergraph,
    clone : Bool
) : InterfacedHypergraph {
    AssertCompatibleInputOutput(f, g)

    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)

    for (i in 0..f.GetOutputs()){
        MergeVertices(newFOutputs[i], newGInputs[i])
    }

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    gVertices.removeAll(map({ iv : InterfaceVertex => iv.GetVertex() }, newGInputs))

    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())

    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(
        newGraph, 
        newFInputs, 
        newGOutputs,
        "${f.GetName()} ; ${g.GetName()}}"
    )
}

public func Seq(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    Seq(f, g, true)
}

func Par(f : InterfacedHypergraph, g : InterfacedHypergraph, clone : Bool) : InterfacedHypergraph {

    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())

    let newInputs = Array<InterfaceVertex>(f.GetInputs() + g.GetInputs(), {
        i => if(i < newFInputs.size) {
            newFInputs[i]
        } else {
            newGInputs[i - f.GetInputs()]
        }
    })
    let newOutputs = Array<InterfaceVertex>(f.GetOutputs() + g.GetOutputs(), {
        i => if(i < newFOutputs.size) {
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
        "${f.GetName()} * ${g.GetName()}}"
    )

}

public func Par(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    Par(f, g, true)
}