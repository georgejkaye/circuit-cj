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
public func MergeVertices<T, U, V, G>(
    t : T,
    u : U,
    feedback: Bool
) : (Vertex<V, G>, Vertex<V, G>)
    where
        T <: ContainsVertex<V, G>,
        U <: ContainsVertex<V, G>,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertAtMostOneInEdge(t, u)
    let v = t.GetVertex()
    let w = u.GetVertex()
    match(w.GetInEdge()) {
        case None => ()
        case Some(ec) => ec.GetEdge().SetTarget(ec.GetIndex(), v)
    }
    let outEdges = Array<EdgeConnection<V, G>>(w.GetOutEdges())
    for(ec in outEdges){
        ec.GetEdge().SetSource(ec.GetIndex(), v, feedback)
    }
    func UpdateInterfaces(ie : InterfaceElement<V, G>) {
        let graph = ie.graph
        let index = ie.index
        match(ie.interfaceType) {
            case INPUT => graph.ReplaceInput(index, v)
            case OUTPUT => graph.ReplaceOutput(index, v)
        }
    }
    for(ie in HashSet(w.GetInterfacedInputs())) {
        UpdateInterfaces(ie)
    }
    for(ie in HashSet(w.GetInterfacedOutputs())) {
        UpdateInterfaces(ie)
    }
    // Make sure the old vertex isn't part of a hypergraph any more
    // w.GetGraph().RemoveVertex(w)
    (v, w)
}
public func MergeVertices<T, V, G>(vs : Array<T>) : Vertex<V, G>
    where
        T <: ContainsVertex<V, G>,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertAtMostOneInEdge<T, V, G>(vs)
    let retainedVertex = vs[0].GetVertex()
    for(i in 1..vs.size) {
        let discardedVertex = vs[i].GetVertex()
        match(discardedVertex.GetInEdge()) {
            case None => ()
            case Some(ec) => ec.GetEdge()
        }
        for(ie in discardedVertex.GetInterfacedInputs()) {
            ie.graph.ReplaceInput(ie.index, retainedVertex)
        }
        for(ec in discardedVertex.GetOutEdges()) {
            ec.GetEdge().SetSource(ec.GetIndex(), retainedVertex, false)
        }
        for(ie in discardedVertex.GetInterfacedOutputs()) {
            ie.graph.ReplaceOutput(ie.index, retainedVertex)
        }
        discardedVertex.GetGraph().RemoveVertex(discardedVertex)
    }
    retainedVertex
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
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    if(clone) {
        let (newGraph, newInputs, newOutputs, _, _) = f.CloneGraph()
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
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertCompatibleInputOutput(f, g)
    // If necessary, clone the graphs
    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)
    // The outputs of f and the inputs of g must be merged pointwise
    for (i in 0..f.GetCoarity()){
        newFOutputs[i].GetVertex().MergeVertex(
            newGInputs[i].GetVertex(), false
        )
    }
    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()
    // The 'unmerged' inputs of g must be removed from the graph to avoid duplicates
    gVertices.removeAll(map({ iv : InterfaceVertex<V, G> => iv.GetVertex() }, newGInputs))
    // Create the new sets of vertices are edges
    let newGraph = Hypergraph<V, G>()
    newGraph.AddEdges(newF.GetEdges())
    newGraph.AddEdges(newG.GetEdges())
    newGraph.AddVertices(fVertices)
    newGraph.AddVertices(gVertices)
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
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
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
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    // If necessary, clone the graphs
    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)
    // All the vertices of the original graph are preserved
    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()
    let newGraph = Hypergraph<V, G>()
    newGraph.AddEdges(newF.GetEdges())
    newGraph.AddEdges(newG.GetEdges())
    newGraph.AddVertices(fVertices)
    newGraph.AddVertices(gVertices)
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
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    Par(f, g, true)
}