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
 * Depending on a flag, clone an interfaced hypergraph, or just get a
 * tuple of its underlying graph and its interfaced
 * @param f The interfaced hypergraph
 * @param clone Whether or not to clone it
 * @return A tuple (graph, inputs, outputs)
 */
func CloneOrRetain<V, G>(
    f : InterfacedHypergraph<V, G>,
    clone : Bool
) :
    (Hypergraph<V, G>, Array<InterfaceVertex<V, G>>,
        Array<InterfaceVertex<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
    // The 'unmerged' inputs of g must be removed from the graph to avoid
    // duplicates
    gVertices.removeAll(
        map({ iv : InterfaceVertex<V, G> => iv.GetVertex() }, newGInputs)
    )
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
public func Seq<V, G>(
    f : InterfacedHypergraph<V, G>, g : InterfacedHypergraph<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
func Par<V, G>(
    f : InterfacedHypergraph<V, G>, g : InterfacedHypergraph<V, G>, clone : Bool
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
public func Par<V, G>(
    f : InterfacedHypergraph<V, G>, g : InterfacedHypergraph<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Par(f, g, true)
}