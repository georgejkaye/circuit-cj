/**
 * graphs/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

import assertions.*

func AssertOwned<T,U>(t : T) : U where T <: Ownable<U>, U <: ToString {
    AssertIsNotNone<U>(t.GetOwner(), Owner)
}
func AssertAtMostOneInEdge<T, U, V, G>(t : T, u : U) : Option<EdgeConnection<V, G>>
    where T <: ContainsVertex<V, G>, U <: ContainsVertex<V, G>, V <: ValueSymbol,
            V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let v = t.GetVertex()
    let w = u.GetVertex()
    match(v.GetInEdge()) {
        case None    => w.GetInEdge()
        case Some(ev) =>
            AssertHasParameter<Vertex<V, G>, Option<EdgeConnection<V, G>>>(
                w,
                None,
                { w : Vertex<V, G> => w.GetInEdge() },
                InEdge
            )
            Some(ev)
    }
}
public func AssertVertexHasNoInEdge<V, G>(v : Vertex<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertIsNone(v.GetInEdge(), InEdge)
}
func AssertTargetsUnassigned<T, V, G>(targets : Array<T>) : Unit
    where T <: ContainsVertex<V,G>, T <: ToString, V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayElementsHaveParameter<T, Option<EdgeConnection<V, G>>>(
        targets,
        None,
        { t : T => t.GetVertex().GetInEdge() },
        InEdge
    )
}
func AssertCompatibleInputOutput<V, G>(
    f : InterfacedHypergraph<V, G>,
    g : InterfacedHypergraph<V, G>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    AssertArrayElementsHaveParameters<Port<V>, Port<V>, Port<V>>(
        g.GetInputPorts(),
        f.GetOutputPorts(),
        { p : Port<V> => p },
        { p : Port<V> => p },
        Width
    )
}
func AssertGraphHasMinimumInputs<V, G>(f : InterfacedHypergraph<V, G>, i : Int64) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayHasMinimumLength(f.GetInputPorts(), i)
}
func AssertGraphHasMinimumOutputs<V, G>(f : InterfacedHypergraph<V, G>, i : Int64) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayHasMinimumLength(f.GetOutputPorts(), i)
}