/**
 * components/constructions/bitwise.cj
 *
 * Functions for creating bitwise circuits
 *
 * @author George Kaye
 * @since 0.2
 */
package components.constructions
from std import collection.HashSet
/**
 * Given an array of inputs and a bundle width w such that so that the array is
 * partitioned into n bundles of width w:
 *
 *    ws[0][0], ws[0][1], ..., ws[0][w-1], ..., ws[n-1][0], ..., ws[n-1][w-1]
 *
 * create a version of this array of the form
 *
 *    ws[0][0], ws[1][0], ..., ws[n-1][0], ..., ws[n-1][0], ..., ws[n-1][w-1]
 *
 * Optionally, this can have a start and end index; wires outside of this range
 * will not be sorted.
 *
 * @param inputs
 * @param bundleWidth
 * @param start
 * @param end
 * @return The array of sorted wires
 */
func SortByBit<T>(
    inputs : Array<T>, bundleWidth : Int64,
    start!: Int64 = 0, end!: Int64 = inputs.size
) : Array<T> {
    Array<T>(inputs.size, {
        i =>
        if(i < start || i >= end) {
            inputs[i]
        } else {
            let inputNumber = i % bundleWidth
            let bitIndex = i / bundleWidth
            inputs[inputNumber * bundleWidth + bitIndex]
        }
    })
}
/**
 * Given an array of arrays of inputs and a bundle width
 *
 *    [ws[0][0], ws[0][1], ..., ws[0][w-1]], ... ,[ws[n-1][w-1], ..., w[n-1][w-1]]
 *
 * create a flat array of the form
 *
 *    ws[0][0], ws[1][0], ..., ws[n-1][0], ws[0][1], ws[1][1], ..., ws[n-1][w-1]
 *
 * Optionally, this can have a start and end index; wires outside of this range
 * will not be sorted.
 *
 * @param inputs
 * @param start
 * @param end
 * @return The array of sorted wires
 */
func SortByBit<T>(
    inputs : Array<Array<T>>, start!: Int64 = 0, end!: Int64 = inputs.size
) : Array<T> where T <: ToString & HasWidth {
    let bundleWidth = AssertAllSameLength<T>(inputs, start: start, end: end)
    let totalLength = Sum(inputs, { ts : Array<T> => ts.size })
    let wiresToSort = end - start
    let toSortLength = Sum(
        inputs, { ts : Array<T> => ts.size }, start: start, end: end
    )
    Array<T>(totalLength, {
        i =>
            if(i < start) {
                inputs[i][0]
            } else if (i >= start + toSortLength) {
                let inputArrayIndex = end + i - (start + toSortLength)
                inputs[inputArrayIndex][0]
            } else {
                let inputNumber = ((i - start) % wiresToSort) + start
                let bitIndex = (i - start) / wiresToSort
                inputs[inputNumber][bitIndex]
            }
    })
}
/**
 * Perform a bitwise split: split wires into their constituent bits and
 * output bundles of the 0th bit wires, the 1st bit wires, the 2nd bit wires
 * and so on.
 *
 *  Optionally, indices of the wires *not* to split can be specified;
 * rather than being split, these wires will be forked so each bundle will
 * contain the *whole* wire rather than one of its bits.
 *
 * A start and end index can also be specified; outside of this range,
 * no splitting or forking will occur.
 *
 * @param inputWires
 * @param sharedIndices The indices of wires to be forked rather than split
 * @param splitInto The width of the split wires
 */
func BitwiseSplit<V, G>(
    inputWires : Array<Wire<V, G>>, sharedIndices!: HashSet<Int64> = HashSet(),
    splitInto!: Int64 = 1, start!: Int64 = 0, end!: Int64 = inputWires.size
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let splitInputs = mapi(
        { w : Wire<V, G>, i : Int64 =>
            if(i < start || i >= end) {
                [w]
            } else if(!sharedIndices.contains(i)) {
                SplitInto(w, splitInto)
             } else {
                Array<Wire<V, G>>(splitInto, { _ => w })
             }
        }, inputWires)
    SortByBit<Wire<V, G>>(splitInputs, start: start, end: end)
}
/**
 * Perform a bitwise combine: given an array of input wires and a number of
 * bundles n such that the array is of the form
 *
 *   ws[0][0], ws[0][1], ... , ws[0][w-1], ..., ws[n-1][0], ... ws[n-1][w-1]
 *
 * create an array of wires of the form
 *
 *   ws[0][0], ws[1][0], ... ws[n-1][0]
 *
 * Optionally there can be a start and end output wire; this means that all
 * output wires before start and after end will not be the result of a combine.
 *
 * @param inputWires
 * @param numberOfBundles
 * @param start
 * @param end
 * @return Array of combined wires
 */
