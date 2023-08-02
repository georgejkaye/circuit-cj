package components.constructions

/**
 * Given an array of wires, split them to create an array of arrays of one-bit
 * wires of the form output[i][j] = input[j][i].
 *
 * @param inputs The array of wires to split
 * @return The array of arrays of split wires
 */
public func BitwiseSplit<V, G>(
    inputs : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let totalBits = Sum(inputs, { w => w.GetWidth() })
    let splitInputs = map({ w : Wire<V, G> => Split(w) }, inputs)
    concat(splitInputs)
}
/**
 * Given an array of arrays of wires, combine them to create an array of wires,
 * so that outputs[i] = [inputs[0][i], inputs[1][i], ...].
 *
 * @param inputs The array of arrays of wires to combine
 * @return The array of combined wires
 */
public func BitwiseCombine<V, G>(
    inputWires : Array<Wire<V, G>>,
    bundleWidth : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let numberOfBundles = inputWires.size / bundleWidth
    Array<Wire<V, G>>(numberOfBundles, { i =>
        Combine(
            Array<Wire<V, G>>(bundleWidth, { j =>
                inputWires[bundleWidth * j + i]
            })
        )
    })
}
/**
 * Perform a bitwise map.
 *
 * @param f (input array) -> output array
 * @param input array
 * @return output wire
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    outputBundleWidth : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>,  G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    let outputWires = Map(f, inputWires, inputs.size)
    BitwiseCombine<V, G>(outputWires, outputBundleWidth)
}
/**
 * Perform a bitwise map.
 *
 * @param f (input array) -> output wire
 * @param input wire
 * @return output wire
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    inputBundleWidth : Int64,
    outputBundleWidth : Int64
) : Wire<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs)] }
    BitwiseMap(fAdjusted, inputs, outputBundleWidth)[0]
}
/**
 * Perform a bitwise map.
 *
 * @param f (input wire) -> output wire
 * @param input wire
 * @return output wire
 */
public func BitwiseMap<V, G>(
    f : (Wire<V, G>) -> Wire<V, G>,
    input : Wire<V, G>,
    inputBundleWidth : Int64,
    outputBundleWidth : Int64
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs[0])] }
    BitwiseMap(fAdjusted, [input], outputBundleWidth)[0]
}
/**
 * Make a bitwise map subcircuit for an operation.
 *
 * @param f The operation
 * @param n The number of times to map (the width of the input wires)
 * @param wires The number of input wires (the number of inputs f expects)
 * @param label The label to give the new subcircuit
 */
public func MakeBitwiseMap<V, G, T, U>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputPorts : Array<T>, outputPorts : Array<U>,
    inputBundleWidth: Int64, outputBundleWidth: Int64, label: Label<V, G>
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let inputWires = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, inputPorts
    )
    let outputWires =
        BitwiseMap(f, inputWires, outputBundleWidth)
    let inputInterfaceWires =
        map2(
            { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
            inputWires, inputPorts
        )
    let outputInterfaceWires =
        map2(
            { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName()) },
            outputWires, outputPorts
        )
    MakeSubcircuit(inputInterfaceWires, outputInterfaceWires, label)
}
func GetBitwiseMapPorts<V, G>(
    numberOfPorts : Int64, numberOfOperations : Int64,
    getVertex : (Int64) -> InterfaceVertex<V, G>
) : Array<Port>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Array<Port>(numberOfPorts * numberOfOperations, { i =>
        let portVertex = getVertex(i % numberOfPorts)
        Port(portVertex.GetWidth(), name: portVertex.GetName())
    })
}
/**
 * Make a bitwise map subcircut for a subcircuit.
 *
 * @param f The subcircuit
 * @param n The number of times to map (the widtrh of the input wires)
 */
public func MakeBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{

    let inputPorts = GetBitwiseMapPorts(
        f.GetArity(), numberOfOperations, { i : Int64 => f.GetInput(i) })
    let outputPorts = GetBitwiseMapPorts(
        f.GetCoarity(), numberOfOperations, { i : Int64 => f.GetOutput(i) })
    let spec = Specification(
        "${f.GetName()}_${numberOfOperations}", inputPorts, outputPorts
    )
    MakeBitwiseMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws) },
        inputPorts, outputPorts, f.GetArity(), f.GetCoarity(),
        Label<V, G>.COMPOSITE(spec)
    )
}


/**
 * Make a circuit that applies a given primitive bitwise, i.e. the primitive
 * will be applied to each bit of the input wires independently
 *
 * @param prim The primitive to apply
 * @param w The width of the input wires
 * @return The bitwise gate circuit
 */
public func MakeBitwiseMapGate<V, G>(
    prim : G, w : Int64, delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // let inputs = Array<Wire<V, G>>(
    //     prim.GetArity(),
    //     {i : Int64 => UseWire<V, G>(w) }
    // )
    // let output = BitwiseMap(
    //     { inputs : Array<Wire<V, G>> => UseGate(prim, inputs, delay: delay) },
    //     inputs
    // )[0]
    // MakeSubcircuit(
    //     mapi(
    //         { w : Wire<V, G>, i : Int64 =>
    //             InterfaceWire(w, numToUppercaseLetter(i))
    //         },
    //         inputs
    //     ),
    //     [InterfaceWire(output, "Z")],
    //     COMPOSITE(
    //         Specification(
    //             "${prim.GetName()}_${w}",
    //             Array<Port>(
    //                 prim.GetArity(), { i => Port(w, numToUppercaseLetter(i)) }
    //             ),
    //             Array<Port>(
    //                 prim.GetCoarity(), { i => Port(w, numToUppercaseLetter(i)) }
    //             )
    //         )
    //     )
    // )
    throw Exception("to do")
}
/**
 * Connect some inputs to a bitwise primitive
 *
 * @param prim The primitive to bitwise
 * @param ws The input wires
 * @return The output wire from the bitwise gate
 */
public func UseBitwiseMapGate<V, G>(
    prim : G, ws : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAllSameWidth(ws)
    AssertHasLength(ws, prim.GetArity())
    if(ws[0].GetWidth() == 1) {
        UseGate(prim, ws, delay: delay)
    } else {
        UseSubcircuit(
            MakeBitwiseMapGate(prim, ws[0].GetWidth(), delay: delay),
            ws
        )
    }
}
/**
 * Connect an input to an internally rippled primitive
 *
 * @param prim The primitive to ripple
 * @param w The input wire
 * @return The output wire from the internally rippled gate
 */
public func UseBitwiseRippleGate<V, G>(
    prim : G, ws : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(ws)
    UseSubcircuit(MakeBitwiseRippleGate(prim, width, delay: delay), ws)
}
/**
 * Make a circuit that ripples a given primitive over the bits in a single
 * wire, i.e. the primitive will be applied to each bit wire one at a time in
 * succession.
 *
 * @param prim The primitive to apply
 * @param w The width of the input wire
 * @return The internal ripple gate circuit
 */
public func MakeBitwiseRippleGate<V, G>(
    prim : G, w : Int64, delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // let input = UseWire<V, G>(w)
    // let output = BitwiseRipple(
    //     { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
    //         UseGate(prim, [acc[0], cur[0]], delay: delay)
    //     },
    //     [input]
    // )[0]
    // MakeSubcircuit(
    //     [InterfaceWire(input, "A")],
    //     [InterfaceWire(output, "Z")],
    //     COMPOSITE(
    //         Specification(
    //             "${prim.GetName()}_1_${w}",
    //             [Port(w)], [Port(1)]
    //         )
    //     )
    // )
    throw Exception("to do")
}