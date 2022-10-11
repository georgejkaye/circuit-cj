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
public func SimpleRegister<V, G>(initial: Wire<V, G>, input : Wire<V, G>) : Wire<V, G>
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
    incoming : Wire<V, G>,
    initial : Wire<V, G>,
    input : Wire<V, G>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
        let reg = SimpleRegister(initial, input)
        PerformFeedback(reg, incoming, false)
}
/**
 * Create an infinite waveform: a construct that outputs the same thing for
 * every tick of the clock
 *
 * @param initial The circuit that will be output for each tick of the clock
 * @return The output of the waveform
 */
public func InfiniteWaveform<V, G>(initial : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let input = UseWire<V, G>(initial.GetWidth())
    let reg = SimpleRegister(initial, input)
    PerformFeedback(reg, input, false)
    reg
}
/**
 * Create an infinite waveform: a construct that outputs the same value for
 * every tick of the clock
 *
 * @param value The value that will be output for each tick of the clock
 * @return The output of the waveform
 */
public func InfiniteWaveform<V, G>(value : V) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    InfiniteWaveform(UseValue(value))
}

public func MakeWaveform<V, G>(
    wf : Waveform<V>,
    closed!: Bool = true
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = wf.GetWidth()
    let vs = wf.signals
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
    MakeSubcircuit(
        inputs,
        [InterfaceWire(currentWire)],
        wf.toString()
    )
}