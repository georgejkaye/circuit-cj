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
func UseValue<V, G>(v : V) : Wire<V, G>
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
func UseSignal<V, G>(
    spec : Signal<V>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    if(spec.GetWidth() == 1) {
        UseValue(spec.GetBit(0))
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
public func UseVariableSignal<V, G>(vs : VariableSignal<V>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseEdgeWithNewOutputs<V, G, Vertex<V, G>>(
        Label<V, G>.PARTIAL(vs), Array<Vertex<V, G>>(),
        None<InterfacedHypergraph<V, G>>, None<Hypergraph<V, G>>
    )[0]
}
public func UseCycleInput<V, G>(ci : CycleInput<V>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    match(ci) {
        case DEFINITE(s) => UseSignal(s)
        case PARTIAL(p) => UseVariableSignal(p)
    }
}
/**
 * Use a delay component for a given duration
 *
 * @param input The input wire
 * @param duration The length of the delay
 * @return The output of the delay
 */
public func UseDelay<V, G>(
    input: Wire<V, G>, duration!: Int64 = 1
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonNegative(duration)
    if(duration == 0) {
        input
    } else {
        let width = input.GetWidth()
        var inputWire = input
        fold_left(
            { prevWire, _ =>
                UseEdgeWithNewOutputs(
                    Label<V, G>.DELAY(prevWire.GetWidth()),
                    [prevWire],
                    None<InterfacedHypergraph<V, G>>,
                    input.GetGraph()
                )[0]
            }, inputWire, start: 0, end: duration
        )
    }
}
/**
 * Use a delay component for multiple input wires for a given duration
 *
 * @param inputs The array of input wires
 * @param duration The length of the delay
 * @return The output of the delay
 */
public func UseDelays<V, G>(
    inputs : Array<Wire<V, G>>,
    delays!: Array<Int64> = Array(inputs.size, { _ => 1 })
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    mapi({ w : Wire<V, G>, i => UseDelay(w, duration: delays[i])}, inputs)
}
/**
 * Use a simple register with an initial signal
 *
 * @param initial The initial signal
 * @param input The input wire to the register
 * @return The output wire of the register
 */
public func UseSimpleRegister<V, G>(
    initial!: CycleInput<V>, input!: Wire<V, G>
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
    outgoing : Wire<V, G>, incoming : Wire<V, G>, instant: Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasNoInEdge(incoming)
    let width = outgoing.GetWidth()
    AssertBothSameWidth(outgoing, incoming)
    MergeWires(outgoing, incoming, instant: instant)
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
    outgoing : Wire<V, G>, incoming: Wire<V, G>, initial!: CycleInput<V>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let register = UseSimpleRegister(initial: initial, input: outgoing)
    PerformFeedback(register, incoming, false)
    register
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
    outgoing : Wire<V, G>, incoming: Wire<V, G>, initial!: V
) : Wire<V, G>
     where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RegisterGuardedFeedback(
        outgoing, incoming, initial: DEFINITE(Signal([initial]))
    )
}
/**
 * Use a waveform
 *
 * @param signals The signals that make up the waveform
 * @param input The input to the waveform
 * @return The output wire of the waveform
 */
func UseOpenWaveform<V, G>(
    waveform!: Waveform<V>, input!: Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(MakeOpenWaveform(waveform: waveform), [input])
}
/**
 * Use a waveform
 *
 * @param values The values that make up the waveform
 * @param input The input to the waveform
 * @return The output wire of the waveform
 */
func UseOpenWaveform<V, G>(
    signal!: Signal<V>, input!: Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseOpenWaveform(waveform: Waveform([DEFINITE(signal)]), input: input)
}
/**
 * Use a closed waveform
 *
 * @param signals The signals that make up the waveform
 * @return The output wire of the waveform
 */
func UseClosedWaveform<V, G>(waveform!: Waveform<V>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(MakeClosedWaveform(waveform: waveform))
}
/**
 * Use an infinite waveform
 *
 * @param signals The signals that make up the waveform
 * @return The output wire of the waveform
 */
func UseInfiniteWaveform<V, G>(waveform!: Waveform<V>) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    UseSubcircuit_1(MakeInfiniteWaveform(waveform: waveform))
}
/**
 * Make a simple register component
 *
 * @param initial The initial signal contained in this register
 * @return The simple register circuit
 */
