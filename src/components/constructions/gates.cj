package components.constructions
/**
 * Make a circuit that ripples a given primitive over some inputs, i.e. the
 * primitive will be applied to each input wire one at a time in succession
 *
 * @param primitive
 * @param inputs The number of input wires to ripple over
 * @param width The width of the input wires
 * @param delay
 * @return The rippled primitive circuit
 */
public func MakeRippleBinaryPrimitive<V, G>(
    primitive : G, inputs!: Int64, width!: Int64, delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertEqual(primitive.GetArity(), 2)
    AssertAtLeast(inputs, 2)
    let numberOfOperations = inputs - 1
    let op = {
        acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let inputs = [acc[0], cur[0]]
            UseBitwiseMapPrimitive(primitive, inputs, delay: delay)
    }
    let gateAccPorts = [Port(width)]
    let gateInputPorts = [Port(width)]
    MakeRipple<V, G, Port>(
        op, gateAccPorts, gateInputPorts, numberOfOperations,
        "${primitive.GetName()}${inputs}"
    )
}
/**
 * Use a circuit that ripples a given primitive over some inputs, i.e. the
 * primitive will be applied to each input wire one at a time in succession
 *
 * @param primitive
 * @param inputWires
 * @param delay
 * @return The output wires of the rippled primitive
 */
public func UseRippleBinaryPrimitive<V, G>(
    primitive : G, inputWires : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertEqual(primitive.GetArity(), 2)
    AssertMinimumLength(inputWires, 2)
    let width = AssertAllSameWidth(inputWires)
    if(inputWires.size == 2) {
        UsePrimitive(primitive, inputWires, delay: delay)
    } else {
        let ripplePrimitive =
            MakeRippleBinaryPrimitive(
                primitive, inputs: inputWires.size, width: width, delay: delay
            )
        UseSubcircuit(ripplePrimitive, inputWires)
    }
}
/**
 * Make a circuit that applies a given primitive bitwise, i.e. the
 * primitive will be applied to each index of the input wires in parallel.
 *
 * @param primitive
 * @param width The width of the input wires
 * @param inputs The number of input wires
 * @param delay
 * @return The bitwise mapped primitive circuit
 */
public func MakeBitwiseMapPrimitive<V, G>(
    primitive : G, width!: Int64, inputs!: Int64 = primitive.GetArity(),
    delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let allInputPorts = Array<Port>(
        inputs, { i => Port(width) }
    )
    let allOutputPorts = Array<Port>(
        primitive.GetCoarity(), { i => Port(width) }
    )
    let spec = Specification(
        "${primitive.GetName()}_1_${width}", allInputPorts, allOutputPorts
    )
    let function = {
        ws : Array<Wire<V, G>> =>
            UseRippleBinaryPrimitive(primitive, ws, delay: delay)
    }
    MakeBitwiseMap(
        function, allInputPorts, allOutputPorts, Label<V, G>.COMPOSITE(spec)
    )
}
/**
 * Use a circuit that applies a given primitive bitwise, i.e. the
 * primitive will be applied to each index of the input wires in parallel.
 *
 * @param primitive
 * @param inputWires
 * @param delay
 * @return The output wires of the bitwise map gate
 */
public func UseBitwiseMapPrimitive<V, G>(
    primitive : G, inputWires : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputWires)
    AssertHasLength(inputWires, primitive.GetArity())
    if(width == 1) {
        UsePrimitive(primitive, inputWires, delay: delay)
    } else {
        println("The width is ${width} and there are ${inputWires.size} wires to map")
        let bitwiseMap =
            MakeBitwiseMapPrimitive(
                primitive, width: width, inputs: inputWires.size, delay: delay
            )
        UseSubcircuit(bitwiseMap, inputWires)
    }
}
/**
 * Make a circuit that splits an input wire into its bits and ripples a given
 * primitive over them.
 *
 * @param primitive
 * @param width
 * @param delay
 * @return The bitwise ripple gate circuit
 */
public func MakeBitwiseRippleBinaryPrimitive<V, G>(
    primitive : G, width!: Int64, delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputPorts = [Port(width)]
    let outputPorts = [Port(1)]
    let spec = Specification(
        "${primitive.GetName()}1_${width}", inputPorts, outputPorts
    )
    MakeBitwise<V, G, Port, Port>(
        { ws : Array<Wire<V, G>> =>
            UseRippleBinaryPrimitive<V, G>(primitive, ws, delay: delay)
        }, inputPorts, outputPorts, Label<V, G>.COMPOSITE(spec)
    )
}
/**
 * Use a circuit that splits an input wire into its bits and ripples a given
 * primitive over them.
 *
 * @param primitive
 * @param inputWires
 * @param delay
 * @return The output wire of the bitwise ripple gate circuit
 */
public func UseBitwiseRippleBinaryPrimitive<V, G>(
    primitive : G, inputWires : Array<Wire<V, G>>, delay!: Int64 = 0
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputWires)
    UseSubcircuit(
        MakeBitwiseRippleBinaryPrimitive(primitive, width: width, delay: delay),
        inputWires
    )[0]
}