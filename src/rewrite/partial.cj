/**
 * rewrite/partial.cj
 *
 * Partially evaluate circuits
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
import graphs.InterfacedHypergraph
/**
 * Get a fixed cycle input, an input that is known to be a particular signal.
 *
 * @param signal
 * @return The fixed cycle input
 */
public func GetFixed<V>(signal : Signal<V>) : CycleInput<V>
    where V <: ValueSymbol<V>
{
    DEFINITE(signal)
}
/**
 * Get a fixed cycle input, an input that is known to be a particular value.
 *
 * @param signal
 * @return The fixed cycle input
 */
public func GetFixed<V>(v : V) : CycleInput<V> where V <: ValueSymbol<V> {
    GetFixed(Signal(v))
}
/**
 * Get a fixed cycle input, an input that is known to be a particular signal.
 *
 * @param input
 * @param width
 * @param signed
 * @retrn The fixed cycle input for this number
 */
public func GetFixed<V, G>(
    sig: Signature<V, G>, input : Int64, width!: Int64, signed!: Bool
) : CycleInput<V>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    GetFixed(V.DecToSignal(input, width: width, signed: signed))
}
/**
 * Get a variable cycle input, an input that could be multiple signals.
 *
 * @param signals
 * @return The variable cycle input
 */
public func GetVariable<V>(signals : HashSet<Signal<V>>) : CycleInput<V>
    where V <: ValueSymbol<V>
{
    if(signals.size == 0) {
        let signal = signals.iterator().next().getOrThrow()
        GetFixed(signal)
    } else {
        let width = AssertAllHaveSameWidth(signals)
        let pvv = Variable(signals)
        let values = Array<VariableValue<V>>(width){ i : Int64 =>
            VariableValue(
                HashSet([pvv]),
                { ss : HashMap<Int64, Signal<V>> => ss[0].GetBit(i) }
            )
        }
        PARTIAL(VariableSignal(values))
    }
}
/**
 * Get a variable cycle input, an input that could be multiple values.
 *
 * @param signals
 * @return The variable cycle input
 */
public func GetVariable<V>(values : HashSet<V>) : CycleInput<V>
    where V <: ValueSymbol<V>
{
    GetVariable(HashSet(mapCollection({ v => Signal(v) }, values)))
}
/**
 * Get a variable cycle input, an input that could be multiple signals.
 *
 * @param inputs
 * @param width
 * @param signed
 * @return The variable cycle input
 */
public func GetVariable<V, G>(
    sig : Signature<V, G>, inputs : HashSet<Int64>, width!: Int64, signed!: Bool
) : CycleInput<V>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signalArray = mapCollection<Int64, Signal<V>>(
        { i : Int64 => V.DecToSignal(i, width: width, signed: signed)},
        inputs
    )
    let signals = HashSet(signalArray)
    GetVariable(signals)
}
/**
 * Get an unknown cycle input, an input that could be anything.
 * (In reality this is just a variable that can take every possible signal)
 *
 *
 * @param sig
 * @param width
 * @return The unknown cycle input
 */
public func GetUnknown<V, G>(
    sig : Signature<V, G>, width: Int64
) : CycleInput<V>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let signals = sig.EnumerateSignals(width)
    GetVariable(HashSet(signals))
}