public func MakeSimpleRegister<V, G>(
    initial : CycleInput<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = initial.GetWidth()
    let signal = UseCycleInput<V, G>(initial)
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
func MakeOpenWaveform<V, G>(
    waveform!: Waveform<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let input = UseWire<V, G>(waveform.GetWidth())
    var currentWire = input
    let waveformLength = waveform.GetLength()
    for(i in 0..waveformLength) {
        // Construct the waveform from back to front
        let j = waveformLength - i - 1
        let register =
            UseSimpleRegister(
                initial: waveform.GetSignalAtTick(j, false), input:currentWire
            )
        currentWire = register
    }
    MakeSubcircuit(
        [InterfaceWire(input)],
        [InterfaceWire(currentWire)],
        Label<V, G>.OPEN_WAVEFORM(waveform)
    )
}
/**
 * Make a subcircuit for a closed waveform
 *
 * @param signals The signals that make up the waveform
 * @return The circuit containing the closed waveform
 */
func MakeClosedWaveform<V, G>(
    waveform!: Waveform<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let waveformCircuit = Hypergraph<V, G>()
    let bottomWire = UseSignal<V, G>(V.GetDisconnected(), waveform.GetWidth())
    let waveformWire = UseOpenWaveform(waveform: waveform, input: bottomWire)
    MakeSubcircuit(
        [InterfaceWire(waveformWire)],
        Label<V, G>.CLOSED_WAVEFORM(waveform)
    )
}
/**
 * Make a subcircuit for an infinite waveform
 *
 * @param signals The signals that make up the waveform
 * @return The circuit containing the infinite waveform
 */
public func MakeInfiniteWaveform<V, G>(
    waveform!: Waveform<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWire = UseWire<V, G>(waveform.GetWidth())
    let waveformWire = UseOpenWaveform(waveform: waveform, input: inputWire)
    PerformFeedback(waveformWire, inputWire, false)
    MakeSubcircuit(
        [InterfaceWire(waveformWire)],
        Label<V, G>.INFINITE_WAVEFORM(waveform)
    )
}
/**
 * Interface for acccessing signal making functions without
 * needing to specify the generics, since these can't be
 * determined from the arguments
 */
public interface SignalUser<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func UseValue(v : V) : Wire<V, G> {
        UseValue<V, G>(v)
    }
    func UseSignal(v : V) : Wire<V, G> {
        UseValue<V, G>(v)
    }
    func UseSignal(values : Signal<V>) : Wire<V, G> {
        UseSignal<V, G>(values)
    }
    func UseSignal(v : V, i : Int64) : Wire<V, G> {
        UseSignal<V, G>(v, i)
    }
    func UseOpenWaveform(
        waveform!: Waveform<V>, input!: Wire<V, G>
    ) : Wire<V, G> {
        UseOpenWaveform<V, G>(waveform: waveform, input: input)
    }
    func UseClosedWaveform(waveform!: Waveform<V>) : Wire<V, G> {
        UseClosedWaveform<V, G>(waveform: waveform)
    }
    func UseInfiniteWaveform(waveform!: Waveform<V>) : Wire<V, G> {
        UseInfiniteWaveform<V, G>(waveform: waveform)
    }
    func UseCycleInput(ci : CycleInput<V>) : Wire<V, G> {
        UseCycleInput<V, G>(ci)
    }
}
extend Signature<V, G> <: SignalUser<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{}
/**
 * Given a root vertex, check if it is the root of a simple register: a join
 * of a signal on the left and a delay on the right. If it is, return the signal
 * contained within the register and the root of the delayed subgraph; if either
 * of these fails, return None. Note that there can be no signal but can still
 * be a delayed subgraph and vice versa, so one of the elements may be None
 * while the other is Some.
 *
 * @param v The root vertex
 * @return A pair containing
     0) The signal in the register if successful, None otherwise
     1) The source of the delay (the root of the 'later' part of the graph) if
            successful, None otherwise
 */
public func IsSimpleRegister<V, G>(
    v : Vertex<V, G>
) : (Option<Signal<V>>, Option<Vertex<V, G>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    match(v.GetInEdge()) {
        case None => (None, None)
        case Some(ec) =>
            let rootEdge = ec.GetEdge()
            if(!rootEdge.GetLabel().IsJoin()) {
                (None, None)
            } else {
                let signal = match(rootEdge.NextEdgeLeft(0)) {
                    case None => None<Signal<V>>
                    case Some(ec) => ec.GetEdge().GetLabel().GetMaybeSignal()
                }
                let vertex = match(rootEdge.NextEdgeLeft(1)) {
                    case None => None<Vertex<V, G>>
                    case Some(ec) =>
                        let potentialDelay = ec.GetEdge()
                        if(!potentialDelay.GetLabel().IsDelay()) {
                            None<Vertex<V, G>>
                        } else {
                            Some(potentialDelay.GetSource(0))
                        }
                }
                (signal, vertex)
            }
    }
}
/**
 * Left-compose some arguments to a circuit.
 *
 * @param f
 * @param argInputs The inputs to the arguments, if they are open
 * @param argOutputs The outputs to the arguments
 * @param argStrings The strings describing each argument
 * @return The circuit with the given arguments applied
 */
