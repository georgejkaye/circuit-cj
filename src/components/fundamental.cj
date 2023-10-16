/**
 * components/fundamental.cj
 *
 * Functions for creating primitives, the fundamental components of circuits
 *
 * @author George Kaye
 * @since 0.3
 */
package components
/**
 * Use a primitive gate
 *
 * @param prim The primitive to apply
 * @param inputs The array of inputs
 * @return The output wire of the gate
 */
func UseOperation<V, G>(
    label : Label<V, G>, inputs: Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertEqual(inputs.size, label.GetInputPorts().size)
    let opWires = UseEdgeWithNewOutputs(label, inputs, None, None)
    if(delay > 0) {
        UseDelays(opWires, duration: delay)
    } else {
        opWires
    }
}
/**
 * Use a primitive gate
 *
 * @param prim The primitive to apply
 * @param inputs The input wires
 */
public func UsePrimitive<V, G>(
    primitive : G, inputs : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAllElementsHaveWidth(inputs, 1)
    UseOperation(PRIMITIVE(primitive), inputs, delay: delay)
}
/**
 * Use a unary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The input wire
 * @return The output wire of the gate
 */
public func UseUnaryPrimitive<V, G>(
    primitive : G, a : Wire<V, G>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UsePrimitive(primitive, [a], delay: delay)
}
/**
 * Use a binary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The first input wire
 * @param a The second input wire
 * @return The output wire of the gate
 */
public func UseBinaryPrimitive<V, G>(
    primitive : G, a : Wire<V, G>, b : Wire<V, G>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UsePrimitive(primitive, [a,b], delay: delay)
}
/**
 * Use a join operation on two wires
 *
 * @param a The first wire
 * @param b The second wire
 * @return The output of the join
 */
public func UseJoin<V, G>(a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseOperation(JOIN(a.GetWidth()), [a, b])[0]
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
public func UseBlackbox<V, G>(
    blackbox : Blackbox<V, G>,
    inputs: Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseEdgeWithNewOutputs<V, G, Wire<V, G>>(
        Label<V,G>.BLACKBOX(blackbox),
        inputs,
        None<InterfacedHypergraph<V, G>>,
        inputs[0].GetGraph()
    )
}

public func MakeBlackbox<V, G>(
    blackbox : Blackbox<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputs = map(
        { p : Port => UseWire<V, G>(p.GetWidth()) }, blackbox.GetInputPorts()
    )
    let outputs = UseBlackbox(blackbox, inputs)
    MakeSubcircuit(
        mapi(
            { w : Wire<V, G>, i : Int64 => InterfaceWire(w, blackbox.GetInputPort(i).GetName())},
            inputs
        ),
        mapi(
            { w : Wire<V, G>, i : Int64 => InterfaceWire(w, blackbox.GetOutputPort(i).GetName())},
            outputs
        ),
        BLACKBOX(blackbox)
    )
}