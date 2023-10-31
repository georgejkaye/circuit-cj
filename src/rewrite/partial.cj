/**
 * rewrite/partial.cj
 *
 * Partially evaluate circuits
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
import syntax.PartialInput
import components.UseEdge
import graphs.InterfacedHypergraph
func Apply<V, G>(v : Vertex<V, G>, input : PartialInput<V>) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertBothSameWidth(v, input)
    let partial = UseEdge(
        PARTIAL(input), Array<Vertex<V, G>>(), [v],
        None<InterfacedHypergraph<V, G>>, v.GetGraph()
    )
}
/**
 * Partially evaluate a circuit. Clones the circuit so the original is not
 * affected
 *
 * @param f
 * @param partialInputs
 */
public func PartialEvaluate<V, G>(
    f: InterfacedHypergraph<V, G>,
    partialInputs : Array<PartialInputType<V>>
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    AssertHasLength<PartialInputType<V>>(partialInputs, f.GetArity())
    let clonedF = f.Clone()
    forEach(
        { pit : PartialInputType<V>, i : Int64 =>
            let pi = PartialInput(pit, clonedF.GetInput(i).GetWidth())
            Apply(clonedF.GetInput(i).GetVertex(), pi)
        }, partialInputs
    )
    clonedF.WriteDotToFile("dot/partial")
}