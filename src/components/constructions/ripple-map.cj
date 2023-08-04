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
 * @param accBundleSize
 * @param totalinputPorts
 * @return A tuple of start and end indices of the accumulator bundle
 */
func GetInputAccumulatorIndices(
    direction : Direction, accBundleSize : Int64, totalinputPorts : Int64
) : (Int64, Int64) {
    let start = match(direction) {
        case TOP_TO_BOTTOM => 0
        case BOTTOM_TO_TOP => totalinputPorts - accBundleSize
    }
    (start, start + accBundleSize)
}
/**
 * Get the start and end indices of the input bundle with a certin index in some
 * larger input wire array.
 *
 * @param direction
 * @param accBundleSize
 * @param totalinputPorts
 * @return A tuple of start and end indices of the accumulator bundle
 */
func GetInputIndices(
    direction : Direction, index : Int64, accBundleSize : Int64,
    incomingBundleSize : Int64, totalinputPorts : Int64
) : (Int64, Int64) {
    let start = match(direction) {
        case TOP_TO_BOTTOM =>
            accBundleSize + (index * incomingBundleSize)
        case BOTTOM_TO_TOP =>
            totalinputPorts - accBundleSize -
                ((index+1) * incomingBundleSize)
    }
    (start, start + incomingBundleSize)
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
 * Perform a ripple map, an operation that starts with an accumulator bundle and
 * successively apply an operation to the accumulator and a data bundle,
 * creating an outgoing bundle for each operation as well as a new accumulator
 * bundle.
 *
 * @param f (acc bundle, in bundle) -> (acc bundle, out bundle)
 * @param inputPorts
 * @param accBundleSize
 * @param incomingBundleSize
 * @param outgoingBundleSize
 * @param direction
 * @param start
 * @param end
 * @return outputPorts
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputPorts : Array<Wire<V, G>>,
    accBundleSize : Int64,
    incomingBundleSize : Int64,
    outgoingBundleSize : Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputPorts.size - accBundleSize) / incomingBundleSize
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Check that the input wires are of the form [acc, input, ... , input]
    let numberOfInputBundles =
        (inputPorts.size - accBundleSize / incomingBundleSize)
    AssertHasLength(
        inputPorts,
        accBundleSize + (incomingBundleSize * numberOfInputBundles)
    )
    let totalinputPorts = inputPorts.size
    let totaloutputPorts =
        (outgoingBundleSize * numberOfInputBundles) + accBundleSize
    let (accStart, accEnd) =
        GetInputAccumulatorIndices(direction, accBundleSize, totalinputPorts)
    // Initialise the accumulator with the wires from the inputs
    var curAcc = inputPorts.sliceArray(start: accStart, end: accEnd)
    // Initialise the output wires with the correct length
    let outputPorts = ArrayList<Wire<V, G>>(totaloutputPorts)
    // Perform the ripple
    for(i in start..end) {
        // Identify where the current input bundle starts
        let (curInputStart, curInputEnd) =
            GetInputIndices(
                direction, i, accBundleSize,
                incomingBundleSize, totalinputPorts
            )
        // Extract the current input bundle
        let curIn = inputPorts.sliceArray(start: curInputStart, end: curInputEnd)
        // Perform the operation
        let (newAcc, newOut) = f(curAcc, curIn)
        // Add the outputs to the output wires
        AddNextBundle(direction, outputPorts, newOut)
        // Update the accumulator
        curAcc = newAcc
    }
    // Add the final accumulator to the output wires
    AddNextBundle(direction, outputPorts, curAcc)
    // Return an array rather than an arraylist
    outputPorts.toArray()
}
/**
 * Perform a ripple map, an operation that starts with an accumulator bundle and
 * successively apply an operation to the accumulator and a data bundle,
 * creating an outgoing bundle for each operation as well as a new accumulator
 * bundle.
 *
 * @param f (acc wire, in wire) -> (acc wire, out wire)
 * @param inputPorts
 * @param direction
 * @param start
 * @param end
 * @return outputPorts
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    inputPorts : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputPorts.size - 1
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newCur) = f(acc[0], cur[0])
            ([newOut], [newCur])
        }
    RippleMap(
        fAdjusted, inputPorts, 1, 1, 1, direction: direction,
        start: start, end: end
    )
}
/**
 * Make a circuit for a ripple map, an operation that starts with an accumulator
 * bundle and successively apply an operation to the accumulator and a data
 * bundle, creating an outgoing bundle for each operation as well as a new
 * accumulator bundle.
 *
 * @param f (acc bundle, in bundle) -> (acc bundle, out bundle)
 * @param allInputPorts The input port details of the completed circuit
 * @param allOutputPorts The output port details of the completed circuit
 * @param accBundleSize The number of wires in the accumulator bundle
 * @param incomingBundleSize The number of wires in each incoming bundle
 * @param outgoingBundleSize The number of wires in each outgoing bundle
 * @param direction
 * @param start
 * @param end
 * @return The ripple map circuit
 */
