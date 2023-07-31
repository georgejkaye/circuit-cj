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
    inputss : Array<Array<Wire<V, G>>>
) : Array<Array<Wire<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertArrayArraysSameWidths(inputss)
    map({inputs : Array<Wire<V, G>> => f(inputs)}, inputss)
}
/**
 * Make a subcircuit containing an operation mapped a given number of times.
 *
 * @param f The operation
 * @param n The number of times to map
 * @param wires The widths of the expected input wires
 * @param label The label to give the new subcircuit
 */
public func MakeMap<V, G, T>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    n : Int64, wires : Array<T>,
    label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasWidth
{
    let inputs = Array<Array<Wire<V, G>>>(n, {i =>
        map({ t => UseWire<V, G>(t.GetWidth())}, wires)
    })
    let outputs = Map(f, inputs)
    let subcircuitInputs =
        concat(inputs, { w : Wire<V, G> => InterfaceWire(w) })
    let subcircuitOutputs =
        concat(outputs, { w : Wire<V, G> => InterfaceWire(w) })
    MakeSubcircuit<V, G>(
        subcircuitInputs, subcircuitOutputs, label
    )
}
/**
 * Make a subcircuit containing an subcircuit mapped a given number of times.
 *
 * @param f The subcircuit to map
 * @param n The number of times to map
 * @param label The label to give the new subcircuit
 */
public func MakeMap<V, G>(f : InterfacedHypergraph<V, G>, n : Int64)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func GetPorts(
        getNumberOfPorts : (InterfacedHypergraph<V, G>) -> Int64,
        getVertex : (InterfacedHypergraph<V, G>, Int64) -> InterfaceVertex<V, G>
    ) : Array<Port> {
        let numberOfPorts = getNumberOfPorts(f)
        Array<Port>(numberOfPorts * n, { i =>
            let portVertex = getVertex(f, i % numberOfPorts)
            Port(portVertex.GetWidth(), name: portVertex.GetName())
        })
    }
    let inputPorts = GetPorts(
        { f => f.GetArity() }, { f, i => f.GetInput(i)}
    )
    let outputPorts = GetPorts(
        { f => f.GetCoarity() }, { f, i => f.GetOutput(i)}
    )
    let spec = Specification(
        "${f.GetName()}^${n}", inputPorts, outputPorts
    )
    MakeMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws)},
        n, f.GetInputPorts(), Label<V, G>.COMPOSITE(spec)
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
    inputss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let outputWires = Map(GeneraliseSingleOutputFunction(f), inputss)
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
) : Array<Array<Wire<V, G>>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputs)
    let splitInputs = map({ w : Wire<V, G> => Split(w) }, inputs)
    Array<Array<Wire<V, G>>>(width){ i : Int64 =>
        Array<Wire<V, G>>(inputs.size){ j : Int64 => splitInputs[j][i] }
    }
}
/**
 * Given an array of arrays of wires, combine them to create an array of wires,
 * so that outputs[i] = [inputs[0][i], inputs[1][i], ...].
 *
 * @param inputs The array of arrays of wires to combine
 * @return The array of combined wires
 */