public func BitwiseCombine<V, G>(
    inputWires : Array<Wire<V, G>>, numberOfBundles : Int64, start!: Int64 = 0,
    end!: Int64 = inputWires.size
) : Array<Wire<V, G>> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    AssertGreaterThanOrEqualTo(start, 0)
    AssertLessThanOrEqualTo(end, inputWires.size)
    let widthOfOutputWires = numberOfBundles
    let numberOfOutputWires = AssertMultipleOf(end - start, numberOfBundles)
    let totalOutputWires = numberOfOutputWires + start + (inputWires.size - end)
    // The index of the first combined output wire
    let startOutputIndex = start
    // The index of the last combined output wire
    let endOutputIndex = ((end - start) / numberOfBundles) + start
    // Create the output wires
    Array<Wire<V, G>>(totalOutputWires, {
        currentOutputWire =>
            // If wire is before the first index, just use it as is
            if(currentOutputWire < startOutputIndex) {
                inputWires[currentOutputWire]
            // If wire is after the last index, just use it as is
            } else if(currentOutputWire >= endOutputIndex) {
                // Retrieve the appropriate input wire
                let currentEndOutputWire = currentOutputWire - endOutputIndex
                inputWires[end + currentEndOutputWire]
            // Combine the wires into one wire
            } else {
                let wiresToCombine = Array<Wire<V, G>>(
                    widthOfOutputWires, { currentBundle =>
                        let bundleStart =
                            (currentBundle * numberOfOutputWires) + start
                        let currentBit = currentOutputWire - start
                        inputWires[bundleStart + currentBit]
                    })
                Combine(wiresToCombine)
            }
    })
}
/**
 * Perform a bitwise map: splitting input wires into one-bit wires, applying an
 * operation to wires with the same index of each input, then combining the
 * wires again.
 *
 * Optionally some wires can be 'shared': rather than being split they will be
 * copied.
 *
 * @param f (ingoing bundle) -> outgoing bundle
 * @param inputWires
 * @param numberOfOperations
 * @param sharedIndices
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>, numberOfOperations!: Int64,
    sharedIndices!: HashSet<Int64> = HashSet()
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>,  G <: PrimitiveSymbol<V, G>
{

    let splitWires = BitwiseSplit(
        inputWires, sharedIndices: sharedIndices, splitInto: numberOfOperations
    )
    let mappedWires = Map(f, splitWires, numberOfOperations: numberOfOperations)
    let combinedWires = BitwiseCombine(mappedWires, numberOfOperations)
    combinedWires
}
/**
 * Perform a bitwise map: splitting input wires into one-bit wires, applying an
 * operation to wires with the same index of each input, then combining the
 * wires again.
 *
 * @param f (ingoing bundle) -> outgoing wire
 * @param inputWires
 * @param numberOfOperations
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputWires : Array<Wire<V, G>>,
    numberOfOperations!: Int64 = AssertAllHaveSameWidth(inputWires),
    sharedIndices!: HashSet<Int64>
) : Wire<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs)] }
    BitwiseMap<V, G>(
        fAdjusted, inputWires, numberOfOperations: numberOfOperations,
        sharedIndices: sharedIndices
    )[0]
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
    f : (Wire<V, G>) -> Wire<V, G>, input : Wire<V, G>,
    numberOfOperations!: Int64, sharedIndices!: HashSet<Int64>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs[0])] }
    BitwiseMap(
        fAdjusted, [input], numberOfOperations: numberOfOperations,
        sharedIndices: sharedIndices
    )[0]
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
    label: Label<V, G>,
    numberOfOperations!: Int64,
    sharedInputWires!: HashSet<Int64> = HashSet()
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let width = AssertAllElementsMultiplesOf(
        allInputPorts, numberOfOperations, { t => t.GetWidth() },
        excluding: sharedInputWires
    )
    let inputWires = map({t : T => UseWire<V, G>(t.GetWidth())}, allInputPorts)
    let outputWires = BitwiseMap(
        f, inputWires, numberOfOperations: numberOfOperations,
        sharedIndices: sharedInputWires
    )
    let inputInterfaceWires = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName()) },
        inputWires, allInputPorts
    )
    let outputInterfaceWires = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName()) },
        outputWires, allOutputPorts
    )
    MakeSubcircuit(inputInterfaceWires, outputInterfaceWires, label)
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
    name : String,
    sharedInputWires!: HashSet<Int64>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
                T <: HasPort, U <: HasPort
{
    let totalInputPorts =
        GetBitwiseMapPorts<V, G, T>(
            incomingBundlePorts, numberOfOperations,
            sharedInputWires: sharedInputWires
        )
    let totalOutputPorts =
        GetBitwiseMapPorts<V, G, U>(
            outgoingBundlePorts, numberOfOperations,
            sharedInputWires: sharedInputWires
        )
    let spec = Specification(name, totalInputPorts, totalOutputPorts)
    MakeBitwiseMap(
        f, totalInputPorts, totalOutputPorts, Label<V, G>.COMPOSITE(spec),
        numberOfOperations: numberOfOperations,
        sharedInputWires: sharedInputWires
    )
}
/**
 * Given the ports for an operation and the number of operations, get the
 * ports for a bitwise map over this operation. Can take into account some
 * wires being shared rather than split.
 *
 * @param ports
 * @param numberOfOperations
 * @param sharedInputWires
 * @return The array of ports
 */
