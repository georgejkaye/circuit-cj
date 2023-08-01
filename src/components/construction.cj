/**
 * components/construction
 *
 * Functions for constructing 'higher-order circuits' using the functional
 * paradigms of map and fold.
 *
 * @author George Kaye
 * @since 0.2
 */
package components
from std import collection.ArrayList
/**
 * Directions that a ripple can be applied.
 */
public enum Direction {
    | TOP_TO_BOTTOM
    | BOTTOM_TO_TOP
}
/**
 * Given a function that transforms arrays of wires into a single wire,
 * generalise it so that it produces an array of wires instead, by wrapping the
 * outputs into an array
 *
 * @param f The function to generalise
 * @return The generalised function
 */
func GeneraliseSingleOutputFunction<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>
) : (Array<Wire<V, G>>) -> Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    { inputs : Array<Wire<V, G>> => [f(inputs)] }
}
/**
 * Given an array of arrays of wires, which are assumed to each contain one
 * element, flatten it into an array of wires, where each element is the zeroth
 * element of the original array elements.
 *
 * @param inputss The array of arrays of wires
 * @return The flattened array
 */
func FlattenSingleWireOutputs<V, G>(
    inputss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    map({ inputs : Array<Wire<V, G>> => inputs[0] }, inputss)
}
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
 * Perform a ripple map.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param inputWires
 * @param accBundleWidth
 * @param inputBundleWidth
 * @param direction
 * @param start
 * @param end
 * @return outputWires
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputWires : Array<Wire<V, G>>,
    accBundleWidth : Int64,
    inputBundleWidth : Int64,
    outputBundleWidth : Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputWires.size - accBundleWidth) / inputBundleWidth
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let numberOfInputBundles =
        (inputWires.size - accBundleWidth / inputBundleWidth)
    let totalInputWires =
        (inputBundleWidth * numberOfInputBundles) + accBundleWidth
    let totalOutputWires =
        (outputBundleWidth * numberOfInputBundles) + accBundleWidth
    AssertHasLength(
        inputWires, accBundleWidth + (inputBundleWidth * numberOfInputBundles)
    )
    let (accStart, accEnd, addNextBundle) = match(direction) {
        case TOP_TO_BOTTOM =>
            (0, accBundleWidth,
                { list : ArrayList<Wire<V, G>>, bundle : Array<Wire<V, G>> =>
                    list.appendAll(bundle)
                }
            )
        case BOTTOM_TO_TOP =>
            (inputWires.size - accBundleWidth, inputWires.size,
                { list : ArrayList<Wire<V, G>>, bundle : Array<Wire<V, G>> =>
                    list.prependAll(bundle)
                }
            )
    }
    var curAcc = inputWires.sliceArray(start: accStart, end: accEnd)
    let outputWires = ArrayList<Wire<V, G>>(totalOutputWires)
    for(i in start..end) {
        let curInputStart = match(direction) {
            case TOP_TO_BOTTOM =>
                accBundleWidth + (i * inputBundleWidth)
            case BOTTOM_TO_TOP =>
                inputWires.size - accBundleWidth - ((i+1) * inputBundleWidth)
        }
        let curInputEnd = curInputStart + inputBundleWidth
        let curIn = inputWires.sliceArray(start: curInputStart, end: curInputEnd)
        let (newOut, newAcc) = f(curAcc, curIn)
        addNextBundle(outputWires, newOut)
        curAcc = newAcc
    }
    addNextBundle(outputWires, curAcc)
    outputWires.toArray()
}
/**
 * Perform a ripple map.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputWires
 * @param direction
 * @param start
 * @param end
 * @return outputs array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    inputWires : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputWires.size - 1
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newCur) = f(acc[0], cur[0])
            ([newOut], [newCur])
        }
    RippleMap(
        fAdjusted, inputWires, 1, 1, 1, direction: direction,
        start: start, end: end
    )
}
/**
 * Perform a ripple map, with the first input wire as the start wire for the
 * accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputWires
 * @param inputBundleWidth
 * @param outputBundleWidth
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc array
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputWires : Array<Wire<V, G>>,
    inputBundleWidth : Int64,
    outputBundleWidth : Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputWires.size / inputBundleWidth
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RippleMap(
        f, inputWires, inputBundleWidth, inputBundleWidth, outputBundleWidth,
        direction: direction, start: start + 1, end: end
    )
}
func MakeRippleMap<V, G, T, U, W>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputPorts : Array<T>,
    outputPorts : Array<U>,
    accBundleWidth : Int64,
    inputBundleWidth : Int64,
    outputBundleWidth : Int64,
    label : Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort, W <: HasPort
{
    let (inputAccFirst, outputAccFirst) = match(direction) {
        case TOP_TO_BOTTOM => (true, false)
        case BOTTOM_TO_TOP => (false, true)
    }
    let inputWires = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, inputPorts
    )
    let rippleMapWires = RippleMap(
        f, inputWires, accBundleWidth, inputBundleWidth,
        outputBundleWidth, direction: direction
    )
    let inputInterfaceWires = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputWires, inputPorts
    )
    let outputInterfaceWires = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName())},
        rippleMapWires, outputPorts
    )
    MakeSubcircuit(inputInterfaceWires, outputInterfaceWires, label)

}
/**
 * Get an array of widths of elements in the interface of a subcircuit that
 * belong to either the accumulator or input/output bundle.
 *
 * @param totalNumberOfWires
 * @param numberOfAccWires
 * @param inputAccFirst
 * @param isAccBundle
 * @param getVertex The function (index) -> T that gets the ith element of the
 *                  appropriate interface
 * @return An array of elements that form the desired bundle
 */
