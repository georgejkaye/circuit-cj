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
public func Delay(input: Wire, duration!: Int64 = 1) : Wire {
    let width = input.GetWidth()
    var inputWire = input
    for(i in 0..duration) {
        inputWire = MakeEdgeWithNewOutputs<Wire>(
            DELAY(1, width),
            [input],
            None<InterfacedHypergraph>
        )[0]
    }
    inputWire
}
/**
 * Use a simple register: a join of some value and a delay
 *
 * @param initial The initial value of the register
 * @param signed Whether the initial value is signed
 * @param input The input to the register
 * @return The output wire of the register
 */
public func SimpleRegister(initial! : Int64, signed! : Bool, input! : Wire) : Wire {
    let width = input.GetWidth()
    let value = if (signed) {
        SignedValueFromInt(initial, width: width)
    } else {
        UnsignedValueFromInt(initial, width: width)
    }
    SimpleRegisterWithInitial(value, input)
}
/**
 * Use a simple register with an initial wire
 *
 * @param initial The wire serving as the initial output
 * @param input The input wire to the register
 * @return The output wire of the register
 */
func SimpleRegisterWithInitial(initial: Wire, input : Wire){
    let width = initial.GetWidth()
    let delay = Delay(input)
    MakeEdgeWithNewOutputs(
        JOIN(width),
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
func PerformFeedback(outgoing : Wire, incoming : Wire, instant : Bool) {
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
public func Feedback(outgoing : Wire, incoming : Wire) : Unit {
    PerformFeedback(outgoing, incoming, true)
}
/**
 * Create a feedback loop guarded by a delay: join a wire to a wire that is
 * not connected to anything on the left, and insert a delay of one tick on the loop
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 */
public func DelayGuardedFeedback(outgoing : Wire, incoming : Wire) : Unit {
    let delay = Delay(outgoing)
    PerformFeedback(delay, incoming, false)
}
/**
 * Create a feedback loop guarded by a delay: join a wire to a wire that is
 * not connected to anything on the left, and insert a register with some initial
 * value on the loop
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 */
public func RegisterGuardedFeedback(incoming : Wire, initial!: Int64, signed!: Bool, input!: Wire) : Unit {
    let reg = SimpleRegister(initial: initial, signed: signed, input: input)
    PerformFeedback(reg, incoming, false)
}
/**
 * Create an infinite waveform: a construct that outputs the same thing for
 * every tick of the clock
 *
 * @param initial The value of the waveform
 * @return The output of the waveform
 */
public func InfiniteWaveform(initial : Wire) : Wire {
    let input = MakeWire(initial.GetWidth())
    let reg = SimpleRegisterWithInitial(initial, input)
    PerformFeedback(reg, input, false)
    reg
}
/**
 * Create an infinite waveform: a construct that outputs the same value for
 * every tick of the clock
 *
 * @param value The value of the waveform
 * @return The output of the waveform
 */
public func InfiniteWaveform(value : Value) : Wire {
    InfiniteWaveform(Signal(value))
}