public func GetBitwiseMapPorts<V, G, T>(
    ports : Array<T>, numberOfOperations : Int64,
    sharedInputWires!: HashSet<Int64> = HashSet()
) : Array<Port>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    mapi(
        { t : T, i : Int64 =>
            // Shared wires are not split so use the base width
            let width = if(sharedInputWires.contains(i)){
                t.GetWidth()
            // Non shared wires are split equally between each operation
            } else {
                numberOfOperations * t.GetWidth()
            }
            Port(width, name: t.GetName())
        },
        ports
    )
}
/**
 * Make a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f The circuit to bitwise map
 * @param numberOfOperations
 * @param sharedInputWires
 * @return The bitwise map circuit
 */
public func MakeBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations!: Int64,
    sharedInputWires!: HashSet<Int64>,
    name!: Option<String> = None<String>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let bitwiseMapInputPorts =
        GetBitwiseMapPorts<V, G, InterfaceVertex<V, G>>(
            f.GetInputs(), numberOfOperations,
            sharedInputWires: sharedInputWires
        )
    let bitwiseMapOutputPorts =
        GetBitwiseMapPorts<V, G, InterfaceVertex<V, G>>(
            f.GetOutputs(), numberOfOperations
        )
    let specName = match(name) {
        case None => "${f.GetName()}_${numberOfOperations}"
        case Some(s) => s
    }
    let spec = Specification(
        specName, bitwiseMapInputPorts, bitwiseMapOutputPorts
    )
    MakeBitwiseMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws) },
        bitwiseMapInputPorts, bitwiseMapOutputPorts,
        Label<V, G>.COMPOSITE(spec), numberOfOperations: numberOfOperations,
        sharedInputWires: sharedInputWires
    )
}/**
 * Make a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f The circuit to bitwise map
 * @param numberOfOperations
 * @param sharedInputWires
 * @return The bitwise map circuit
 */
public func MakeBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations!: Int64,
    sharedInputWires!: Array<Int64> = Array(),
    name!: Option<String> = None<String>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    MakeBitwiseMap(
        f, numberOfOperations: numberOfOperations,
        sharedInputWires: HashSet(sharedInputWires), name: name
    )
}
/**
 * Use a bitwise map circuit: splitting input wires into one-bit wires,
 * applying an operation to wires with the same index of each input, then
 * combining the wires again.
 *
 * @param f The circuit to bitwise map
 * @param inputWires
 * @param numberOfOperations
 * @param sharedInputWires
 * @return The outputs of the bitwise map circuit
 */
