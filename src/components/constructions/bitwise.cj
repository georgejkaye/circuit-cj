package components.constructions
/**
 * Given an array of wires
 *
 * [inputs[0], inputs[1], ... , inputs[n-1]]
 *
 * split each wire to create an array of one-bit wires
 *
 * [inputs[0][0], inputs[1][0], ... inputs[n-1][0], inputs[0][1], ...]
 *
 * @param inputWires
 * @return The array of split wires
 */
public func BitwiseSplit<V, G>(
    inputWires : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputWires)
    let totalBits = Sum(inputWires, { w => w.GetWidth() })
    let splitInputs = map({ w : Wire<V, G> => Split(w) }, inputWires)
    Array<Wire<V, G>>(totalBits, {
        i : Int64 =>
            let element = i % inputWires.size
            let index = i / inputWires.size
            println("Getting ${element}:${index}")
            splitInputs[element][index]
    })
}
/**
 * Given an array of one-bit wires sorted as
 *
 * [outputs[0][0], outputs[1][0], ... outputs[n][0], outputs[0][1], ...]
 *
 * and so on, combine them to create an array
 *
 * [outputs[0], outputs[1], ..., outputs[n]]
 *
 * @param inputWires
 * @param numberOfOutputBundles
 *              The number of bundles the bitwise operation has created
 * @return The array of combined wires
 */
public func BitwiseCombine<V, G>(
    inputWires : Array<Wire<V, G>>, numberOfOutputBundles : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAllHaveWidth(inputWires, 1)
    let wiresPerOutputBundle = inputWires.size / numberOfOutputBundles
    let numberOfOutputWires = wiresPerOutputBundle
    Array<Wire<V, G>>(numberOfOutputWires, {
        i =>
            Combine(
                Array<Wire<V, G>>(numberOfOutputBundles, { j =>
                    let index = j + (i * numberOfOutputWires)
                    inputWires[index]
                })
            )
    })
}
/**
 * Perform an operation bitwise: split input wires into one-bit wires,
 * apply an operation to all of them, then combine the outputs.
 *
 * @param f (split incoming) -> (split outgoing)
 * @param inputWires
 * @param numberOfOutputBundles The number of bundles created by the operation
 * @return The array of combined wires
 */
public func Bitwise<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>,
    numberOfOutputBundles : Int64
) : Array<Wire<V, G>> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let width = AssertAllSameWidth(inputWires)
    let splitWires = BitwiseSplit(inputWires)
    let outputWires = f(splitWires)
    let combinedWires = BitwiseCombine(outputWires, numberOfOutputBundles)
    combinedWires
}
/**
 * Perform a bitwise map: splitting input wires into one-bit wires, applying an
 * operation to wires with the same index of each input, then combining the
 * wires again.
 *
 * @param f (ingoing bundle) -> outgoing bundle
 * @param inputWires
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>,  G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputWires)
    Bitwise(
        { ws : Array<Wire<V, G>> => Map(f, ws, width) }, inputWires, width
    )
}
/**
 * Perform a bitwise map: splitting input wires into one-bit wires, applying an
 * operation to wires with the same index of each input, then combining the
 * wires again.
 *
 * @param f (ingoing bundle) -> outgoing wire
 * @param inputWires
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputWires : Array<Wire<V, G>>
) : Wire<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs)] }
    BitwiseMap(fAdjusted, inputWires)[0]
}
/**
 * Perform a bitwise map: splitting input wires into one-bit wires, applying an
 * operation to wires with the same index of each input, then combining the
 * wires again.
 *
 * @param f (ingoing wire) -> outgoing wire
 * @param inputWires
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Wire<V, G>) -> Wire<V, G>, input : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs[0])] }
    BitwiseMap(fAdjusted, [input])[0]
}
/**
 * Make a bitwise circuit: splitting input wires into one-bit wires,
 * applying an operation to these wires, then combining the wires again.
 *
 * @param f (ingoing bundle) -> outgoing bundle
 * @param allInputPorts The port details for all input ports
 * @param allOutputPorts The port details for all output ports
 * @return The bitwise circuit
 */