func GetBundleArray<T>(
    totalNumberOfWires : Int64,
    numberOfAccWires : Int64,
    accFirst : Bool,
    isAccBundle : Bool,
    getVertex : (Int64) -> T
) : Array<T> where T <: HasWidth & HasOptionalName {
    let numberOfInputWires = totalNumberOfWires - numberOfAccWires
    let length = if(isAccBundle) {
        numberOfAccWires
    } else {
        numberOfInputWires
    }
    Array<T>(length, { i =>
        // The desired index might be offset by the accumulator
        let index = if(accFirst) {
            // The other wires are offset by the accumulator bundle
            if(isAccBundle) { i } else { i + numberOfAccWires }
        } else {
            // The accumulator wires are offset by the other bundle
            if(isAccBundle) { i + numberOfInputWires } else { i }
        }
        getVertex(index)
    })
}
/**
 * Get the port array for either the inputs of outputs of a ripple map.
 *
 * @param accFirst
 *          Whether the accumulator wires come before the remaining wires
 * @param accWiresPerOp
 *          The number of wires that make up the accumulator bundle
 * @param totalWiresPerOp
 *          The total number of wires the make up the interface
 * @param getAccVertex
 *          Function (index, numberOfAccWires, numberOfOtherWires) -> vertex
 *          that returns the indexth accumulator interface vertex of f
 * @param getOtherVertex
 *          Function (index, numberOfAccWires, numberOfOtherWires) -> vertex
 *          that returns the indexth other vertex of f
 */
