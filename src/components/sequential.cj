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
    func UseDelay(input : Wire<V, G>, duration!: Int64) : Wire<V, G>
    func UseSimpleRegister(initial : Wire<V, G>, input : Wire<V, G>) : Wire<V, G>
    func UseSimpleRegister(initial : Signal<V>, input : Wire<V, G>) : Wire<V, G>
    func Feedback(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func DelayGuardedFeedback(outgoing : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func RegisterGuardedFeedback(initial : Wire<V, G>, input : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func RegisterGuardedFeedback(initial : Signal<V>, input : Wire<V, G>, incoming : Wire<V, G>) : Unit
    func MakeWaveform(heads : Array<Array<Signal<V>>>, tail : Option<InterfacedHypergraph<V, G>>) : InterfacedHypergraph<V, G>
    func MakeInfiniteWaveform(heads : Array<Array<Signal<V>>>) : InterfacedHypergraph<V, G>
    func MakeInfiniteWaveform(heads : Array<Signal<V>>) : InterfacedHypergraph<V, G>
    func MakeClosedWaveform(heads : Array<Array<Signal<V>>>) : InterfacedHypergraph<V, G>
    func MakeClosedWaveform(heads : Array<Signal<V>>) : InterfacedHypergraph<V, G>
    func MakeClosedWaveform(width : Int64) : InterfacedHypergraph<V, G>
    func MakeOpenWaveform(heads : Array<Array<Signal<V>>>) : InterfacedHypergraph<V, G>
    func MakeOpenWaveform(heads : Array<Signal<V>>) : InterfacedHypergraph<V, G>
    func UseInfiniteWaveform(heads : Array<Array<Signal<V>>>) : Array<Wire<V, G>>
    func UseClosedWaveform(heads : Array<Array<Signal<V>>>) : Array<Wire<V, G>>
    func UseOpenWaveform(heads : Array<Array<Signal<V>>>, input : Wire<V, G>) : Array<Wire<V, G>>
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
     * @param heads The heads of the waveform
     * @param tail The circuit in the tail of the waveform
     * @return The circuit containing the waveform
     */
    public func MakeWaveform(
        heads : Array<Array<Signal<V>>>,
        tail : Option<InterfacedHypergraph<V, G>>
    ) : InterfacedHypergraph<V, G> {
        var tailGraph = tail
        for(i in 0..heads.size) {
            let j = heads.size - i - 1
            let currentSignals = heads[j]
            let (inputs, tailOutputs, tailLabel) = match(tailGraph) {
                case Some(f) =>
                    let inputs = mapi(
                        { iv : InterfaceVertex<V, G>, i : Int64 =>
                            InterfaceWire(this.UseWire(iv.GetWidth()), f.GetInput(i).name)
                        },
                        f.GetInputs()
                    )
                    let subcircuit = this.UseSubcircuit(
                        f,
                        map({iw : InterfaceWire<V, G> => iw.wire}, inputs)
                    )
                    (inputs, subcircuit, Some(f.GetLabel()))
                case None =>
                    let wires = Array<Wire<V, G>>(currentSignals.size){
                        i : Int64 =>
                            this.UseWire(currentSignals[i].GetWidth())
                    }
                    let interfaceWires = map({ w : Wire<V, G> => InterfaceWire(w, "") }, wires)
                    (interfaceWires, wires, None<Label<V, G>>)
            }
            let outputs = mapi({ s : Signal<V>, i : Int64 =>
                let signal = this.UseSignal(s)
                let delay = this.UseDelay(tailOutputs[i])
                let join = this.UseJoin(signal, delay)
                InterfaceWire(join, "")
            }, currentSignals)
            let label = WAVEFORM(currentSignals, tailLabel)
            tailGraph = this.MakeSubcircuit(
                inputs,
                outputs,
                label
            )
        }
        tailGraph.getOrThrow()
    }
    public func MakeWaveform(
        heads : Array<Array<Signal<V>>>
    ) {
        this.MakeWaveform(heads, None<InterfacedHypergraph<V, G>>)
    }
    /**
     * Make an infinite waveform
     *
     * @param heads The elements of the waveform
     * @return The circuit containing the waveform
     */
    public func MakeInfiniteWaveform(
        heads : Array<Array<Signal<V>>>
    ) : InterfacedHypergraph<V, G> {
        let waveform = MakeWaveform(heads, None<InterfacedHypergraph<V, G>>)
        Feedback(Wire(waveform.GetOutput(0).vertex), Wire(waveform.GetInput(0).vertex))
        waveform
    }
    public func MakeInfiniteWaveform(
        head : Array<Signal<V>>
    ) : InterfacedHypergraph<V, G> {
        this.MakeInfiniteWaveform([head])
    }
    /**
     * Make a closed waveform
     *
     * @param heads The elements of this waveform
     * @param width The width of elements of this waveform
     * @return The circuit containing the waveform
     */
    func MakeClosedWaveform(
        heads : Array<Array<Signal<V>>>,
        width : Int64
    ) : InterfacedHypergraph<V, G> {
        let bottoms = this.MakeSignal(this.GetBottom(), width)
        MakeWaveform(heads, bottoms)
    }
    /**
     * Make a closed waveform
     *
     * @param heads The elements of this waveform
     * @return The circuit containing the waveform
     */
    public func MakeClosedWaveform(
        heads : Array<Array<Signal<V>>>
    ) : InterfacedHypergraph<V, G> {
        AssertSignalArrayArrayNonEmpty(heads)
        MakeClosedWaveform(heads, heads[0][0].GetWidth())
    }
    public func MakeClosedWaveform(
        head : Array<Signal<V>>
    ) : InterfacedHypergraph<V, G> {
        this.MakeClosedWaveform([head])
    }
    /**
     * Make a closed waveform with no elements
     *
     * @param width The width of the waveform
     * @return The circuit containing the waveform
     */
    public func MakeClosedWaveform(
        width : Int64
    ) : InterfacedHypergraph<V, G> {
        this.MakeClosedWaveform(Array<Array<Signal<V>>>(), width)
    }
    /**
     * Make an open waveform
     *
     * @param heads The elements of the waveform
     * @return The circuit containing the waveform
     */
    public func MakeOpenWaveform(
        heads : Array<Array<Signal<V>>>
    ) : InterfacedHypergraph<V, G> {
        this.MakeWaveform(heads, None<InterfacedHypergraph<V, G>>)
    }
    public func MakeOpenWaveform(
        head : Array<Signal<V>>
    ) : InterfacedHypergraph<V, G> {
        this.MakeOpenWaveform([head])
    }
    /**
     * Use an infinite waveform
     *
     * @param heads The element of the waveform
     * @return The output wire of the waveform circuit
     */
    public func UseInfiniteWaveform(
        heads : Array<Array<Signal<V>>>
    ) : Array<Wire<V, G>> {
        this.UseSubcircuit(
            MakeInfiniteWaveform(heads),
            Array<Wire<V, G>>()
        )
    }
    /**
     * Use an infinite waveform
     *
     * @param signal The signal that specifies the waveform
     * @return The output of the waveform
     */
    public func UseInfiniteWaveform(signal : Signal<V>) : Array<Wire<V, G>> {
        UseInfiniteWaveform([[signal]])
    }
    /**
     * Use a closed waveform
     *
     * @param heads The elements of the waveform
     * @return The output of the waveform
     */
    public func UseClosedWaveform(
        heads : Array<Array<Signal<V>>>
    ) : Array<Wire<V, G>> {
        this.UseSubcircuit(
            MakeClosedWaveform(heads),
            Array<Wire<V, G>>()
        )
    }
    public func UseClosedWaveform(
        head : Array<Signal<V>>
    ) : Array<Wire<V, G>> {
        this.UseClosedWaveform([head])
    }
    /**
     * Use an open waveform
     *
     * @param heads The elements of the waveform
     * @param inputs The inputs to the waveform
     * @return The output of the waveform
     */
    public func UseOpenWaveform(
        heads : Array<Array<Signal<V>>>,
        input : Wire<V, G>
    ) : Array<Wire<V, G>> {
        this.UseSubcircuit(
            MakeOpenWaveform(heads),
            [input]
        )
    }
    public func UseOpenWaveform(
        head : Array<Signal<V>>,
        input : Wire<V, G>
    ) : Array<Wire<V, G>> {
        this.UseOpenWaveform([head], input)
    }
}