func MakeBitwise<V, G, T, U>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    allInputPorts : Array<T>,
    allOutputPorts : Array<U>,
    label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>,  G <: PrimitiveSymbol<V, G>,
            T <: HasPort, U <: HasPort
{
    let outputBundleSize = AssertAllSameWidth(allOutputPorts)
    let inputWires = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, allInputPorts
    )
    let outputWires = Bitwise(f, inputWires, outputBundleSize)
    let inputInterfaceWires = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputWires, allInputPorts
    )
    let outputInterfaceWires = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName()) },
        outputWires, allOutputPorts
    )
    MakeSubcircuit<V, G>(inputInterfaceWires, outputInterfaceWires, label)
}
/**
 * Make a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f (ingoing bundle) -> outgoing bundle
 * @param allInputPorts The port details for all input ports
 * @param allOutputPorts The port details for all output ports
 * @return The bitwise map circuit
 */
func MakeBitwiseMap<V, G, T, U>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    allInputPorts : Array<T>, allOutputPorts : Array<U>,
    label: Label<V, G>
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let width = AssertAllSameWidth(allInputPorts)
    MakeBitwise(
        { ws : Array<Wire<V, G>> => Map(f, ws, allInputPorts.size)},
        allInputPorts, allOutputPorts, label
    )
}
/**
 * Get the input or output ports for a bitwise map circuit.
 *
 * @param bundlePorts The port details for one bundle
 * @param numberOfOperations
 * @return An array of ports for the complete map circuit
 */
func GetMapPorts<V, G, T>(
    bundlePorts : Array<T>, numberOfOperations : Int64
) : Array<Port>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    map(
        { t : T =>
            let width = t.GetWidth() * numberOfOperations
            Port(width, name: t.GetName())
        },
        bundlePorts
    )
}
/**
 * Make a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f (ingoing bundle) -> outgoing bundle
 * @param incomingBundlePorts The port details for an incoming bundle
 * @param outgoingBundlePorts The port details for an outgoing bundle
 * @return The bitwise map circuit
 */
public func MakeBitwiseMap<V, G, T, U>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    incomingBundlePorts : Array<T>,
    outgoingBundlePorts : Array<U>,
    numberOfOperations : Int64,
    name : String
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
                T <: HasPort, U <: HasPort
{
    let totalInputPorts =
        GetMapPorts<V, G, T>(incomingBundlePorts, numberOfOperations)
    let totalOutputPorts =
        GetMapPorts<V, G, U>(outgoingBundlePorts, numberOfOperations)
    let spec = Specification(name, totalInputPorts, totalOutputPorts)
    MakeBitwiseMap(
        f, totalInputPorts, totalOutputPorts, Label<V, G>.COMPOSITE(spec)
    )
}
/**
 * Make a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f The circuit to bitwise map
 * @param numberOfOperations
 * @return The bitwise map circuit
 */
public func MakeBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputPorts = GetMapPorts<V, G, InterfaceVertex<V, G>>(
        f.GetInputs(), numberOfOperations
    )
    let outputPorts = GetMapPorts<V, G, InterfaceVertex<V, G>>(
        f.GetOutputs(), numberOfOperations
    )
    let spec = Specification(
        "${f.GetName()}_${numberOfOperations}", inputPorts, outputPorts
    )
    MakeBitwiseMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws) },
        inputPorts, outputPorts, Label<V, G>.COMPOSITE(spec)
    )
}
/**
 * Use a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f The circuit to bitwise map
 * @param inputWires
 * @return The outputs of the bitwise map circuit
 */
public func UseBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    inputWires : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputWires)
    UseSubcircuit(MakeBitwiseMap(f, width))
}