/**
 * components/sequential
 *
 * Functions for using sequential components: state, delay and feedback
 *
 * @author George Kaye
 * @since 0.1
 */
package components
/**
 * Make a subcircuit containing a signal
 *
 * @param spec The signal
 * @return The circuit containing the signal
 */
public func MakeSignal<V, G>(
    signal : Signal<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let outputWires = map(
        { v : V => UseValue<V, G>(v) },
        signal.GetValues()
    )
    let outputWire = Combine(outputWires)
    let signalLabel = Label<V, G>.SIGNAL(signal)
    MakeSubcircuit([InterfaceWire(outputWire)], signalLabel)
}
/**
 * Make a subcircuit containing a a signal defined as multiple copies of a
 * single value
 *
 * @param v The value
 * @param width The width of the signal
 * @return The output wire
 */
public func MakeSignal<V, G>(
    v : V, width : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = Signal(Array<V>(width){ i : Int64 => v })
    MakeSignal(signal)
}
/**
* Use a value
*
* @param v The value to use
* @return The output of the value
*/
public func UseValue<V, G>(v : V) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseEdgeWithNewOutputs<V, G, Vertex<V, G>>(
        Label<V, G>.VALUE(v),
        Array<Vertex<V, G>>(),
        None<InterfacedHypergraph<V, G>>,
        Hypergraph<V, G>()
    )[0]
}
    /**
* Use a signal
*
* @param spec The signal to use
* @return The output of the signal circuit
*/
public func UseSignal<V, G>(
    spec : Signal<V>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    if(spec.GetWidth() == 1) {
        UseValue(spec.values[0])
    } else {
        UseSubcircuit_1(
            MakeSignal<V, G>(spec),
            Array<Wire<V, G>>()
        )
    }
}
/**
* Use a signal cosntructed as multiple copies of a single value
*
* @param v The value to use
* @param i The number of this value to use
* @return The output of the signal circuit
*/
public func UseSignal<V, G>(v : V, i : Int64) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let array : Array<V> = Array<V>(i, {i : Int64 => v})
    UseSignal(Signal(array))
}
/**
 * Interface for acccessing signal making functions without
 * needing to specify the generics, since these can't be
 * determined from the arguments
 */
public interface SignalUser<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func UseSignal(v : V) : Wire<V, G> {
        UseValue<V, G>(v)
    }
    func UseSignal(spec : Signal<V>) : Wire<V, G> {
        UseSignal<V, G>(spec)
    }
    func UseSignal(v : V, i : Int64) : Wire<V, G> {
        UseSignal<V, G>(v, i)
    }
}
extend Signature<V, G> <: SignalUser<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{}
/**
 * Use a delay component for a given duration
 *
 * @param duration The length of the delay
 * @param input The input wire
 * @return The output of the delay
 */
public func UseDelay<V, G>(
    input: Wire<V, G>, duration!: Int64 = 1
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = input.GetWidth()
    var inputWire = input
    for(i in 0..duration) {
        inputWire = UseEdgeWithNewOutputs(
            Label<V,G>.DELAY(width),
            [inputWire],
            None<InterfacedHypergraph<V, G>>,
            input.GetGraph()
        )[0]
    }
    inputWire
}
/**
 * Use a simple register with an initial signal
 *
 * @param initial The initial signal
 * @param input The input wire to the register
 * @return The output wire of the register
 */
public func UseSimpleRegister<V, G>(
    initial : Signal<V>, input : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(
        MakeSimpleRegister(initial),
        [input]
    )
}
/**
 * Join two wires together to form a feedback loop. Variant for internal use
 * only, allows the specification of whether this in an 'instant' or a
 * 'delay-guarded' loop, which is crucial for rewriting.
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 * @param instant Whether this is instant feedback or not.
 */
func PerformFeedback<V, G>(
    outgoing : Wire<V, G>, incoming : Wire<V, G>, instant : Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasNoInEdge(incoming)
    let width = outgoing.GetWidth()
    AssertAllSameWidth(outgoing, incoming)
    MergeWires(outgoing, incoming, instant)
}
/**
 * Create a feedback loop: join a wire to a wire that is not connected
 * to anything on the left
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 */
public func Feedback<V, G>(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    PerformFeedback(outgoing, incoming, true)
}
/**
 * Create a feedback loop guarded by a delay: join a wire to a wire that is
 * not connected to anything on the left, and insert a delay of one tick on the
 * loop
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 */
public func DelayGuardedFeedback<V, G>(
    outgoing : Wire<V, G>, incoming : Wire<V, G>
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let delay = UseDelay(outgoing)
    PerformFeedback(delay, incoming, false)
}
/**
 * Create a feedback loop guarded by a simple register: join a wire to a wire
 * that is not connected to anything on the left, and insert a register with a
 * given initial signal on the loop
 *
 * @param input The input to the register
 * @param incoming The wire to feed back to
 * @param initial The initial signal of the register
 */
