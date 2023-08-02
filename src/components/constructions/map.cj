package components.constructions

/**
 * Given an array of arrays of wires, apply an operation that transforms an
 * array of wires into a new array of wires, to each array of wires in the
 * input.
 *
 * @param f The operation to apply
 * @param inputss The array of arrays of wires
* @return The output array of arrays of wires
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>,
    inputBundleWidth : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let numberOfOperations = inputWires.size / inputBundleWidth
    let outputBundles =
        Array<Array<Wire<V, G>>>(numberOfOperations, {
            i =>
                let curInputWires = inputWires.slice(
                    i * inputBundleWidth, inputBundleWidth
                )
                f(curInputWires)
        })
    concat(outputBundles)

}
/**
 * Make a map circuit for an operation.
 *
 * @param f The operation
 * @param n The number of times to map
 * @param wires The widths of the expected input wires
 * @param label The label to give the new subcircuit
 */
public func MakeMap<V, G, T, U>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputPorts : Array<T>, outputPorts : Array<U>,
    numberOfOperations: Int64, label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let inputWires = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, inputPorts
    )
    let inputBundleWidth = inputPorts.size / numberOfOperations
    let outputBundleWidth = outputPorts.size / numberOfOperations
    let outputWires = Map(f, inputWires, inputBundleWidth)
    let subcircuitInputs = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputWires, inputPorts
    )
    let subcircuitOutputs = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName()) },
        outputWires, outputPorts
    )
    MakeSubcircuit(subcircuitInputs, subcircuitOutputs, label)
}
func GetPorts<V, G>(
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
 * Make a map subcircuit for a given subcircuit.
 *
 * @param f The subcircuit to map
 * @param n The number of times to map
 * @param label The label to give the new subcircuit
 */
public func MakeMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputPorts = GetPorts(
        f.GetArity(), numberOfOperations, { i : Int64 => f.GetInput(i)}
    )
    let outputPorts = GetPorts(
        f.GetCoarity(), numberOfOperations, { i : Int64 => f.GetOutput(i)}
    )
    let spec = Specification(
        "${f.GetName()}^${numberOfOperations}", inputPorts, outputPorts
    )
    MakeMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws)}, inputPorts,
        outputPorts, numberOfOperations, Label<V, G>.COMPOSITE(spec)
    )
}
/**
 * Given an array of arrays of wires, apply an operation that transforms an
 * array of wires into a new wire, to each array of wires in the input.
 *
 * @param f The operation to apply
 * @param inputss The array of arrays of wires
 * @return The output array of wires
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    inputBundleWidth : Int64
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let outputWires = Map(
        GeneraliseSingleOutputFunction(f), inputs,
        inputBundleWidth
    )
    FlattenSingleWireOutputs(outputWires)
}