func MakeRippleMap<V, G, T, U>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    allInputPorts : Array<T>,
    allOutputPorts : Array<U>,
    accBundleSize : Int64,
    incomingBundleSize : Int64,
    outputWireBundleSize : Int64,
    label : Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    // Get the position of the accumulator and data bundles
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    // Create actual input wires based on the specified ports
    let inputPorts = map(
        { t : T => UseWire<V, G>(t.GetWidth()) }, allInputPorts
    )
    // Perform the ripple map and get the actual output wires
    let rippleMapWires = RippleMap(
        f, inputPorts, accBundleSize, incomingBundleSize,
        outputWireBundleSize, direction: direction
    )
    // Add interface information to the input wires based on the input ports
    let inputInterfaceWires = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputPorts, allInputPorts
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
 * Make a circuit for a ripple map, an operation that starts with an accumulator
 * bundle and successively apply an operation to the accumulator and a data
 * bundle, creating an outgoing bundle for each operation as well as a new
 * accumulator bundle.
 *
 * @param f (acc bundle, in bundle) -> (acc bundle, out bundle)
 * @param accPorts The port details for the accumulator bundle
 * @param incomingPorts The port details for each incoming bundle
 * @param outgoingPorts The port details for each outgoing bundle
 * @param numberOfOperations The
 * @param name
 * @param direction
 * @return The ripple map circuit
 */
public func MakeRippleMap<V, G, T>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
        (Array<Wire<V, G>>, Array<Wire<V, G>>),
    accPorts : Array<T>,
    incomingPorts : Array<T>,
    outgoingPorts : Array<T>,
    numberOfOperations : Int64,
    name: String,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    let (inputFirst, inputSecond) = if(inputAccFirst) {
        (accPorts, incomingPorts)
    } else {
        (incomingPorts, accPorts)
    }
    let allInputPorts = GetRippleMapPorts(
        concat(inputFirst, inputSecond), inputAccFirst, accPorts.size,
        numberOfOperations
    )
    let (outputFirst, outputSecond) = if(outputAccFirst) {
        (accPorts, outgoingPorts)
    } else {
        (outgoingPorts, accPorts)
    }
    let allOutputPorts = GetRippleMapPorts(
        concat(outputFirst, outputSecond), outputAccFirst, accPorts.size,
        numberOfOperations
    )
    let spec = Specification(name, allInputPorts, allOutputPorts)
    let label = Label<V, G>.COMPOSITE(spec)
    MakeRippleMap(
        f, allInputPorts, allOutputPorts, accPorts.size, incomingPorts.size,
        outgoingPorts.size, label, direction: direction
    )
}
/**
 * Get an array of widths of elements in the interface of a subcircuit that
 * belong to either the accumulator or incoming/outgoing bundle.
 *
 * @param totalNumberOfWires
 * @param numberOfaccPorts
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
    numberOfaccPorts : Int64,
    isInput : Bool,
    isAccBundle : Bool,
    getVertex : (Int64) -> T
) : Array<T> where T <: HasWidth & HasOptionalName {
    let numberOfinputPorts = totalNumberOfWires - numberOfaccPorts
    let (accFirstInput, accFirstOutput) = GetRippleBundlePositions(direction)
    let length = if(isAccBundle) {
        numberOfaccPorts
    } else {
        numberOfinputPorts
    }
    let accFirst = if(isInput) { accFirstInput } else { accFirstOutput }
    Array<T>(length, { i =>
        // The desired index might be offset by the accumulator
        let index = if(accFirst) {
            // The other wires are offset by the accumulator bundle
            if(isAccBundle) { i } else { i + numberOfaccPorts }
        } else {
            // The accumulator wires are offset by the other bundle
            if(isAccBundle) { i + numberOfinputPorts } else { i }
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
 * @param accPortsPerOp
 *          The number of wires that make up the accumulator bundle
 * @param totalWiresPerOp
 *          The total number of wires the make up the interface
 * @param getAccVertex
 *          Function (index, numberOfaccPorts, numberOfOtherWires) -> vertex
 *          that returns the indexth accumulator interface vertex of f
 * @param getOtherVertex
 *          Function (index, numberOfaccPorts, numberOfOtherWires) -> vertex
 *          that returns the indexth other vertex of f
 * @return An array of ports for the inputs or outputs of a ripple map
 */
