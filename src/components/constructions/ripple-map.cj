package components.constructions
/*******************************************************************************
 * Ripple(map)s can be performed from TOP_TO_BOTTOM or BOTTOM_TO_TOP.          *
 * The conventions for the interfaces are as follows.                          *
 *                                                                             *
 * For TOP_TO_BOTTOM:                                                          *
 *                                                                             *
 *   operation (ACC, INPUT) -> (OUTPUT, ACC)                                   *
 *                                                                             *
 *   inputs  [ ACC, INPUT[0], INPUT[1], ... , INPUT[n-2], INPUT[n-1] ]         *
 *   outputs [ OUTPUT[0], OUTPUT[1], ... , OUTPUT[n-2], OUTPUT[n-1], ACC ]     *
 *                                                                             *
 * For BOTTOM_TO_TOP:                                                          *
 *                                                                             *
 *   operation (INPUT, ACC) -> (ACC, OUTPUT)                                   *
 *                                                                             *
 *   inputs [ INPUT[n-1], INPUT[n-2], ... , INPUT[1], INPUT[0], ACC ]          *
 *   outputs [ ACC, OUTPUT[n-1], OUTPUT[n-2], ... , OUTPUT[1], OUTPUT[0] ]     *
 *                                                                             *
 *                                                                             *
 ******************************************************************************/
public enum Direction {
    | TOP_TO_BOTTOM
    | BOTTOM_TO_TOP
}
/**
 * Get parameters related to the positions of bundles in ripple maps.
 *
 * @param direction
 * @return A tuple (accumulator first in inputs, accumulator first in outputs)
 */
func GetRippleBundlePositions(direction : Direction) : (Bool, Bool) {
   match(direction) {
        case TOP_TO_BOTTOM => (true, false)
        case BOTTOM_TO_TOP => (false, true)
    }
}
/**
 * Given arrays of accumulator and current wires, concat them depending on the
 * ripple direction.
 *
 * @param direction
 * @param acc
 * @param cur
 * @return The concatenated array of acc and cur arrays
 */
func ConcatAccInputBundles<V, G>(
    direction : Direction, acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>>
) : Array<Wire<V, G>> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let (accFirstInputs, _) = GetRippleBundlePositions(direction)
    let (first, second) = if(accFirstInputs) {
        (acc, cur)
    } else {
        (cur, acc)
    }
    concat(first, second)
}
/**
 * Get the start and end indices of the accumulator bundle in some larger input
 * wire array.
 *
 * @param direction
 * @param accWireBundleSize
 * @param totalInputWires
 * @return A tuple of start and end indices of the accumulator bundle
 */
func GetInputAccumulatorIndices(
    direction : Direction, accWireBundleSize : Int64, totalInputWires : Int64
) : (Int64, Int64) {
    let start = match(direction) {
        case TOP_TO_BOTTOM => 0
        case BOTTOM_TO_TOP => totalInputWires - accWireBundleSize
    }
    (start, start + accWireBundleSize)
}
/**
 * Get the start and end indices of the input bundle with a certin index in some
 * larger input wire array.
 *
 * @param direction
 * @param accWireBundleSize
 * @param totalInputWires
 * @return A tuple of start and end indices of the accumulator bundle
 */
func GetInputIndices(
    direction : Direction, index : Int64, accWireBundleSize : Int64,
    inputWireBundleSize : Int64, totalInputWires : Int64
) : (Int64, Int64) {
    let start = match(direction) {
        case TOP_TO_BOTTOM =>
            accWireBundleSize + (index * inputWireBundleSize)
        case BOTTOM_TO_TOP =>
            totalInputWires - accWireBundleSize -
                ((index+1) * inputWireBundleSize)
    }
    (start, start + inputWireBundleSize)
}
/**
 * Add a bundle to a list of output wires based on the direction.
 *
 * @param direction
 * @param list
 * @param bundle
 */