public func UseBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    inputWires : Array<Wire<V, G>>,
    numberOfOperations: Int64,
    sharedInputWires!: HashSet<Int64> = HashSet()
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllHaveSameWidth(inputWires, excluding: sharedInputWires)
    UseSubcircuit(
        MakeBitwiseMap(
            f, numberOfOperations: numberOfOperations,
            sharedInputWires: sharedInputWires
        )
    )
}
/**
 * Perform a bitwise ripple map, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f The operation (acc, in) -> (acc, out)
 * @param accBundleSize
 * @param numberOfOperations
 * @param direction
 * @param sharedIndices
 * @param initial true if option a) is picked above, false for option b)
 * @return The output wires from the bitwise map
 */
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputWires : Array<Wire<V, G>>,
    accBundleSize: Int64,
    numberOfOperations : Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    sharedIndices!: HashSet<Int64> = HashSet(),
    initial!: Bool = true
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let (inputAccStart, inputAccEnd) =
        GetInputAccumulatorIndices(direction, accBundleSize, inputWires.size)
    let (splitStart, splitEnd, splitInto) = if(!initial) {
        (0, accBundleSize, numberOfOperations + 1)
    } else if(inputAccStart == 0) {
        (inputAccEnd, inputWires.size, numberOfOperations)
    } else {
        (0, inputAccStart, numberOfOperations)
    }
    let actualSharedIndices = HashSet<Int64>()
    for(index in sharedIndices){
        actualSharedIndices.put(index + accBundleSize)
    }
    let splitWires =
        BitwiseSplit(
            inputWires, sharedIndices: actualSharedIndices,
            start: splitStart, end: splitEnd, splitInto: splitInto
        )
    let rippledWires = RippleMap(
        f, splitWires, accBundleSize: accBundleSize,
        numberOfOperations: numberOfOperations, direction: direction
    )
    let (outputAccStart, outputAccEnd, _) =
        GetOutputAccumulatorIndices(direction, accBundleSize, rippledWires.size)
    let (combineStart, combineEnd) = if(outputAccStart == 0) {
        (outputAccEnd, rippledWires.size)
    } else {
        (0, outputAccStart)
    }
    let combinedWires = BitwiseCombine(
        rippledWires, numberOfOperations, start: combineStart, end: combineEnd
    )
    combinedWires
}
/**
 * Perform a bitwise ripple map, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f The operation (acc, in) -> (acc, out)
 * @param accWires Array of wires for accumulator
 * @param dataWires Array of wires for data
 * @param numberOfOperations
 * @param direction
 * @param sharedIndices
 * @param initial true if option a) is picked above, false for option b)
 * @return (acc wires, output wires)
 */
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    accWires : Array<Wire<V, G>>,
    dataWires : Array<Wire<V, G>>,
    numberOfOperations!: Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    sharedIndices!: HashSet<Int64> = HashSet()
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let outputs = BitwiseRippleMap(
        f, concat(accWires, dataWires), accWires.size, numberOfOperations,
        direction: direction
    )
    // Split up the accumulator and the outputs
    let (outputAccStart, outputAccEnd, partitionPoint) =
        GetOutputAccumulatorIndices(direction, accWires.size, outputs.size)
    let (first, second) = outputs.partition(partitionPoint)
    if(outputAccStart == 0) {
        (first, second)
    } else {
        (second, first)
    }
}
/**
 * Make a bitwise ripple map, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f The operation (acc, in) -> (acc, out)
 * @param allIncomingPorts Array of ports for entire circuit inputs
 * @param allOutgoingPorts Array of ports for entire circuit outputs
 * @param accBundleSize
 * @param numberOfOperations
 * @param direction
 * @param label
 * @param initial true if option a) is picked above, false for option b)
 * @return The bitwise ripple map circuit
 */
func MakeBitwiseRippleMap<V, G, T, U>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    allIncomingPorts : Array<T>,
    allOutgoingPorts : Array<U>,
    accBundleSize: Int64,
    numberOfOperations : Int64,
    label: Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM,
    initial!: Bool = true
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let inputWires =
        map({t : T => UseWire<V, G>(t.GetWidth())}, allIncomingPorts)
    let outputWires = BitwiseRippleMap(
        f, inputWires, accBundleSize, numberOfOperations, direction: direction,
        initial: initial
    )
    let inputInterfaceWires = map2(
        { w : Wire<V, G>, t : T => InterfaceWire(w, t.GetName())},
        inputWires, allIncomingPorts
    )
    let outputInterfaceWires = map2(
        { w : Wire<V, G>, u : U => InterfaceWire(w, u.GetName())},
        outputWires, allOutgoingPorts
    )
    MakeSubcircuit(inputInterfaceWires, outputInterfaceWires, label)
}
/**
 * Given a template port, get the corresponding port for a bitwise ripple map
 * accumulator wire
 *
 * @param t
 * @return The port for an accumulator wire
 */
