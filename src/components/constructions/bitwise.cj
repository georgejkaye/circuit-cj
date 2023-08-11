package components.constructions
from std import collection.HashSet
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
func SortByBit<T>(
    inputs : Array<Array<T>>, start!: Int64 = 0, end!: Int64 = inputs.size
) : Array<T> where T <: ToString & HasWidth {
    let bundleWidth = AssertAllSameLength<T>(
        inputs, start: start, end: end
    )
    let totalLength = Sum(inputs, { ts : Array<T> => ts.size })
    let wiresToSort = end - start
    let toSortLength = Sum(
        inputs, { ts : Array<T> => ts.size }, start: start, end: end
    )
    Array<T>(totalLength, {
        i =>
            if(i < start || i >= start + toSortLength) {
                inputs[i][0]
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
 * and so on. Optionally, indices of the wires *not* to split can be specified;
 * rather than being split, these wires will be forked so each bundle will
 * contain the *whole* wire rather than one of its bits.
 *
 * @param inputWires
 * @param sharedIndices
 */
func BitwiseSplit<V, G>(
    inputWires : Array<Wire<V, G>>, sharedIndices!: HashSet<Int64> = HashSet(),
    start!: Int64 = 0, end!: Int64 = inputWires.size
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let bundleWidth = AssertAllSameWidth(inputWires, start: start, end: end)
    let splitInputs = mapi(
        { w : Wire<V, G>, i : Int64 =>
            if(i < start || i >= end) {
                [w]
            } else if(!sharedIndices.contains(i)) {
                Split(w)
             } else {
                Array<Wire<V, G>>(bundleWidth, { _ => w })
             }
        }, inputWires)
    SortByBit<Wire<V, G>>(splitInputs, start: start, end: end)
}
public func BitwiseCombine<V, G>(
    inputWires : Array<Wire<V, G>>, numberOfBundles : Int64, start!: Int64 = 0,
    end!: Int64 = inputWires.size
) : Array<Wire<V, G>> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let widthOfOutputWires = numberOfBundles
    AssertAtLeast(start, 0)
    AssertAtMost(end, inputWires.size)
    let numberOfOutputWires = AssertMultipleOf(end - start, numberOfBundles)
    let totalOutputWires = numberOfOutputWires + start + (inputWires.size - end)
    let startOutputIndex = start
    let endOutputIndex = ((end - start) / numberOfBundles) + start
    Array<Wire<V, G>>(totalOutputWires, {
        currentOutputWire =>
            if(currentOutputWire < startOutputIndex) {
                inputWires[currentOutputWire]
            } else if(currentOutputWire >= endOutputIndex) {
                let currentEndOutputWire = currentOutputWire - endOutputIndex
                inputWires[end + currentEndOutputWire]
            } else {
                let wiresToCombine = Array<Wire<V, G>>(
                    widthOfOutputWires, { currentBundle =>
                        let bundleStart = (currentBundle * numberOfOutputWires) + start
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
 * @param f (ingoing bundle) -> outgoing bundle
 * @param inputWires
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>, sharedIndices!: HashSet<Int64> = HashSet()
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>,  G <: PrimitiveSymbol<V, G>
{
    // There is one operation for each bit of the split wires
    let numberOfOperations =
        AssertAllSameWidth(inputWires, excluding: sharedIndices)
    let splitWires = BitwiseSplit(inputWires, sharedIndices: sharedIndices)
    let mappedWires = Map(f, splitWires, numberOfOperations)
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
 * @return The array of combined wires
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputWires : Array<Wire<V, G>>, sharedIndices!: HashSet<Int64>
) : Wire<V, G> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs)] }
    BitwiseMap<V, G>(fAdjusted, inputWires, sharedIndices: sharedIndices)[0]
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
    sharedIndices!: HashSet<Int64>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let fAdjusted = { inputs : Array<Wire<V, G>> => [f(inputs[0])] }
    BitwiseMap(fAdjusted, [input], sharedIndices: sharedIndices)[0]
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
    label: Label<V, G>, sharedInputWires!: HashSet<Int64> = HashSet()
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let width = AssertAllSameWidth(allInputPorts, excluding: sharedInputWires)
    let inputWires = map({t : T => UseWire<V, G>(t.GetWidth())}, allInputPorts)
    let outputWires = BitwiseMap(f, inputWires, sharedIndices: sharedInputWires)
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
    name : String,
    sharedInputWires!: HashSet<Int64>
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
        f, totalInputPorts, totalOutputPorts, Label<V, G>.COMPOSITE(spec),
        sharedInputWires: sharedInputWires
    )
}
public func GetBitwiseMapPorts<V, G, T>(
    ports : Array<T>, numberOfOperations : Int64,
    sharedInputWires!: HashSet<Int64> = HashSet()
) : Array<Port>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    mapi(
        { t : T, i : Int64 =>
            let width = if(sharedInputWires.contains(i)){
                t.GetWidth()
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
 * @return The bitwise map circuit
 */
public func MakeBitwiseMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations : Int64,
    sharedInputWires!: HashSet<Int64> = HashSet()
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
    let spec = Specification(
        "${f.GetName()}_${numberOfOperations}",
        bitwiseMapInputPorts, bitwiseMapOutputPorts
    )
    MakeBitwiseMap(
        { ws : Array<Wire<V, G>> => UseSubcircuit(f, ws) },
        bitwiseMapInputPorts, bitwiseMapOutputPorts,
        Label<V, G>.COMPOSITE(spec), sharedInputWires: sharedInputWires
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
    inputWires : Array<Wire<V, G>>,
    sharedInputWires!: HashSet<Int64> = HashSet()
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(inputWires, excluding: sharedInputWires)
    let numberOfOperations = (inputWires.size - sharedInputWires.size) / width
    UseSubcircuit(MakeBitwiseMap(f, width, sharedInputWires: sharedInputWires))
}

public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputWires : Array<Wire<V, G>>,
    accBundleSize: Int64,
    numberOfIncomingBundles : Int64,
    outgoingBundleSize : Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = numberOfIncomingBundles,
    sharedIndices!: HashSet<Int64> = HashSet()
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let (inputAccStart, inputAccEnd) =
        GetInputAccumulatorIndices(direction, accBundleSize, inputWires.size)
    let (splitStart, splitEnd) = if(inputAccStart == 0) {
        (inputAccEnd, inputWires.size)
    } else {
        (0, inputAccStart)
    }
    let actualSharedIndices = HashSet<Int64>()
    for(index in sharedIndices){
        actualSharedIndices.put(index + accBundleSize)
    }
    let splitWires =
        BitwiseSplit(
            inputWires, sharedIndices: actualSharedIndices,
            start: splitStart, end: splitEnd
        )
    let rippledWires = RippleMap(
        f, splitWires, accBundleSize, numberOfIncomingBundles,
        outgoingBundleSize, direction: direction, start: start, end: end
    )
    let (outputAccStart, outputAccEnd) =
        GetOutputAccumulatorIndices(direction, accBundleSize, rippledWires.size)
    let (combineStart, combineEnd) = if(outputAccStart == 0) {
        (outputAccEnd, rippledWires.size)
    } else {
        (0, outputAccStart)
    }
    let combinedWires = BitwiseCombine(
        rippledWires, numberOfIncomingBundles,
        start: combineStart, end: combineEnd
    )
    combinedWires
}
func MakeBitwiseRippleMap<V, G, T, U>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    allIncomingPorts : Array<T>,
    allOutgoingPorts : Array<U>,
    accBundleSize: Int64,
    numberOfIncomingBundles : Int64,
    outgoingBundleSize : Int64,
    label: Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = numberOfIncomingBundles
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let inputWires =
        map({t : T => UseWire<V, G>(t.GetWidth())}, allIncomingPorts)
    let outputWires = BitwiseRippleMap(
        f, inputWires, accBundleSize, numberOfIncomingBundles,
        outgoingBundleSize, direction: direction, start: start, end: end
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
func GetBitwiseRippleMapAccPort<T>(t : T) : Port where T <: HasPort {
    t.ToPort()
}
func GetBitwiseRippleMapOtherPort<T>(t : T, numberOfOperations : Int64) : Port
    where T <: HasPort
{
    Port(t.GetWidth() * numberOfOperations, name: t.GetName())
}
func GetBitwiseRippleMapPorts<T>(
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
public func MakeBitwiseRippleMap<V, G, T>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    accPorts : Array<T>,
    portsPerIncomingBundle : Array<T>,
    portsPerOutgoingBundle : Array<T>,
    numberOfOperations : Int64,
    name : String,
    direction!: Direction,
    start!: Int64 = 0,
    end!: Int64 = numberOfOperations
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    let totalInputPorts = accPorts.size + portsPerIncomingBundle.size
    let totalOutputPorts = accPorts.size + portsPerOutgoingBundle.size
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    let (inputFirst, inputSecond) = if(inputAccFirst) {
        (accPorts, portsPerIncomingBundle)
    } else {
        (portsPerIncomingBundle, accPorts)
    }
    let allInputPorts = GetBitwiseRippleMapPorts<T>(
        concat(inputFirst, inputSecond), inputAccFirst, accPorts.size,
        numberOfOperations
    )
    let (outputFirst, outputSecond) = if(outputAccFirst) {
        (accPorts, portsPerOutgoingBundle)
    } else {
        (portsPerOutgoingBundle, accPorts)
    }
    let allOutputPorts = GetBitwiseRippleMapPorts<T>(
        concat(outputFirst, outputSecond), outputAccFirst, accPorts.size,
        numberOfOperations
    )
    let spec = Specification(name, allInputPorts, allOutputPorts)
    let label = Label<V, G>.COMPOSITE(spec)
    MakeRippleMap(
        f, allInputPorts, allOutputPorts, accPorts.size,
        portsPerIncomingBundle.size, portsPerIncomingBundle.size, label,
        direction: direction
    )
}
public func MakeBitwiseRippleMap<V, G>(
    f : InterfacedHypergraph<V, G>,
    accBundleSize : Int64,
    inputDataWireWidth : Int64,
    name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let (inputAccFirst, outputAccFirst) = GetRippleBundlePositions(direction)
    let op = GetRippleMapOperationForSubcircuit(
        f, direction, outputAccFirst, accBundleSize
    )
    let numberOfOperations = inputDataWireWidth
    let allInputPorts = GetBitwiseRippleMapPorts(
        f.GetInputs(), inputAccFirst, accBundleSize, inputDataWireWidth
    )
    let allOutputPorts = GetBitwiseRippleMapPorts(
        f.GetOutputs(), outputAccFirst, accBundleSize, inputDataWireWidth
    )
    let circuitLabel = match(name) {
        case Some(s) => s
        case None => "${f.GetName()}_${allInputPorts.size}"
    }
    let spec = Specification(circuitLabel, allInputPorts, allOutputPorts)
    let label = Label<V, G>.COMPOSITE(spec)
    MakeBitwiseRippleMap<V, G, Port, Port>(
        op, allInputPorts, allOutputPorts, accBundleSize, inputDataWireWidth,
        f.GetCoarity() - accBundleSize, label, direction: direction
    )
}