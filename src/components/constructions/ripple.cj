package components.constructions
/**
 * Perform a ripple, an operation that starts with an accumulator bundle and
 * successively apply an operation to the accumulator and a data bundle,
 * creating a new accumulator bundle.
 *
 * @param f (acc bundle, cur bundle) -> acc bundle
 * @param inputWires
 * @param accBundleSize The number of wires that make up the accumulator bundle
 * @param dataBundleSize The number of wires that make up each data bundle
 * @param direction
 * @param start The input bundle to start rippling from
 * @param end The input bundle to end rippling at
 * @return The final accumulator bundle
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputWires : Array<Wire<V, G>>,
    accBundleSize!: Int64,
    numberOfOperations!: Int64,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc, cur)
            (Array<Wire<V, G>>(), curAcc)
        }
    RippleMap(
        function, inputWires, accBundleSize: accBundleSize,
        numberOfOperations: numberOfOperations, direction: direction
    )
}
/**
 * Perform a ripple, an operation that starts with an accumulator bundle and
 * successively apply an operation to the accumulator and a data bundle,
 * creating a new accumulator bundle.
 *
 * @param f (acc wire, cur bundle) -> acc wire
 * @param inputWires
 * @param dataBundleSize The number of wires that make up each data bundle
 * @param direction
 * @param start The input bundle to start rippling from
 * @param end The input bundle to end rippling at
 * @return The final accumulator bundle
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    inputWires : Array<Wire<V, G>>,
    numberOfOperations!: Int64,
    direction!: Direction = TOP_TO_BOTTOM
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc[0], cur)
            [curAcc]
        }
    Ripple(
        function, inputWires, accBundleSize: 1,
        numberOfOperations: numberOfOperations, direction: direction
    )[0]
}
/**
 * Make a ripple curcuit, an operation that starts with an accumulator bundle
 * and successively apply an operation to the accumulator and a data bundle,
 * creating a new accumulator bundle.
 *
 * @param f (acc bundle, cur bundle) -> acc bundle
 * @param allInputPorts
            Array of the input ports of the completed ripple circuit
 * @param allOutputPorts
            Array of the output ports of the completed ripple circuit
 * @param accBundleSize The number of wires in the accumulator bundle
 * @param incomingBundleSize The number of wires in the incoming bundles
 * @param direction
 * @return The ripple circuit
 */
func MakeRipple<V, G, T, U>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    allInputPorts : Array<T>,
    allOutputPorts : Array<U>,
    accBundleSize!: Int64,
    numberOfOperations!: Int64,
    label!: Label<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasPort, U <: HasPort
{
    let function  = {
        acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            (Array<Wire<V, G>>(), f(acc, cur))
    }
    MakeRippleMap<V, G, T, U>(
        function, allInputPorts, allOutputPorts, accBundleSize: accBundleSize,
        numberOfOperations: numberOfOperations, label: label,
        direction: direction
    )
}
/**
 * Make a ripple curcuit, an operation that starts with an accumulator bundle
 * and successively apply an operation to the accumulator and a data bundle,
 * creating a new accumulator bundle.
 *
 * @param f (acc bundle, cur bundle) -> acc bundle
 * @param accPorts The ports that make up the accumulator bundle
 * @param incomingPorts The ports that make up each incoming bundle
 * @param numberOfOperations
 * @param name
 * @param direction
 * @return The ripple circuit
 */
public func MakeRipple<V, G, T>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    accPorts : Array<T>,
    incomingPorts : Array<T>,
    numberOfOperations : Int64,
    name : String,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>, T <: HasPort
{
    let op = {
        acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            (f(acc, cur), Array<Wire<V, G>>())
    }
    MakeRippleMap<V, G, T>(
        op, accPorts, incomingPorts, Array<T>(),
        numberOfOperations: numberOfOperations, name: name, direction: direction
    )
}
/**
 * Make a ripple curcuit, an operation that starts with an accumulator bundle
 * and successively apply an operation to the accumulator and a data bundle,
 * creating a new accumulator bundle.
 *
 * @param f The circuit to ripple
 * @param numberOfOperations
 * @param name
 * @param direction
 * @return The ripple circuit
 */
public func MakeRipple<V, G>(
    f : InterfacedHypergraph<V, G>,
    numberOfOperations!: Int64,
    name!: Option<String> = None<String>,
    direction!: Direction = TOP_TO_BOTTOM
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    MakeRippleMap(
        f, acc: f.GetCoarity(),
        ops: numberOfOperations, name: name, direction: direction
    )
}