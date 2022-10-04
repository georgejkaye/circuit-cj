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
 * Nullary gates
 */

public func UseValue<V, G>(v : V) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseEdgeWithNewOutputs<Vertex<V, G>, V, G>(
        VALUE(v),
        Array<Vertex<V, G>>(),
        None<InterfacedHypergraph<V, G>>
    )[0]
}

public func Join<V, G>(a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseOperation(JOIN(a.GetWidth()), [a, b])
}

/**
 * Create an edge for a given array of values
 * @param vs The array of values
 * @param signed Whether the number is signed
 * @return The output wire
 */
func MakeSignal<V, G>(spec : Signal<V>) : InterfacedHypergraph
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
func UseSignal<V, G>(spec : Signal<V>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    if(spec.GetWidth() == 1) {
        UseValue(spec.values[0])
    } else {
        UseSubcircuit_1<Wire<V, G>, V, G>(
            MakeSignal(spec),
            Array<Wire>()
        )
    }
}
public func UseSignal<V, G>(v : V, i : Int64) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let array : Array<V> = Array<V>(i, {i : Int64 => v})
    UseSignal(Signal(array, false))
}