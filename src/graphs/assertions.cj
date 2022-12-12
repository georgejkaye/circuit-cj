/**
 * graphs/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

import assertions.*

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
func AssertAtMostOneInEdge<T, V, G>(ts : Array<T>) : Option<EdgeConnection<V, G>>
    where T <: ContainsVertex<V, G>, V <: ValueSymbol,
            V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    var inEdge = None<EdgeConnection<V, G>>
    for (t in ts) {
        let v = t.GetVertex()
        match(inEdge) {
            case Some(ec) =>
                AssertHasParameter<Vertex<V, G>, Option<EdgeConnection<V, G>>>(
                v,
                None,
                { w : Vertex<V, G> => w.GetInEdge() },
                InEdge
            )
            case None =>
                inEdge = v.GetInEdge()
        }
    }
    inEdge
}
public func AssertVertexHasNoInEdge<V, G>(v : Vertex<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertIsNone(v.GetInEdge(), InEdge)
}
func AssertTargetsUnassigned<V, G>(targets : Array<Tentacle<V, G>>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayElementsHaveParameter(
        targets,
        None<EdgeConnection<V, G>>,
        { t => t.vertex.GetInEdge() },
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