public func BitwiseCombine<V, G>(
    inputs : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let size = AssertAllSameLength(inputs)
    Array<Wire<V, G>>(size, {
        i : Int64 => Combine(Array<Wire<V, G>>(inputs.size){
            j : Int64 => inputs[j][i]
        })
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
    inputs : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>,  G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    let outputWires = Map(f, inputWires)
    BitwiseCombine(outputWires)
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
    inputs : Array<Wire<V, G>>
) : Wire<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    BitwiseMap({ inputs : Array<Wire<V, G>> => [f(inputs)] }, inputs)[0]
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
    input : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    BitwiseMap({ inputs : Array<Wire<V, G>> => [f(inputs[0])] }, [input])[0]
}
public func MakeBitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    n : Int64, wires: Int64, label: Label<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputs = Array<Wire<V, G>>(wires, {i => UseWire<V, G>(n)})
    let outputs = BitwiseMap(f, inputs)
    let inputWires = map({ w : Wire<V, G> => InterfaceWire(w) }, inputs)
    let outputWires = map({ w : Wire<V, G> => InterfaceWire(w) }, outputs)
    MakeSubcircuit(inputWires, outputWires, label)
}
public func MakeBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    n : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func GetPorts(
        getNumberOfPorts : (InterfacedHypergraph<V, G>) -> Int64,
        getVertex : (InterfacedHypergraph<V, G>, Int64) -> InterfaceVertex<V, G>
    ) : Array<Port> {
        Array<Port>(getNumberOfPorts(f), { i =>
            let portVertex = getVertex(f, i)
            Port(n, name: portVertex.GetName())
        })
    }
    let inputPorts = GetPorts({ f => f.GetArity() }, { f, i => f.GetInput(i) })
    let outputPorts = GetPorts({ f => f.GetCoarity() }, { f, i => f.GetOutput(i) })
    let spec = Specification(
        "${f.GetName()}_${n}", inputPorts, outputPorts
    )
    MakeBitwiseMap({ ws : Array<Wire<V, G>> => UseSubcircuit(f, ws) }, n, f.GetArity(), Label<V, G>.COMPOSITE(spec))
}
/**
 * Perform a ripple map.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc array
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    initial : Array<Wire<V, G>>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertArrayArraysSameWidths(inputs)
    var acc = initial
    let outputs = ArrayList<Array<Wire<V, G>>>()
    for(i in start..end) {
        let j = match(direction) {
            case TOP_TO_BOTTOM => i
            case BOTTOM_TO_TOP => inputs.size - 1 - i
        }
        let cur = inputs[j]
        let (curRes, curAcc) = f(acc, cur)
        match(direction) {
            case TOP_TO_BOTTOM => outputs.append(curRes)
            case BOTTOM_TO_TOP => outputs.prepend(curRes)
        }
        acc = curAcc
    }
    (outputs.toArray(), acc)
}
/**
 * Perform a ripple map.
 *
 * @param f (acc wire, cur array) -> (out array, acc wire)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Wire<V, G>),
    initial : Wire<V, G>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Array<Wire<V, G>>>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let rippleMapFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (curOutput, curAcc) = f(acc[0], cur)
            (curOutput, [curAcc])
        }
    let (outputs, acc) = RippleMap(
        rippleMapFunction, [initial], inputs, direction: direction,
        start: start, end: end
    )
    (outputs, acc[0])
}
/**
 * Perform a ripple map.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Wire<V, G>>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let (finalOut, finalAcc) = RippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newCur) = f(acc[0], cur[0])
            ([newOut], [newCur])
        },
        [initial],
        map({ w : Wire<V, G> => [w] }, initial),
        direction: direction,
        start: start,
        end: end
    )
    (FlattenSingleWireOutputs(finalOut), finalAcc[0])
}
/**
 * Perform a ripple map, with the first input wire as the start wire for the
 * accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc array
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RippleMap(
        f, inputs[start], inputs, direction: direction,
        start: start + 1, end: end
    )
}
/**
 * Perform a ripple map, with the first input wire as the start wire for the
 * accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return outputs array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Wire<V, G>>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (curRes, curAcc) = f(acc[0], cur[0])
            ([curRes], [curAcc])
        }
    let (outputs, acc) = RippleMap<V, G>(
        function, map({ w : Wire<V, G> => [w] }, inputs), direction: direction,
        start: start, end: end
    )
    (FlattenSingleWireOutputs(outputs), acc[0])
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
    initial : Array<Wire<V, G>>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc, cur)
            (Array<Wire<V, G>>(), curAcc)
        }
    let (_, acc) = RippleMap(
        function, initial, inputs, direction: direction,
        start: start, end: end
    )
    acc
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
    initial : Wire<V, G>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let rippleFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc[0], cur)
            [curAcc]
        }
    Ripple(
        rippleFunction, [initial], inputs, direction: direction,
        start: start, end: end
    )[0]
}
/**
 * Perform a ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Ripple(
        f, inputs[start], inputs, direction: direction,
        start: start + 1, end: end
    )
}
/**
 * Perform a ripple.
 *
 * @param f (acc wire, cur wire) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc wire
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let rippleFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur[0])
            [newAcc]
        }
    Ripple<V, G>(
        rippleFunction, map({ w : Wire<V, G> => [w] }, inputs),
        direction: direction, start: start, end: end
    )[0]
}
public func MakeRippleMap<V, G, T, U>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    n : Int64,
    accWidths: Array<T>,
    inputWidths: Array<U>,
    label : Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasWidth, U <: HasWidth
{
    let initialWires = map(
        { t : T => UseWire<V, G>(t.GetWidth())}, accWidths
    )
    let inputWires = Array<Array<Wire<V, G>>>(n, { i =>
        map<U, Wire<V, G>>(
            { u : U => UseWire<V, G>(u.GetWidth())}, inputWidths
        )
    })
    let (outputWires, accWires) =
        RippleMap(
            f, initialWires, inputWires, direction: direction
        )
    let numberOfInputWiresPerOp = inputWidths.size
    let numberOfInputAccWires = accWidths.size
    let numberofInputInputWires = numberOfInputWiresPerOp * n
    let numberOfInputWires = numberOfInputAccWires + numberofInputInputWires
    let subcircuitInputs = Array<InterfaceWire<V, G>>(
        numberOfInputWires, { i =>
            if(i < accWidths.size) {
                InterfaceWire(initialWires[i])
            } else {
                let iAdjusted = i - numberOfInputAccWires
                let inputNumber = iAdjusted / numberOfInputWiresPerOp
                let inputIndex = iAdjusted % numberOfInputWiresPerOp
                InterfaceWire(inputWires[inputNumber][inputIndex])
            }
        }
    )
    let numberOfOutputWiresPerOp = outputWires[0].size
    let numberOfOutputOutputWires = numberOfOutputWiresPerOp * n
    let numberOfOutputAccWires = accWires.size
    let numberOfOutputWires = numberOfOutputOutputWires + numberOfOutputAccWires
    let subcircuitOutputs = Array<InterfaceWire<V, G>>(
        numberOfOutputWires, {i =>
            if( i < numberOfOutputOutputWires){
                let outputNumber = i / numberOfOutputWiresPerOp
                let outputIndex = i % numberOfOutputWiresPerOp
                InterfaceWire(outputWires[outputNumber][outputIndex])
            } else {
                let iAdjusted = i - numberOfOutputOutputWires
                InterfaceWire(accWires[iAdjusted])
            }
        }
    )
    MakeSubcircuit<V, G>(
        subcircuitInputs, subcircuitOutputs, label
    )
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
    let op = {
        first : Array<Wire<V, G>>, second : Array<Wire<V, G>> =>
            let inputs = concat(first, second)
            let subcircuit = UseSubcircuit(f, inputs)
            partition(subcircuit, numberOfAccWires)
    }
    // Whether the accumulator wires should come first or last in the
    // input or output ports
    let (inputAccFirst, outputAccFirst) = match(direction) {
        case TOP_TO_BOTTOM => (true, false)
        case BOTTOM_TO_TOP => (false, true)
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
    MakeRippleMap<V, G, InterfaceVertex<V, G>, InterfaceVertex<V, G>>(
        op, numberOfOperations, accWidths, inputWidths,
        Label<V, G>.COMPOSITE(spec), direction: direction
    )

}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    initial : Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    Ripple(f, initial, inputWires, direction: direction, start: start, end: end)
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc wire, cur array) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    initial : Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur)
            [newAcc]
        }
    BitwiseRipple(function, [initial], inputs, direction: direction)[0]
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = if(inputs.size == 0){ 0 } else { inputs[0].GetWidth() }
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    Ripple(
        f, inputWires[start], inputWires, direction: direction,
        start: start + 1, end: end
    )
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc wire, cur wire) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur[0])
            [newAcc]
        }
    BitwiseRipple(
        function, inputs, direction: direction, start: start, end: end
    )[0]
}
/**
 * Perform a bitwise ripple map.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param initial array
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return (combined outputs array, acc array)
 */
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    initial : Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    let (output, acc) = RippleMap(
        f, initial, inputWires, direction: direction, start: start, end: end
    )
    let combinedOutput = BitwiseCombine(output)
    (combinedOutput, acc)
}
/**
 * Perform a bitwise ripple map.
 *
 * @param f (acc wire, cur array) -> (out wire, acc wire)
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return (combined outputs wire, acc wire)
 */
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs[0].GetWidth()
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newCur, newAcc) = f(acc[0], cur)
            ([newCur], [newAcc])
        }
    let (output, acc) = RippleMap(
        function, [initial], inputWires, direction: direction,
        start: start, end: end)
    let combinedOutput = BitwiseCombine(output)
    (combinedOutput[0], acc[0])
}
/**
 * Perform a bitwise ripple map.
 *
 * @param f (acc, cur) -> (out, acc)
 * @param initial
 * @param inputs
 * @param direction
 * @return The combined outputs and the final accumulator
 */
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    input : Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newAcc) = f(acc[0], cur[0])
            ([newOut], [newAcc])
        }
    let (output, acc) = BitwiseRippleMap(
        function, [initial], [input], direction: direction
    )
    (output[0], acc[0])
}
/**
 * Perform a bitwise ripple map with the first input as the initial value of
 * the accumulator.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param inputs
 * @param direction
 * @return (output array, acc array)
 */
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit(inputs)
    let (output, acc) = RippleMap(
        f, inputWires[0], inputWires, direction: direction, start: 1
    )
    (BitwiseCombine(output), acc)
}
/**
 * Perform a bitwise ripple map with the first input as the initial value of
 * the accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param input
 * @param direction
 * @return (output wire, acc wire)
 */
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    input : Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = BitwiseSplit([input])
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newAcc) = f(acc[0], cur[0])
            ([newOut], [newAcc])
        }
    let (output, acc) = RippleMap(
        function, inputWires[0], inputWires, direction: direction, start: 1
    )
    (BitwiseCombine(output)[0], acc[0])
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
    let inputs = Array<Wire<V, G>>(
        prim.GetArity(),
        {i : Int64 => UseWire<V, G>(w) }
    )
    let output = BitwiseMap(
        { inputs : Array<Wire<V, G>> => UseGate(prim, inputs, delay: delay) },
        inputs
    )[0]
    MakeSubcircuit(
        mapi(
            { w : Wire<V, G>, i : Int64 =>
                InterfaceWire(w, numToUppercaseLetter(i))
            },
            inputs
        ),
        [InterfaceWire(output, "Z")],
        COMPOSITE(
            Specification(
                "${prim.GetName()}_${w}",
                Array<Port>(
                    prim.GetArity(), { i => Port(w, numToUppercaseLetter(i)) }
                ),
                Array<Port>(
                    prim.GetCoarity(), { i => Port(w, numToUppercaseLetter(i)) }
                )
            )
        )
    )
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
    let inputs = Array<Array<Wire<V, G>>>(n, {
        i : Int64 => [UseWire<V, G>(w)]
    })
    let output = Ripple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            UseGate(prim, [acc[0], cur[0]], delay: delay)
        },
        inputs
    )[0]
    MakeSubcircuit(
        mapi(
            {inputs : Array<Wire<V, G>>, i : Int64 =>
                InterfaceWire(inputs[0], numToUppercaseLetter(i))
            },
            inputs
        ),
        [InterfaceWire(output, "Z")],
        COMPOSITE(
            Specification(
                "${prim.GetName()}_${n}_${w}",
                Array<Port>(n, { i => Port(w, numToUppercaseLetter(i)) }),
                [Port(w)]
            )
        )
    )
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
    let input = UseWire<V, G>(w)
    let output = BitwiseRipple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            UseGate(prim, [acc[0], cur[0]], delay: delay)
        },
        [input]
    )[0]
    MakeSubcircuit(
        [InterfaceWire(input, "A")],
        [InterfaceWire(output, "Z")],
        COMPOSITE(
            Specification(
                "${prim.GetName()}_1_${w}",
                [Port(w)], [Port(1)]
            )
        )
    )
}