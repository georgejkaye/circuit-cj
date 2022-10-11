/**
 * components/library.cj
 *
 * Common circuit components
 *
 * @author George Kaye
 * @since 0.2
 */

package components

/**
 * Use a blackbox, a component that we can't look inside
 *
 * @param name The name of the blackbox
 * @param domain The ports of the inputs
 * @param codomain The ports of the outputs
 * @param inputs The input wires
 * @return The array of outputs of this blackbox
 */
public func BlackBox<V, G>(
    name : String,
    domain : Array<Port<V>>,
    codomain : Array<Port<V>>,
    inputs: Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseEdgeWithNewOutputs<V, G, Wire<V, G>>(
        Label<V,G>.BLACKBOX(
            Specification<V>(
                name,
                domain,
                codomain
            )
        ),
        inputs,
        None<InterfacedHypergraph<V, G>>
    )
}