func AddNextBundle<V, G>(
    direction : Direction, list : ArrayList<Wire<V, G>>,
    bundle : Array<Wire<V, G>>
) where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    match(direction) {
        case TOP_TO_BOTTOM => list.appendAll(bundle)
        case BOTTOM_TO_TOP => list.prependAll(bundle)
    }
}
/**
 * Perform a ripple map.
 *
 * @param f (acc array, in array) -> (acc array, out array)
 * @param inputWires
 * @param accWireBundleSize
 * @param inputWireBundleSize
 * @param direction
 * @param start
 * @param end
 * @return outputWires
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputWires : Array<Wire<V, G>>,
    accWireBundleSize : Int64,
    inputWireBundleSize : Int64,
    outputBundleWidth : Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputWires.size - accWireBundleSize) / inputWireBundleSize
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Check that the input wires are of the form [acc, input, ... , input]
    let numberOfInputBundles =
        (inputWires.size - accWireBundleSize / inputWireBundleSize)
    AssertHasLength(
        inputWires,
        accWireBundleSize + (inputWireBundleSize * numberOfInputBundles)
    )
    let totalInputWires = inputWires.size
    let totalOutputWires =
        (outputBundleWidth * numberOfInputBundles) + accWireBundleSize
    let (accStart, accEnd) =
        GetInputAccumulatorIndices(direction, accWireBundleSize, totalInputWires)
    // Initialise the accumulator with the wires from the inputs
    var curAcc = inputWires.sliceArray(start: accStart, end: accEnd)
    // Initialise the output wires with the correct length
    let outputWires = ArrayList<Wire<V, G>>(totalOutputWires)
    // Perform the ripple
    for(i in start..end) {
        // Identify where the current input bundle starts
        let (curInputStart, curInputEnd) =
            GetInputIndices(
                direction, i, accWireBundleSize,
                inputWireBundleSize, totalInputWires
            )
        // Extract the current input bundle
        println(inputWires)
        let curIn = inputWires.sliceArray(start: curInputStart, end: curInputEnd)
        // Perform the operation
        let (newAcc, newOut) = f(curAcc, curIn)
        // Add the outputs to the output wires
        AddNextBundle(direction, outputWires, newOut)
        // Update the accumulator
        curAcc = newAcc
    }
    // Add the final accumulator to the output wires
    AddNextBundle(direction, outputWires, curAcc)
    // Return an array rather than an arraylist
    outputWires.toArray()
}
/**
 * Perform a ripple map.
 *
 * @param f (acc wire, cur wire) -> (acc wire, cur wire)
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
 * Make a ripple map circuit for a given function from wires to wires.
 *
 * @param f
 * @param allInputPorts The input ports for the completed circuit
 * @param allInputPorts The output ports for the completed circuit
 * @param accWireBundleSize
 * @param inputWireBundleSize
 * @param outputWireBundleSize
 * @param label The label for the completed circuit
 * @param direction The direction to ripple map
 * @return The subcircuit containing a ripple map
 */
func MakeRippleMap<V, G, T, U, W>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    allInputPorts : Array<T>,
    allOutputPorts : Array<U>,
    accWireBundleSize : Int64,
    inputWireBundleSize : Int64,
    outputWireBundleSize : Int64,
    label : Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort, W <: HasPort
{
    // Get the position of the accumulator and data bundles
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    // Create actual input wires based on the specified ports
    let inputWires = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, allInputPorts
    )
    println(inputWires)
    // Perform the ripple map and get the actual output wires
    let rippleMapWires = RippleMap(
        f, inputWires, accWireBundleSize, inputWireBundleSize,
        outputWireBundleSize, direction: direction
    )
    // Add interface information to the input wires based on the input ports
    let inputInterfaceWires = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputWires, allInputPorts
    )
    // Add interface information to the output wires based on the input ports
    let outputInterfaceWires = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName())},
        rippleMapWires, allOutputPorts
    )
    // Make the subcircuit
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
 * @param getVertex
 *           The function (index) -> T that gets the ith element of the
 *           appropriate interface
 * @return An array of elements that form the desired bundle
 */