func GetRippleMapPorts<T, U>(
    opPorts : Array<T>,
    accFirst : Bool,
    accBundleSize : Int64,
    numberOfOperations : Int64
) : Array<Port> where T <: HasPort, U <: HasPort {
    let totalWiresPerOp = opPorts.size
    let dataWireBundleSize = totalWiresPerOp - accBundleSize
    let totalDataWires = dataWireBundleSize * numberOfOperations
    let totalWires = totalDataWires + accBundleSize
    map(
        { i : Int64 =>
            if(accFirst) {
                if(i < accBundleSize) {
                    let port = opPorts[i]
                    GetAccWirePort(port)
                } else {
                    let dataWireIndex =
                        ((i - accBundleSize) % dataWireBundleSize) +
                            accBundleSize
                    let port = opPorts[dataWireIndex]
                    let iteration = (i - accBundleSize) / dataWireBundleSize
                    GetOtherWirePort(port, iteration)
                }
            } else {
                if(i < totalDataWires) {
                    let port = opPorts[i % dataWireBundleSize]
                    let iteration = i / dataWireBundleSize
                    GetOtherWirePort(port, iteration)
                } else {
                    let accWireIndex =
                        (i - totalDataWires) % accBundleSize +
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
 * Make a circuit for a ripple map, an operation that starts with an accumulator
 * bundle and successively apply an operation to the accumulator and a data
 * bundle, creating an outgoing bundle for each operation as well as a new
 * accumulator bundle.
 *
 * @param f The circuit to ripple map
 * @param accBundleSize The number of wires in the accumulator bundle
 * @param numberOfOperations
 * @param name
 * @param direction
 * @return The ripple map circuit
 */
public func MakeRippleMap<V, G>(
    f : InterfacedHypergraph<V, G>,
accBundleSize : Int64,
    numberOfOperations : Int64,
    name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAtMost(accBundleSize, f.GetArity())
    // Whether the accumulator wires should come first or last in the
    // input or output ports
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    let op = {
        acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let inputs = ConcatAccInputBundles(direction, acc, cur)
            let subcircuit = UseSubcircuit(f, inputs)
            let outputsSplitPoint = if(outputAccFirst) {
                accBundleSize
            } else {
                f.GetCoarity() - accBundleSize
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
        f.GetInputs(), inputAccFirst, accBundleSize, numberOfOperations
    )
    // Get ports describing the outputs to the ripple map subcircuit
    let outputPorts = GetRippleMapPorts(
        f.GetOutputs(), outputAccFirst, accBundleSize, numberOfOperations
    )
    // Use the ports in the specification of the ripple map label
    let circuitLabel = match(name) {
        case Some(s) => s
        case None => "${f.GetName()}^${numberOfOperations}"
    }
    // Create the label specification for the ripple map subcircuit
    let spec = Specification(circuitLabel, inputPorts, outputPorts)
    MakeRippleMap(
        op, inputPorts, outputPorts, accBundleSize,
        f.GetArity() - accBundleSize, f.GetCoarity() - accBundleSize,
        Label<V, G>.COMPOSITE(spec), direction: direction
    )
}