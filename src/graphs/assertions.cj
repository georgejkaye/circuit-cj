/**
 * graphs/assertions.cj
 *
 * Assertions specific to graphs.
 *
 * @author George Kaye
 * @since 0.2
 */
package graphs
/**
 * Given two vertex-like objects, assert that between them they have at most
 * one in edge.
 *
 * @param t
 * @param u
 * @return None if there is no in edge, and the single in edge if there is one
 */
func AssertLessThanOneInEdge<V, G, T, U>(
    t : T, u : U
) : Option<EdgeConnection<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G>, U <: ContainsVertex<V, G>
{
    let v = t.GetVertex()
    let w = u.GetVertex()
    match(v.GetInEdge()) {
        case None    => w.GetInEdge()
        case Some(ev) =>
            AssertHasParameter(
                w, None, { w : Vertex<V, G> => w.GetInEdge() }, InEdge
            )
            Some(ev)
    }
}
/**
 * Given an array of vertex-like objects, assert that between them they have at
 * most one in edge.
 *
 * @param ts The array of vertex-like objects
 * @return None if there is no in edge, and the single in edge if there is one
 */
func AssertLessThanOneInEdge<V, G, T>(
    ts : Array<T>
) : Option<EdgeConnection<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G>
{
    var inEdge = None<EdgeConnection<V, G>>
    for (t in ts) {
        let v = t.GetVertex()
        match(inEdge) {
            case Some(ec) =>
                AssertHasParameter(
                    v, None, { w : Vertex<V, G> => w.GetInEdge() }, InEdge
                )
            case None =>
                inEdge = v.GetInEdge()
        }
    }
    inEdge
}
/**
 * Assert a given vertex-like object has no in edge
 *
 * @param <T> The type that contains a vertex
 * @param v
 */
public func AssertHasNoInEdge<V, G, T>(v : T) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G>
{
    AssertIsNone(v.GetVertex().GetInEdge())
}
/**
 * Assert a given vertex-like object has no out edges
 *
 * @param <T> The type that contains a vertex
 * @param v
 */
public func AssertHasNoOutEdges<V, G, T>(v : T) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G>
{
    AssertEmpty(v.GetVertex().GetOutEdges())
}
/**
 * Given an array of vertices, assert that they do not have any in edges
 *
 * @param <T> The type that contains a vertex
 * @param targets
 */
func AssertTargetsUnassigned<V, G, T>(targets : Array<T>) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G> & ToString
{
    AssertElementsHaveParameter<T, Option<EdgeConnection<V, G>>>(
        targets, None<EdgeConnection<V, G>>,
        { t => t.GetVertex().GetInEdge() }, InEdge
    )
}
/**
 * Given two interfaced hypergraphs, assert that the output ports of the first
 * match the input ports of the second.
 *
 * @param f
 * @param g
 */
func AssertCompatibleInputOutput<V, G>(
    f : InterfacedHypergraph<V, G>,
    g : InterfacedHypergraph<V, G>
) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertElementsHaveParameters<Port, Port, Port>(
        g.GetInputPorts(), f.GetOutputPorts(),
        { p : Port => p }, { p : Port => p }, Width
    )
}
/**
 * Given an interfaced hypergraph, assert that it has at least a certain
 * number of input ports.
 *
 * @param f
 */
func AssertGraphHasMinimumInputs<V, G>(
    f : InterfacedHypergraph<V, G>, i : Int64
) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertMinimumLength(f.GetInputPorts(), i)
}
/**
 * Given an interfaced hypergraph, assert that it has at least a certain
 * number of output ports.
 *
 * @param f
 */
func AssertGraphHasMinimumOutputs<V, G>(
    f : InterfacedHypergraph<V, G>, i : Int64
) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertMinimumLength(f.GetOutputPorts(), i)
}
public func AssertAllOwnedBySame<V, G, T>(
    elems : Collection<T>
) : Hypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: GraphElement<V, G> & ToString
{
    AssertCollectionHasSameParameter(elems, { t : T => t.GetGraph() }, Owner)
}
/**
 * Given an edge, assert that it is not owned by a particular hypergraph.
 *
 * @param e The edge
 * @param f The hypergraph
 */
public func AssertNotOwnedBy<V, G>(e : Edge<V, G>, f : Hypergraph<V, G>) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertIsNone(e.GetGraph())
}