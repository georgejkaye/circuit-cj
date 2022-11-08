/**
 * components/sequential
 *
 * Functions for using sequential components: delay and feedback
 *
 * @author George Kaye
 * @since 0.1
 */

package components

public interface SequentialBuilder<V, G> where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    // Delay
    func UseDelay(input : Wire<V, G>, duration!: Int64) : Wire<V, G>
    func UseSimpleRegister(initial : Wire<V, G>, input : Wire<V, G>) : Wire<V, G>
    func UseSimpleRegister(initial : Signal<V>, input : Wire<V, G>) : Wire<V, G>
    // Feedback
    func Feedback(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func DelayGuardedFeedback(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func RegisterGuardedFeedback(initial : Wire<V, G>, input : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func RegisterGuardedFeedback(initial : Signal<V>, input : Wire<V, G>, incoming : Wire<V, G>) : Unit
    // Waveforms
    func MakeOpenWaveform(signals : Array<Signal<V>>) : InterfacedHypergraph<V, G>
    func MakeOpenWaveform(values : Array<V>) : InterfacedHypergraph<V, G>
    func MakeClosedWaveform(signals : Array<Signal<V>>) : InterfacedHypergraph<V, G>
    func MakeClosedWaveform(values : Array<V>) : InterfacedHypergraph<V, G>
    func MakeInfiniteWaveform(signals : Array<Signal<V>>) : InterfacedHypergraph<V, G>
    func MakeInfiniteWaveform(values : Array<V>) : InterfacedHypergraph<V, G>
    func UseOpenWaveform(signals : Array<Signal<V>>, input : Wire<V, G>) : Wire<V, G>
    func UseOpenWaveform(values : Array<V>, input : Wire<V, G>) : Wire<V, G>
    func UseClosedWaveform(signals : Array<Signal<V>>) : Wire<V, G>
    func UseClosedWaveform(values : Array<V>) : Wire<V, G>
    func UseInfiniteWaveform(signals : Array<Signal<V>>) : Wire<V, G>
    func UseInfiniteWaveform(values : Array<V>) : Wire<V, G>
}
extend Signature<V, G> <: SequentialBuilder<V, G> {
    /**
     * Use a delay component for a given duration
     *
     * @param duration The length of the delay
     * @param input The input wire
     * @return The output of the delay
     */
    public func UseDelay(input: Wire<V, G>, duration!: Int64 = 1) : Wire<V, G> {
        let wire = input.GetWire()
        let width = wire.GetWidth()
        var inputWire = wire
        for(i in 0..duration) {
            inputWire = UseEdgeWithNewOutputs(
                Label<V,G>.DELAY(width),
                [wire],
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
    public func UseSimpleRegister(initial: Wire<V, G>, input : Wire<V, G>) : Wire<V, G> {
        let width = initial.GetWidth()
        let delay = UseDelay(input)
        UseEdgeWithNewOutputs(
            Label<V,G>.JOIN(width),
            [initial, delay],
            None
        )[0]
    }
    /**
     * Use a simple register with an initial signal
     *
     * @param initial The initial signal
     * @param input The input wire to the register
     * @return The output wire of the register
     */
    public func UseSimpleRegister(initial : Signal<V>, input : Wire<V, G>) : Wire<V, G> {
        let wire = this.UseSignal(initial)
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
    func PerformFeedback(outgoing : Wire<V, G>, incoming : Wire<V, G>, instant : Bool) : Unit {
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
    public func Feedback(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit {
        PerformFeedback(outgoing, incoming, true)
    }
    /**
     * Create a feedback loop guarded by a delay: join a wire to a wire that is
     * not connected to anything on the left, and insert a delay of one tick on the loop
     *
     * @param outgoing The wire to bend back
     * @param incoming The wire to feed back into, must not have an incoming edge
     */
    public func DelayGuardedFeedback(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit {
        let delay = this.UseDelay(outgoing)
        PerformFeedback(delay, incoming, false)
    }
    /**
     * Create a feedback loop guarded by a simple register: join a wire to a wire that is
     * not connected to anything on the left, and insert a register with a given initial wire
     * on the loop
     *
     * @param input The input to the register
     * @param incoming The wire to feed back to
     * @param initial The initial wire of the register
     */
    public func RegisterGuardedFeedback(
        initial : Wire<V, G>,
        input : Wire<V, G>,
        incoming : Wire<V, G>
    ) : Unit {
            AssertWiresSameWidth(incoming, input)
            let reg = this.UseSimpleRegister(initial, input)
            PerformFeedback(reg, incoming, false)
    }
    /**
     * Create a feedback loop guarded by a simple register: join a wire to a wire that is
     * not connected to anything on the left, and insert a register with a given initial signal
     * on the loop
     *
     * @param input The input to the register
     * @param incoming The wire to feed back to
     * @param initial The initial signal of the register
     */
    public func RegisterGuardedFeedback(
        initial : Signal<V>,
        input : Wire<V, G>,
        incoming: Wire<V, G>
    ) : Unit {
        this.RegisterGuardedFeedback(input, incoming, this.UseSignal(initial))
    }
    /**
     * Make a subcircuit for a waveform
     *
     * @param signals The signals that make up the waveform
     * @return The circuit containing the waveform
     */
    public func MakeOpenWaveform(
        signals : Array<Signal<V>>
    ) : InterfacedHypergraph<V, G> {
        AssertSignalArrayNonEmpty(signals)
        let width = AssertSignalsAllSameWidth(signals)
        let input = this.UseWire(width)
        var currentWire = input
        for(i in 0..signals.size) {
            // Construct the waveform from back to front
            let j = signals.size - i - 1
            let signal = this.UseSignal(signals[j])
            let delay = this.UseDelay(currentWire)
            let join = this.UseJoin(signal, delay)
            currentWire = join
        }
        this.MakeSubcircuit(
            [InterfaceWire(input)],
            [InterfaceWire(currentWire)],
            OPEN_WAVEFORM(signals)
        )
    }
    /**
     * Make a subcircuit for a waveform
     *
     * @param values The values that make up the waveform
     * @return The circuit containing the waveform
     */
    public func MakeOpenWaveform(
        values : Array<V>
    ) : InterfacedHypergraph<V, G> {
        this.MakeOpenWaveform(map({ v : V => Signal(v) }, values))
    }
    /**
     * Make a subcircuit for a closed waveform
     *
     * @param signals The signals that make up the waveform
     * @return The circuit containing the closed waveform
     */
    public func MakeClosedWaveform(
        signals : Array<Signal<V>>
    ) : InterfacedHypergraph<V, G> {
        AssertSignalArrayNonEmpty(signals)
        let width = AssertSignalsAllSameWidth(signals)
        let bottom = this.UseSignal(this.GetBottom(), width)
        let waveform = this.UseOpenWaveform(signals, bottom)
        this.MakeSubcircuit(
            [InterfaceWire(waveform)],
            Label<V, G>.CLOSED_WAVEFORM(signals)
        )
    }
    /**
     * Make a subcircuit for a closed waveform
     *
     * @param signals The signals that make up the waveform
     * @return The circuit containing the closed waveform
     */
    public func MakeClosedWaveform(
        values : Array<V>
    ) : InterfacedHypergraph<V, G> {
        this.MakeClosedWaveform(map({ v : V => Signal(v) }, values))
    }
    /**
     * Make a subcircuit for an infinite waveform
     *
     * @param signals The signals that make up the waveform
     * @return The circuit containing the infinite waveform
     */
    public func MakeInfiniteWaveform(
        signals : Array<Signal<V>>
    ) : InterfacedHypergraph<V, G> {
        AssertSignalArrayNonEmpty(signals)
        let width = AssertSignalsAllSameWidth(signals)
        let input = this.UseWire(width)
        let waveform = UseOpenWaveform(signals, input)
        this.PerformFeedback(waveform, input, false)
        this.MakeSubcircuit(
            [InterfaceWire(waveform)],
            Label<V, G>.INFINITE_WAVEFORM(signals)
        )
    }
    /**
     * Make a subcircuit for an infinite waveform
     *
     * @param signals The signals that make up the waveform
     * @return The circuit containing the infinite waveform
     */
    public func MakeInfiniteWaveform(
        values : Array<V>
    ) : InterfacedHypergraph<V, G> {
        this.MakeInfiniteWaveform(map({ v : V => Signal(v) }, values))
    }
    /**
     * Use a waveform
     *
     * @param signals The signals that make up the waveform
     * @param input The input to the waveform
     * @return The output wire of the waveform
     */
    public func UseOpenWaveform(
        signals : Array<Signal<V>>,
        input : Wire<V, G>
    ) : Wire<V, G> {
        this.UseSubcircuit_1(
            this.MakeOpenWaveform(signals),
            [input]
        )
    }
    /**
     * Use a waveform
     *
     * @param values The values that make up the waveform
     * @param input The input to the waveform
     * @return The output wire of the waveform
     */
    public func UseOpenWaveform(
        signals : Array<V>,
        input : Wire<V, G>
    ) : Wire<V, G> {
        this.UseSubcircuit_1(
            this.MakeOpenWaveform(signals),
            [input]
        )
    }
    /**
     * Use a closed waveform
     *
     * @param signals The signals that make up the waveform
     * @return The output wire of the waveform
     */
    public func UseClosedWaveform(
        signals : Array<Signal<V>>
    ) : Wire<V, G> {
        this.UseSubcircuit_1(
            this.MakeClosedWaveform(signals)
        )
    }
    /**
     * Use a closed waveform
     *
     * @param values The values that make up the waveform
     * @return The output wire of the waveform
     */
    public func UseClosedWaveform(
        values : Array<V>
    ) : Wire<V, G> {
        this.UseSubcircuit_1(
            this.MakeClosedWaveform(values)
        )
    }
    /**
     * Use an infinite waveform
     *
     * @param signals The signals that make up the waveform
     * @return The output wire of the waveform
     */
    public func UseInfiniteWaveform(
        signals : Array<Signal<V>>
    ) : Wire<V, G> {
        this.UseSubcircuit_1(
            this.MakeInfiniteWaveform(signals)
        )
    }
    /**
     * Use an infinite waveform
     *
     * @param values The values that make up the waveform
     * @return The output wire of the waveform
     */
    public func UseInfiniteWaveform(
        values : Array<V>
    ) : Wire<V, G> {
        this.UseSubcircuit_1(
            this.MakeInfiniteWaveform(values)
        )
    }
}