func GetPorts<T, U>(
    accFirst : Bool,
    accWiresPerOp : Int64,
    totalWiresPerOp : Int64,
    numberOfOperations : Int64,
    accWidthsAndNames : Array<T>,
    otherWidthsAndNames : Array<U>
) : Array<Port>
    where T <: HasPort, U <: HasPort
{
    let otherWiresPerOp = totalWiresPerOp - accWiresPerOp
    let totalOtherWires = otherWiresPerOp * numberOfOperations
    Array<Port>(
        accWiresPerOp + totalOtherWires,
        { i =>
            if(accFirst) {
                if(i < accWiresPerOp) {
                    accWidthsAndNames[i].ToPort()
                } else {
                    let iOffset = i - accWiresPerOp
                    otherWidthsAndNames[iOffset % otherWiresPerOp].ToPort()
                }
            } else {
                if(i < totalOtherWires) {
                    otherWidthsAndNames[i % otherWiresPerOp].ToPort()
                } else {
                    accWidthsAndNames[i - totalOtherWires].ToPort()
                }
            }
        }
    )
}
public func MakeRippleMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfAccWires : Int64,
    numberOfOperations : Int64,
    name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAtMost(numberOfAccWires, f.GetArity())
    // Whether the accumulator wires should come first or last in the
    // input or output ports
    let (inputAccFirst, outputAccFirst) = match(direction) {
        case TOP_TO_BOTTOM => (true, false)
        case BOTTOM_TO_TOP => (false, true)
    }
    let op = {
        first : Array<Wire<V, G>>, second : Array<Wire<V, G>> =>
            let inputs = concat(first, second)
            let subcircuit = UseSubcircuit(f, inputs)
            let outputsSplitPoint = if(outputAccFirst) {
                numberOfAccWires
            } else {
                f.GetCoarity() - numberOfAccWires
            }
            subcircuit.partition(outputsSplitPoint)
    }
    // Get an array of the widths of wires in the accumulator bundle
    let accWidths = GetBundleArray(
        f.GetArity(), numberOfAccWires, inputAccFirst, true,
        { i : Int64 => f.GetInput(i) }
    )
    // Get an array of the widths of wires in the input bundle
    let inputWidths = GetBundleArray(
        f.GetArity(), numberOfAccWires, inputAccFirst, false,
        { i : Int64 => f.GetInput(i) }
    )
    // Get an array of the widths of wires in the output bundle
    let outputWidths = GetBundleArray(
        f.GetCoarity(), numberOfAccWires, outputAccFirst, false,
        { i : Int64 => f.GetOutput(i) }
    )
    // Get ports describing the inputs to the ripple map subcircuit
    let inputPorts = GetPorts(
        inputAccFirst, numberOfAccWires, f.GetArity(), numberOfOperations,
        accWidths, inputWidths
    )
    // Get ports describing the outputs to the ripple map subcircuit
    let outputPorts = GetPorts(
        outputAccFirst, numberOfAccWires, f.GetCoarity(), numberOfOperations,
        accWidths, outputWidths
    )
    // Use the ports in the specification of the ripple map label
    let circuitLabel = match(name) {
        case Some(s) => s
        case None => "${f.GetName()}^${numberOfOperations}"
    }
    // Create the label specification for the ripple map subcircuit
    let spec = Specification(circuitLabel, inputPorts, outputPorts)
    MakeRippleMap(
        op, inputPorts, outputPorts, numberOfAccWires,
        f.GetArity() - numberOfAccWires, f.GetCoarity() - numberOfAccWires,
        Label<V, G>.COMPOSITE(spec), direction: direction
    )

}
/**
 * Perform a ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial array
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return acc wire
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>,
    accBundleWidth: Int64,
    inputBundleWidth: Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputWires.size - accBundleWidth) / inputBundleWidth
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc, cur)
            (Array<Wire<V, G>>(), curAcc)
        }
    RippleMap(
        function, inputWires, accBundleWidth, inputBundleWidth,
        0, direction: direction, start: start, end: end
    )
}
/**
 * Perform a ripple.
 *
 * @param f (acc wire, cur array) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc wire
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    inputWires : Array<Wire<V, G>>,
    accBundleWidth: Int64,
    inputBundleWidth: Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputWires.size - accBundleWidth) / inputBundleWidth
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let rippleFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc[0], cur)
            [curAcc]
        }
    Ripple(
        rippleFunction, inputWires, accBundleWidth, inputBundleWidth,
        direction: direction, start: start, end: end
    )[0]
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
 * Make a circuit that ripples a given primitive over some inputs, i.e. the
 * primitive will be applied to each input wire one at a time in succession
 *
 * @param prim The primitive to apply
 * @param n The number of input wires
 * @param w The width of the input wires
 * @return The ripple gate circuit
 */
public func MakeRippleGate<V, G>(
    prim : G, n : Int64, w : Int64, delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // let inputWires = Array<Array<Wire<V, G>>>(n, {
    //     i : Int64 => [UseWire<V, G>(w)]
    // })
    // let output = Ripple<V, G>(
    //     { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
    //         UseGate(prim, [acc[0], cur[0]], delay: delay)
    //     },
    //     inputWires, 1, 1
    // )[0]
    // MakeSubcircuit(
    //     mapi(
    //         {inputs : Array<Wire<V, G>>, i : Int64 =>
    //             InterfaceWire(inputs[0], numToUppercaseLetter(i))
    //         },
    //         inputs
    //     ),
    //     [InterfaceWire(output, "Z")],
    //     COMPOSITE(
    //         Specification(
    //             "${prim.GetName()}_${n}_${w}",
    //             Array<Port>(n, { i => Port(w, numToUppercaseLetter(i)) }),
    //             [Port(w)]
    //         )
    //     )
    // )
    throw Exception("to do")
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