func GetBitwiseRippleMapAccPort<T>(t : T) : Port where T <: HasPort {
    t.ToPort()
}
/**
 * Given a template port, get the corresponding port for a bitwise ripple map
 * data wire
 *
 * @param t
 * @param numberOfOperations
 * @return The port for a data wire
 */
func GetBitwiseRippleMapOtherPort<T>(t : T, numberOfOperations : Int64) : Port
    where T <: HasPort
{
    Port(t.GetWidth() * numberOfOperations, name: t.GetName())
}
/**
 * Get an array of ports for a bitwise ripple map with initial wires.
 *
 * @param portsPerOperation
 * @param accFirst
 * @param accBundleSize
 * @param numberOfOperations
 * @return The array of ports
 */
func GetBitwiseRippleMapPortsWithInitial<T>(
    portsPerOperation : Array<T>, accFirst : Bool, accBundleSize: Int64,
    numberOfOperations : Int64
) : Array<Port> where T <: HasPort {
    let totalWires = portsPerOperation.size
    Array<Port>(totalWires, { i : Int64 =>
        let port = portsPerOperation[i]
        if(accFirst) {
            if(i < accBundleSize) {
                GetBitwiseRippleMapAccPort(port)
            } else {
                GetBitwiseRippleMapOtherPort(port, numberOfOperations)
            }
        } else {
            if(i < (totalWires - accBundleSize)) {
                GetBitwiseRippleMapOtherPort(port, numberOfOperations)
            } else {
                GetBitwiseRippleMapAccPort(port)
            }
        }
    })
}
/**
 * Get an array of ports for a bitwise ripple map without initial wires.
 *
 * @param portsPerOperation
 * @param numberOfOperations
 * @return The array of ports
 */
func GetBitwiseRippleMapInputsWithoutInitial<T>(
    portsPerOperation : Array<T>, numberOfOperations : Int64
) : Array<Port> where T <: HasPort {
    let bundleSize = portsPerOperation.size / 2
    for(i in 0..bundleSize){
        AssertBothSameWidth(
            portsPerOperation[i], portsPerOperation[i+bundleSize]
        )
    }
    let numberOfInputWires = bundleSize
    Array<Port>(numberOfInputWires, { i =>
        let widthPerWire = portsPerOperation[i].GetWidth()
        let totalWidth = widthPerWire * (numberOfOperations + 1)
        Port(totalWidth, name: portsPerOperation[i].GetName())
    })
}
/**
 * Make a bitwise ripple map, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f The operation (acc, in) -> (acc, out)
 * @param inputAccPorts
 * @param inputDataPorts ports for one input data bundle
 * @param outputAccPorts
 * @param outputDataPorts ports for one output data bundle
 * @param numberOfOperations
 * @param name
 * @param direction
 * @param initial true if option a) is picked above, false for option b)
 * @return The bitwise ripple map circuit
 */
public func MakeBitwiseRippleMap<V, G, T>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputAccPorts : Array<T>, inputDataPorts : Array<T>,
    outputAccPorts : Array<T>, outputDataPorts : Array<T>,
    numberOfOperations : Int64, name : String,
    direction!: Direction = TOP_TO_BOTTOM, initial!: Bool = true
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    AssertElementsHaveSameWidths(inputAccPorts, outputAccPorts)
    let totalInputPorts = inputAccPorts.size + inputDataPorts.size
    let totalOutputPorts = inputAccPorts.size + outputDataPorts.size
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    let (inputFirst, inputSecond) = if(inputAccFirst) {
        (inputAccPorts, inputDataPorts)
    } else {
        (inputDataPorts, inputAccPorts)
    }
    let inputPortsPerOperation = concat(inputFirst, inputSecond)
    let allInputPorts = if(!initial) {
        GetBitwiseRippleMapInputsWithoutInitial(
            inputPortsPerOperation, numberOfOperations
        )
    } else {
        GetBitwiseRippleMapPortsWithInitial<T>(
            inputPortsPerOperation, inputAccFirst, inputAccPorts.size,
            numberOfOperations
        )
    }
    let (outputFirst, outputSecond) = if(outputAccFirst) {
        (outputAccPorts, outputDataPorts)
    } else {
        (outputDataPorts, outputAccPorts)
    }
    let allOutputPorts = GetBitwiseRippleMapPortsWithInitial<T>(
        concat(outputFirst, outputSecond), outputAccFirst, outputAccPorts.size,
        numberOfOperations
    )
    let spec = Specification(name, allInputPorts, allOutputPorts)
    let label = Label<V, G>.COMPOSITE(spec)
    MakeBitwiseRippleMap(
        f, allInputPorts, allOutputPorts, inputAccPorts.size,
        numberOfOperations, label, direction: direction, initial: initial
    )
}
/**
 * Make a bitwise ripple map, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f
 * @param acc Number of accumulator wires in operation
 * @param ops Number of operations
 * @param name
 * @param direction
 * @param initial Whether to have an initial wire input (a) or not (b)
 * @return The bitwise ripple map circuit
 */