func Apply<V, G>(
    f : InterfacedHypergraph<V, G>, argInputs : Array<Option<Wire<V, G>>>,
    argOutputs : Array<Option<Wire<V, G>>>, argStrings : Array<Option<String>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let graph = f.Clone()
    let actualInputs = mapi({
        ow : Option<Wire<V, G>>, i : Int64 =>
            match(ow) {
                case Some(w) => w
                case None => UseWire<V, G>(f.GetInput(i).GetWidth())
            }
        }, argInputs
    )
    let actualOutputs = mapi({
            ow : Option<Wire<V, G>>, i : Int64 =>
                match(ow) {
                    case Some(w) => w
                    case None => actualInputs[i]
                }
        }, argOutputs
    )
    let outputs = UseSubcircuit(f, actualOutputs)
    let inputInterfaces = ArrayList<InterfaceWire<V, G>>()
    forEach({
        ow : Option<Wire<V, G>>, i : Int64 =>
            let wire = match(ow) {
                case None => ()
                case Some(w) =>
                    let iw = InterfaceWire(w, f.GetInput(i).GetName())
                    inputInterfaces.append(iw)
            }
        }, argInputs
    )
    let outputInterfaces = mapi({
        w : Wire<V, G>, i : Int64 => InterfaceWire(w, f.GetOutput(i).GetName())
    }, outputs)
    let argPrinter = {
        arg : Option<String> =>
            match(arg) {
                case Some(a) => a
                case None => "-"
            }
    }
    let argumentString = concatStrings(argPrinter, argStrings, delimiter: ", ")
    MakeSubcircuit(
        inputInterfaces.toArray(),
        outputInterfaces,
        "${f.GetName()}(${argumentString})"
    )
}
/**
 * Left-compose some signals to a circuit.
 *
 * @param f
 * @param signals
 * @return The circuit with the given arguments applied
 */
public func Apply<V, G>(
    f : InterfacedHypergraph<V, G>, signals : Array<Signal<V>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let inputWires = map({ s : Signal<V> => Some(UseSignal<V, G>(s)) }, signals)
    let inputStrings = map({ s : Signal<V> => Some(s.GetName()) }, signals)
    Apply(
        f, Array<Option<Wire<V, G>>>(f.GetArity(), { i => None<Wire<V, G>> }),
        inputWires, inputStrings
    )
}
/**
 * Left-compose some values to a circuit.
 *
 * @param f
 * @param values
 * @return The circuit with the given arguments applied
 */
public func Apply<V, G>(
    f : InterfacedHypergraph<V, G>, values : Array<V>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Apply(f, map({ v => Signal([v]) }, values))
}
/**
 * Left-compose some waveforms to a circuit.
 *
 * @param f
 * @param signals
 * @return The circuit with the given arguments applied
 */
public func Apply<V, G>(
    f : InterfacedHypergraph<V, G>, inputs : Array<Waveform<V>>,
    wfType : WaveformType
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let argInputs = map({
        wf : Waveform<V> =>
            match(wfType){
                case OPEN => UseWire<V, G>(wf.GetWidth())
                case _ => None<Wire<V, G>>
            }
        }, inputs
    )
    let argOutputs = mapi({
        wf : Waveform<V>, i : Int64 =>
            let wire = match(wfType) {
                case OPEN => UseOpenWaveform<V, G>(
                    waveform: wf, input: argInputs[i].getOrThrow()
                )
                case CLOSED => UseClosedWaveform<V, G>(waveform: wf)
                case INFINITE => UseInfiniteWaveform<V, G>(waveform: wf)
            }
            Some(wire)
        }, inputs
    )
    let argStrings = map({ wf : Waveform<V> => Some(wf.GetName()) }, inputs)
    Apply<V, G>(f, argInputs, argOutputs, argStrings)
}
/**
 * Left-compose some partially specified to a circuit.
 *
 * @param f
 * @param inputs
 * @return The circuit with the given arguments applied
 */
public func Apply<V, G>(
    f : InterfacedHypergraph<V, G>, inputs : Array<VariableSignal<V>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasLength(inputs, f.GetArity())
    let argInputs = Array<Option<Wire<V, G>>>(
        inputs.size, { i => None<Wire<V, G>> }
    )
    let argOutputs = mapi({
        pi : VariableSignal<V>, i : Int64 =>
            Some(UseEdgeWithNewOutputs(
                Label<V,G>.PARTIAL(pi), Array<Vertex<V, G>>(),
                None, f.GetGraph()
            )[0])
    }, inputs)
    let argStrings = map({ pi : VariableSignal<V> => Some(pi.GetName()) }, inputs)
    Apply(f, argInputs, argOutputs, argStrings)
}