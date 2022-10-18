/**
 * components/sequential
 *
 * Functions for using sequential components: delay and feedback
 *
 * @author George Kaye
 * @since 0.1
 */

package components

/**
 * Use a delay component for a given duration
 *
 * @param duration The length of the delay
 * @param input The input wire
 * @return The output of the delay
 */
public func UseDelay<V, G>(input: Wire<V, G>, duration!: Int64 = 1) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = input.GetWidth()
    var inputWire = input
    for(i in 0..duration) {
        inputWire = UseEdgeWithNewOutputs(
            Label<V,G>.DELAY(width),
            [input],
            None<InterfacedHypergraph<V, G>>
        )[0]
    }
    inputWire
}
/**
 * Use a simple register with an initial wire
 *
 * @param initial The wire serving as the initial output
 * @param input The input wire to the register
 * @return The output wire of the register
 */
public func UseSimpleRegister<V, G>(initial: Wire<V, G>, input : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = initial.GetWidth()
    let delay = UseDelay(input)
    UseEdgeWithNewOutputs(
        Label<V,G>.JOIN(width),
        [initial, delay],
        None
    )[0]
}
public func UseSimpleRegister<V, G>(initial : Signal<V>, input : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let wire = UseSignal<V, G>(initial)
    UseSimpleRegister(wire, input)
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
func PerformFeedback<V, G>(outgoing : Wire<V, G>, incoming : Wire<V, G>, instant : Bool) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertWireHasNoInEdge(incoming)
    let width = outgoing.GetWidth()
    AssertWiresSameWidth(outgoing, incoming)
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
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    PerformFeedback(outgoing, incoming, true)
}
/**
 * Create a feedback loop guarded by a delay: join a wire to a wire that is
 * not connected to anything on the left, and insert a delay of one tick on the loop
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 */
public func DelayGuardedFeedback<V, G>(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let delay = UseDelay(outgoing)
    PerformFeedback(delay, incoming, false)
}

public func RegisterGuardedFeedback<V, G>(
    input : Wire<V, G>,
    incoming : Wire<V, G>,
    initial : Wire<V, G>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
        AssertWiresSameWidth(incoming, input)
        let reg = UseSimpleRegister(initial, input)
        PerformFeedback(reg, incoming, false)
}
public func RegisterGuardedFeedback<V, G>(
    input : Wire<V, G>,
    incoming: Wire<V, G>,
    initial : Signal<V>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RegisterGuardedFeedback(input, incoming, UseSignal(initial))
}
public func MakeWaveform<V, G>(
    wf : Waveform<V>,
    wfType : WaveformType
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = wf.GetWidth()
    let vs = wf.signals
    let closed = match(wfType) {
        case FINITE_CLOSED => true
        case _ => false
    }
    var (currentWire, inputs, startingIndex) = if(closed) {
        (UseSignal<V, G>(vs[vs.size - 1]), Array<InterfaceWire<V, G>>(), 1)
    } else {
        let wire = UseWire<V, G>(width)
        (wire, [InterfaceWire(wire)], 0)
    }
    for(i in startingIndex..vs.size) {
        let value = UseSignal<V, G>(vs[vs.size - 1 - i])
        let delay = UseDelay(currentWire)
        currentWire = Join(value, delay)
    }
    match(wfType) {
        case INFINITE =>
            PerformFeedback(currentWire, inputs[0].GetWire(), false)
            inputs = Array<InterfaceWire<V, G>>()
        case _ => ()
    }
    MakeSubcircuit(
        inputs,
        [InterfaceWire(currentWire)],
        WAVEFORM(wf, wfType)
    )
}
public func MakeInfiniteWaveform<V, G>(
    wf : Waveform<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    MakeWaveform(wf, INFINITE)
}
public func MakeClosedWaveform<V, G>(
    wf : Waveform<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    MakeWaveform(wf, FINITE_CLOSED)
}
public func MakeOpenWaveform<V, G>(
    wf : Waveform<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    MakeWaveform(wf, FINITE_OPEN)
}
public func UseInfiniteWaveform<V, G>(
    wf : Waveform<V>
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseSubcircuit_1(
        MakeInfiniteWaveform(wf),
        Array<InterfaceWire<V, G>>()
    )
}
public func UseInfiniteWaveform<V, G>(signals : Array<Signal<V>>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseInfiniteWaveform(Waveform(signals))
}
public func UseInfiniteWaveform<V, G>(signal : Signal<V>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseInfiniteWaveform([signal])
}
public func UseClosedWaveform<V, G>(
    wf : Waveform<V>
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseSubcircuit_1(
        MakeClosedWaveform(wf),
        Array<InterfaceWire<V, G>>()
    )
}
public func UseClosedWaveform<V, G>(
    wf : Array<Signal<V>>
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseClosedWaveform(Waveform(wf))
}
public func UseOpenWaveform<V, G>(
    wf : Waveform<V>,
    inputs : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseSubcircuit_1(
        MakeOpenWaveform(wf),
        [inputs]
    )
}
public func UseOpenWaveform<V, G>(
    wf : Array<Signal<V>>,
    inputs : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseOpenWaveform(Waveform(wf), inputs)
}