func GetBundleArray<T>(
    direction : Direction,
    totalNumberOfWires : Int64,
    numberOfAccWires : Int64,
    isInput : Bool,
    isAccBundle : Bool,
    getVertex : (Int64) -> T
) : Array<T> where T <: HasWidth & HasOptionalName {
    let numberOfInputWires = totalNumberOfWires - numberOfAccWires
    let (accFirstInput, accFirstOutput) = GetRippleBundlePositions(direction)
    let length = if(isAccBundle) {
        numberOfAccWires
    } else {
        numberOfInputWires
    }
    let accFirst = if(isInput) { accFirstInput } else { accFirstOutput }
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
 * Get the port for an accumulator wire in a ripple map.
 *
 * @param t The port-like object
 * @return The port for the accumulator wire
 */
func GetAccWirePort<T>(t : T) : Port where T <: HasPort {
    t.ToPort()
}
/**
 * Get the port for an input or output wire in a ripple map.
 *
 * @param t The port-like object
 * @param index The index of the ripple iteration this port is for
 * @return The port for the accumulator wire
 */
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
 * @return An array of ports for the inputs or outputs of a ripple map
 */
func GetRippleMapPorts<T, U>(
    opPorts : Array<T>,
    accFirst : Bool,
    accWireBundleSize : Int64,
    numberOfOperations : Int64
) : Array<Port> where T <: HasPort, U <: HasPort {
    let totalWiresPerOp = opPorts.size
    let dataWireBundleSize = totalWiresPerOp - accWireBundleSize
    let totalDataWires = dataWireBundleSize * numberOfOperations
    let totalWires = totalDataWires + accWireBundleSize
    map(
        { i : Int64 =>
            if(accFirst) {
                if(i < accWireBundleSize) {
                    let port = opPorts[i]
                    GetAccWirePort(port)
                } else {
                    let dataWireIndex =
                        ((i - accWireBundleSize) % dataWireBundleSize) +
                            accWireBundleSize
                    let port = opPorts[dataWireIndex]
                    let iteration = (i - accWireBundleSize) / dataWireBundleSize
                    GetOtherWirePort(port, iteration)
                }
            } else {
                if(i < totalDataWires) {
                    let port = opPorts[i % dataWireBundleSize]
                    let iteration = i / dataWireBundleSize
                    GetOtherWirePort(port, iteration)
                } else {
                    let accWireIndex =
                        (i - totalDataWires) % accWireBundleSize +
                            dataWireBundleSize
                    let port = opPorts[accWireIndex]
                    GetAccWirePort(port)
                }
            }
        },
        start: 0, end: totalWires
    )
}
/**
 * Make a ripple map circuit for a given subcircuit.
 *
 * @param f
 * @param accWireBundleSize
 *          The number of wires that make up the accumulator bundle that is
 *          threaded through the ripple. Must be smaller than the arity and
 *          coarity of f
 * @param numberOfOperations
 *          The number of times to apply the subcircuit in the ripple
 * @param name
 *          An optional name to give the completed circuit
 * @param direction
 *          The direction to ripple. If TOP_TO_BOTTOM, the accumulator bundle is
 *          assumed to be at the top of the inputs and bottom of the outputs;
 *          vice versa if BOTTOM_TO_TOP
 * @return A subcircuit containing a ripple map cirucit.
 */
public func MakeRippleMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    accWireBundleSize : Int64,
    numberOfOperations : Int64,
    name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAtMost(accWireBundleSize, f.GetArity())
    // Whether the accumulator wires should come first or last in the
    // input or output ports
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    let op = {
        acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let inputs = ConcatAccInputBundles(direction, acc, cur)
            let subcircuit = UseSubcircuit(f, inputs)
            let outputsSplitPoint = if(outputAccFirst) {
                accWireBundleSize
            } else {
                f.GetCoarity() - accWireBundleSize
            }
            let (first, second) = subcircuit.partition(outputsSplitPoint)
            if(outputAccFirst) {
                (first, second)
            } else {
                (second, first)
            }
    }
    // Get ports describing the inputs to the ripple map subcircuit
    let inputPorts = GetRippleMapPorts(
        f.GetInputs(), inputAccFirst, accWireBundleSize, numberOfOperations
    )
    // Get ports describing the outputs to the ripple map subcircuit
    let outputPorts = GetRippleMapPorts(
        f.GetOutputs(), outputAccFirst, accWireBundleSize, numberOfOperations
    )
    // Use the ports in the specification of the ripple map label
    let circuitLabel = match(name) {
        case Some(s) => s
        case None => "${f.GetName()}^${numberOfOperations}"
    }
    // Create the label specification for the ripple map subcircuit
    let spec = Specification(circuitLabel, inputPorts, outputPorts)
    MakeRippleMap(
        op, inputPorts, outputPorts, accWireBundleSize,
        f.GetArity() - accWireBundleSize, f.GetCoarity() - accWireBundleSize,
        Label<V, G>.COMPOSITE(spec), direction: direction
    )
}