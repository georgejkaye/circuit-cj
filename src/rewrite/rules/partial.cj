/**
 * rewrite/rules/partial.cj
 *
 * Functions for dealing with the partially specified values.
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite.rules
public func GetUniquePartialRule<V, G>() : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "unique",
        PARTIAL,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let variable = e.GetLabel().GetVariableSignal()
                let potentialSignals = variable.GetPotentialSignals()
                if(potentialSignals.size == 1) {
                    let signal = potentialSignals.iterator().next().getOrThrow()
                    let target = e.GetTarget(0)
                    f.RemoveEdge(e)
                    let edge = MakeValueOrSignal(signal, [target], f.GetGraph())
                    Some(HashSet([EDGE(edge)]))
                } else {
                    None
                }
        }
    )
}