/**
 * components/fundamental.cj
 *
 * Functions for creating values and primitives, the fundamental
 * components of circuits
 *
 * @author George Kaye
 * @since 0.3
 */

package components

import graphs.*
import syntax.*

/**
 * Use a primitive gate
 *
 * @param prim The primitive to apply
 * @param inputs The array of inputs
 * @return The output wire of the gate
 */
func UseOperation<V, G>(label : Label<V, G>, inputs: Array<Wire<V, G>>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertNumberOfWires(inputs, label.GetInputPorts().size)
    UseEdgeWithNewOutputs(
        label,
        inputs,
        None
    )[0]
}
/**
 * Use a primitive gate
 *
 * @param prim The primitive to apply
 * @param inputs The input wires
 */
public func UseGate<V, G>(prim : G, inputs : Array<Wire<V, G>>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertAllWiresWidth(inputs, 1)
    UseOperation(PRIMITIVE(prim), inputs)
}
/**
 * Use a unary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The input wire
 * @return The output wire of the gate
 */
public func UseUnaryGate<V, G>(prim : G, a : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseGate(prim, [a])
}
/**
 * Use a binary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The first input wire
 * @param a The second input wire
 * @return The output wire of the gate
 */
public func UseBinaryGate<V, G>(prim : G, a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseGate(prim, [a,b])
}
/**
 * Use a value
 *
 * @param v The value to use
 * @return The output of the value
 */
public func UseValue<V, G>(v : V) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseEdgeWithNewOutputs<V, G, Vertex<V, G>>(
        Label<V, G>.VALUE(v),
        Array<Vertex<V, G>>(),
        None<InterfacedHypergraph<V, G>>
    )[0]
}
/**
 * Use a join operation on two wires
 *
 * @param a The first wire
 * @param b The second wire
 * @return The output of the join
 */
public func UseJoin<V, G>(a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseOperation(JOIN(a.GetWidth()), [a, b])
}
/**
 * Make a subcircuit containing a signal
 *
 * @param vs The array of values
 * @param signed Whether the number is signed
 * @return The output wire
 */
public func MakeSignal<V, G>(spec : Signal<V>) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let vs = spec.values
    let wires = map(
        { v : V =>
            UseEdgeWithNewOutputs(
                Label<V, G>.VALUE(v),
                Array<Vertex<V, G>>(),
                None<InterfacedHypergraph<V, G>>
            )[0]
        },
        vs
    )
    MakeSubcircuit(
        Array<InterfaceWire<V, G>>(),
        [InterfaceWire(Combine(wires))],
        SIGNAL(spec)
    )
}
/**
 * Use a signal
 *
 * @param The signal to use
 * @return The output of the signal
 */
public func UseSignal<V, G>(spec : Signal<V>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    if(spec.GetWidth() == 1) {
        UseValue(spec.values[0])
    } else {
        UseSubcircuit_1<Wire<V, G>, V, G>(
            MakeSignal(spec),
            Array<Wire<V, G>>()
        )
    }
}
/**
 * Use a signal cosntructed as multiple copies of a single value
 *
 * @param v The value to use
 * @param i The number of this value to use
 * @return The output of the signal
 */
public func UseSignal<V, G>(v : V, i : Int64) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let array : Array<V> = Array<V>(i, {i : Int64 => v})
    UseSignal(Signal(array))
}
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