public func RegisterGuardedFeedback<V, G>(
    initial : Signal<V>, outgoing : Wire<V, G>, incoming: Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>{
    let register = UseSimpleRegister(initial, outgoing)
    PerformFeedback(register, incoming, false)
    register
}
/**
 * Use a waveform
 *
 * @param signals The signals that make up the waveform
 * @param input The input to the waveform
 * @return The output wire of the waveform
 */
public func UseOpenWaveform<V, G>(
    signals : Array<Signal<V>>, input : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(MakeOpenWaveform(signals), [input])
}
/**
 * Use a waveform
 *
 * @param values The values that make up the waveform
 * @param input The input to the waveform
 * @return The output wire of the waveform
 */
public func UseOpenWaveform<V, G>(
    signal : Signal<V>,
    input : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseOpenWaveform([signal], input)
}
/**
 * Use a closed waveform
 *
 * @param signals The signals that make up the waveform
 * @return The output wire of the waveform
 */
public func UseClosedWaveform<V, G>(signals : Array<Signal<V>>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(MakeClosedWaveform(signals))
}
/**
 * Use an infinite waveform
 *
 * @param signals The signals that make up the waveform
 * @return The output wire of the waveform
 */
public func UseInfiniteWaveform<V, G>(signals : Array<Signal<V>>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(MakeInfiniteWaveform(signals))
}
/**
 * Make a simple register component
 *
 * @param initial The initial signal contained in this register
 * @return The simple register circuit
 */
public func MakeSimpleRegister<V, G>(
    initial : Signal<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = initial.GetWidth()
    let signal = UseSignal<V, G>(initial)
    let input = UseWire<V, G>(width)
    let delay = UseDelay(input)
    let join = UseJoin(signal, delay)
    MakeSubcircuit(
        [InterfaceWire(input)],
        [InterfaceWire(join)],
        Label<V, G>.REGISTER(initial)
    )
}
/**
* Make a subcircuit for a waveform
*
* @param signals The signals that make up the waveform
* @return The circuit containing the waveform
*/
public func MakeOpenWaveform<V, G>(
    signals : Array<Signal<V>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonEmpty(signals)
    let width = AssertAllSameWidth(signals)
    let input = UseWire<V, G>(width)
    var currentWire = input
    for(i in 0..signals.size) {
        // Construct the waveform from back to front
        let j = signals.size - i - 1
        let register = UseSimpleRegister(signals[j], currentWire)
        currentWire = register
    }
    MakeSubcircuit(
        [InterfaceWire(input)],
        [InterfaceWire(currentWire)],
        Label<V, G>.OPEN_WAVEFORM(signals)
    )
}
/**
 * Make a subcircuit for a closed waveform
 *
 * @param signals The signals that make up the waveform
 * @return The circuit containing the closed waveform
 */
public func MakeClosedWaveform<V, G>(
    signals : Array<Signal<V>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonEmpty(signals)
    let width = AssertAllSameWidth(signals)
    let waveformCircuit = Hypergraph<V, G>()
    let bottomWire = UseSignal<V, G>(V.GetDisconnected(), width)
    let waveformWire = UseOpenWaveform(signals, bottomWire)
    MakeSubcircuit(
        [InterfaceWire(waveformWire)],
        Label<V, G>.CLOSED_WAVEFORM(signals)
    )
}
/**
 * Make a subcircuit for an infinite waveform
 *
 * @param signals The signals that make up the waveform
 * @return The circuit containing the infinite waveform
 */
public func MakeInfiniteWaveform<V, G>(
    signals : Array<Signal<V>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonEmpty(signals)
    let width = AssertAllSameWidth(signals)
    let inputWire = UseWire<V, G>(width)
    let waveformWire = UseOpenWaveform(signals, inputWire)
    PerformFeedback(waveformWire, inputWire, false)
    MakeSubcircuit(
        [InterfaceWire(waveformWire)],
        Label<V, G>.INFINITE_WAVEFORM(signals)
    )
}