public func MakeBitwiseRippleMap<V, G>(
    f : InterfacedHypergraph<V, G>, acc!: Int64,
    ops!: Int64, name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM, initial!: Bool = true
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Find out where the accumulator is in the bundles
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    // Check the types work for the accumulator
    for(i in 0..acc) {
        let accVertex = f.GetInput(i)
        if(!initial) {
            AssertBothSameWidth(accVertex, f.GetInput(i + acc))
        }
        let outputAccIndex = if(outputAccFirst) {
            i
        } else {
            f.GetCoarity() - acc + i
        }
        AssertBothSameWidth(accVertex, f.GetOutput(outputAccIndex))
    }
    let op = GetRippleMapOperationForSubcircuit(
        f, direction, outputAccFirst, acc
    )
    let allInputPorts = if(!initial) {
        GetBitwiseRippleMapInputsWithoutInitial(
            f.GetInputs(), ops
        )
    } else {
        GetBitwiseRippleMapPortsWithInitial(
            f.GetInputs(), inputAccFirst, acc, ops
        )
    }
    let allOutputPorts = GetBitwiseRippleMapPortsWithInitial(
        f.GetOutputs(), outputAccFirst, acc, ops
    )
    let circuitLabel = match(name) {
        case Some(s) => s
        case None => "${f.GetName()}_${allInputPorts.size}"
    }
    let spec = Specification(circuitLabel, allInputPorts, allOutputPorts)
    let label = Label<V, G>.COMPOSITE(spec)
    MakeBitwiseRippleMap<V, G, Port, Port>(
        op, allInputPorts, allOutputPorts, acc, ops,
        label, direction: direction, initial: initial
    )
}
/**
 * Make a bitwise ripple, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f The operation (acc, in) -> (acc, out)
 * @param accPorts
 * @param portsPerIncomingBundle ports for one input data bundle
 * @param numberOfOperations
 * @param name
 * @param direction
 * @param initial true if option a) is picked above, false for option b)
 * @return The bitwise ripple circuit
 */
public func MakeBitwiseRipple<V, G, T>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>),
    accPorts : Array<T>, portsPerIncomingBundle : Array<T>,
    numberOfOperations : Int64, name : String,
    direction!: Direction = TOP_TO_BOTTOM, initial!: Bool = true
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    let op = {
        acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            (f(acc, cur), Array<Wire<V, G>>())
    }
    MakeBitwiseRippleMap<V, G, T>(
        op, accPorts, portsPerIncomingBundle, accPorts, Array<T>(),
        numberOfOperations, name, direction: direction, initial: initial
    )
}
/**
 * Make a bitwise ripple, in which (some of) the input data wires are
 * split bitwise to create the input data bundles for the ripple.

 * There are two choices regarding the initial accumulator wire:
 * a) The initial wire can be an additional input
 * b) The first bit of each of the data wires can be used as the initial wire
 *
 * Rather than being split, a wire can be shared.
 *
 * @param f
 * @param ops Number of operations
 * @param name
 * @param direction
 * @param initial true if option a) is picked above, false for option b)
 * @return The bitwise ripple circuit
 */
public func MakeBitwiseRipple<V, G>(
    f : InterfacedHypergraph<V, G>, ops!: Int64,
    name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM, initial!: Bool = true
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    MakeBitwiseRippleMap(
        f, acc: f.GetCoarity(),
        ops: ops, name: name,
        direction: direction, initial: initial
    )
}