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
public func MergeVertices<T, U, V, G>(t : T, u : U, feedback: Bool) : (Vertex<V, G>, Vertex<V, G>)
    where T <: ContainsVertex<V, G>, U <: ContainsVertex<V, G>, V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertAtMostOneInEdge(t, u)
    let v = t.GetVertex()
    let w = u.GetVertex()
    match(w.GetInEdge()) {
        case None => ()
        case Some(ec) => ec.edge.SetTarget(ec.index, v)
    }
    let outEdges = Array<EdgeConnection<V, G>>(w.GetOutEdges())
    for(ec in outEdges){
        ec.edge.SetSource(ec.index, v, feedback)
    }
    // Make sure the old vertex isn't part of a hypergraph any more
    w.GetOwner().RemoveVertex(w)
    (v, w)
}
public func SplitVertex<V, G>(v : Vertex<V, G>) : (Vertex<V, G>, Vertex<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let leftVertex = v
    let rightVertex = Vertex<V, G>(v.GetWidth())
    leftVertex.GetOwner().AddVertex(rightVertex)
    let outEdges = HashSet<EdgeConnection<V, G>>(v.GetOutEdges())
    for(ec in HashSet(leftVertex.GetOutEdges())) {
        ec.edge.SetSource(ec.index, rightVertex, ec.edge.GetSource(ec.index).feedback)
    }
    for(ie in HashSet(v.GetInterfacedOutputs())) {
        ie.graph.ReplaceOutput(ie.index, rightVertex)
        leftVertex.RemoveAsOutput(ie.graph, ie.index)
    }
    (leftVertex, rightVertex)
}
public func SliceTentacle<V, G>(to : TentacleOrigin<V, G>) : (Vertex<V, G>, Vertex<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let existingVertex = match(to) {
        case SOURCE(e, i) => e.GetSource(i).GetVertex()
        case TARGET(e, i) => e.GetTarget(i).GetVertex()
        case INPUT(f, i) => f.GetInput(i).GetVertex()
        case OUTPUT(f, i) => f.GetOutput(i).GetVertex()
    }
    let slicedVertex = Vertex<V, G>(existingVertex.GetWidth())
    match(to) {
        case SOURCE(e, i) =>
            e.SetSource(i, slicedVertex, false)
        case TARGET(e, i) =>
            e.SetTarget(i, slicedVertex)
        case INPUT(f, i) =>
            f.ReplaceInput(i, slicedVertex)
        case OUTPUT(f, i) =>
            f.ReplaceOutput(i, slicedVertex)
    }
    (existingVertex, slicedVertex)
}
/**
 * Depending on a flag, clone an interfaced hypergraph, or just get a
 * tuple of its underlying graph and its interfaced
 * @param f The interfaced hypergraph
 * @param clone Whether or not to clone it
 * @return A tuple (graph, inputs, outputs)
 */
func CloneOrRetain<V, G>(
    f : InterfacedHypergraph<V, G>,
    clone : Bool
) : (Hypergraph<V, G>, Array<InterfaceVertex<V, G>>, Array<InterfaceVertex<V, G>>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    if(clone) {
        let (newGraph, newInputs, newOutputs, _, _) = f.Clone()
        (newGraph, newInputs, newOutputs)
    } else {
        (f.GetGraph(), f.GetInputs(), f.GetOutputs())
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
func Seq<V, G>(
    f : InterfacedHypergraph<V, G>,
    g : InterfacedHypergraph<V, G>,
    clone : Bool
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertCompatibleInputOutput(f, g)
    // If necessary, clone the graphs
    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)
    // The outputs of f and the inputs of g must be merged pointwise
    for (i in 0..f.GetCoarity()){
        MergeVertices(newFOutputs[i], newGInputs[i], false)
    }
    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()
    // The 'unmerged' inputs of g must be removed from the graph to avoid duplicates
    gVertices.removeAll(map({ iv : InterfaceVertex<V, G> => iv.GetVertex() }, newGInputs))
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
public func Seq<V, G>(f : InterfacedHypergraph<V, G>, g : InterfacedHypergraph<V, G>) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
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
func Par<V, G>(f : InterfacedHypergraph<V, G>, g : InterfacedHypergraph<V, G>, clone : Bool) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
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
    let newInputs = Array<InterfaceVertex<V, G>>(f.GetArity() + g.GetArity(), {
        i => if(i < newFInputs.size) {
            newFInputs[i]
        } else {
            newGInputs[i - f.GetArity()]
        }
    })
    let newOutputs = Array<InterfaceVertex<V, G>>(f.GetCoarity() + g.GetCoarity(), {
        i => if(i < newFOutputs.size) {
            newFOutputs[i]
        } else {
            newGOutputs[i - f.GetArity()]
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
public func Par<V, G>(f : InterfacedHypergraph<V, G>, g : InterfacedHypergraph<V, G>) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    Par(f, g, true)
}