package components.constructions
/**
 * Directions that a ripple can be applied.
 */
public enum Direction {
    | TOP_TO_BOTTOM
    | BOTTOM_TO_TOP
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
func GetAccWirePort<T>(t : T) : Port where T <: HasPort {
    t.ToPort()
}
func GetOtherWirePort<T>(t : T, index : Int64) : Port where T <: HasPort {
    let name = match(t.GetName()) {
        case Some(s) => "${s}[${index}]"
        case None => None<String>
    }
    Port(t.GetWidth(), name: name)
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
                    GetAccWirePort(accWidthsAndNames[i])
                } else {
                    let iOffset = i - accWiresPerOp
                    let index = iOffset % otherWiresPerOp
                    GetOtherWirePort(otherWidthsAndNames[index], iOffset)
                }
            } else {
                if(i < totalOtherWires) {
                    let index = i % otherWiresPerOp
                    GetOtherWirePort(otherWidthsAndNames[index], i)
                } else {
                    GetAccWirePort(accWidthsAndNames[i - totalOtherWires])
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