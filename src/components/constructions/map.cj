package components.constructions
/**
 * Perform a map, an operation that applies an operation in parallel to
 * multiple bundles.
 *
 * @param f (in data bundle) -> (out data bundle)
 * @param incomingWires wires for each operation concatenated together
 *                          data[0] ++ data[1] ++ data[2] ++ ...
 * @param incomingBundleSize The number of wires in each incoming bundle
 * @return An array containing all of the outgoing bundles
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    incomingWires : Array<Wire<V, G>>,
    numberOfOperations : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let incomingBundleSize =
        AssertLengthMultipleOf(incomingWires, numberOfOperations)
    let outputBundles =
        Array<Array<Wire<V, G>>>(numberOfOperations, {
            i =>
                let curInputWires = incomingWires.slice(
                    i * incomingBundleSize, incomingBundleSize
                )
                f(curInputWires)
        })
    concat(outputBundles)
}
/**
 * Perform a map, an operation that applies an operation in parallel to
 * multiple bundles.
 *
 * @param f The operation to apply to each bundle
 * @param incomingWires
 * @param incomingBundleSize The number of wires in each incoming bundle
 * @return An array containing all of the outgoing bundles
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputWires : Array<Wire<V, G>>,
    incomingBundleSize : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let outputWires = Map(
        { inp => [f(inp)] }, inputWires, incomingBundleSize
    )
    FlattenSingleWireOutputs(outputWires)
}
/**
 * Make a map circuit, an operation that applies an operation in parallel to
 * multiple bundles.
 *
 * @param f The operation to apply to each bundle
 * @param incomingBundlePorts The port details for each incoming bundle
 * @param outgoingBundlePorts The port details for each outgoing bundle
 * @param numberOfOperations
 * @param label
 * @return The map circuit
 */
public func MakeMap<V, G, T, U>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    incomingBundlePorts : Array<T>, outgoingBundlePorts : Array<U>,
    numberOfOperations: Int64, label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let inputWires = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, incomingBundlePorts
    )
    let inputBundleWidth = incomingBundlePorts.size / numberOfOperations
    let outputBundleWidth = outgoingBundlePorts.size / numberOfOperations
    let outputWires = Map(f, inputWires, inputBundleWidth)
    let subcircuitInputs = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputWires, incomingBundlePorts
    )
    let subcircuitOutputs = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName()) },
        outputWires, outgoingBundlePorts
    )
    MakeSubcircuit(subcircuitInputs, subcircuitOutputs, label)
}
/**
 * Get an array of all the incoming or outgoing ports to a map circuit
 *
 * @param numberOfOperations
 * @param portDetails An array containing port-like objects
 * @return The array of map ports
 */
func GetMapPorts<V, G, T>(
    numberOfOperations : Int64, portDetails : Array<T>
) : Array<Port>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    Array<Port>(portDetails.size * numberOfOperations, { i =>
        let portVertex = portDetails[i % numberOfOperations]
        Port(portVertex.GetWidth(), name: portVertex.GetName())
    })
}
/**
 * Make a map circuit, an operation that applies an operation in parallel to
 * multiple bundles.
 *
 * @param f The circuit to apply to each bundle
 * @param numberOfOperations
 * @return The map circuit
 */
public func MakeMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputPorts = GetMapPorts<V, G, InterfaceVertex<V, G>>(
        numberOfOperations, f.GetInputs()
    )
    let outputPorts = GetMapPorts<V, G, InterfaceVertex<V, G>>(
        numberOfOperations, f.GetOutputs()
    )
    let spec = Specification(
        "${f.GetName()}^${numberOfOperations}", inputPorts, outputPorts
    )
    MakeMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws)}, inputPorts,
        outputPorts, numberOfOperations, Label<V, G>.COMPOSITE(spec)
    )
}