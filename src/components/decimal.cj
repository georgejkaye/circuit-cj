/**
 * components/decimal.cj
 *
 * Definition of `Decimal` interface, for defining arrays of values
 * corresponding to decimal numbers
 *
 * @author George Kaye
 * @since 0.3
 */
package components
/**
 * Interface for value sets that can be interpreted as decimal values.
 */
public interface Decimal<V>
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    /**
     * Convert a number to an unsigned signal of values of a given width.
     *
     * @param x
     * @param width
     * @return The corresponding signal
     */
    static func UnsignedDecToSignal(x : Int64, width : Int64) : Signal<V>
    /**
     * Convert a number to an signed signal of values of a given width.
     *
     * @param x
     * @param width
     * @return The corresponding signal
     */
    static func SignedDecToSignal(x : Int64, width : Int64) : Signal<V>
    /**
     * Convert a number to an signal of values of a given width.
     *
     * @param x
     * @param width
     * @param signed
     * @return The corresponding signal
     */
    static func DecToSignal(
        x  : Int64, width : Int64, signed : Bool
    ) : Signal<V>
    /**
     * Attempt to convert an unsigned signal to a decimal number. Returns None
     * if this is not possible for the given signal.
     *
     * @param signal
     * @return The corresponding number if possible, or None if not
     */
    static func UnsignedSignalToDec(signal : Signal<V>) : Option<Int64>
    /**
     * Attempt to convert a signed signal to a decimal number. Returns None
     * if this is not possible for the given signal.
     *
     * @param signal
     * @return The corresponding number if possible, or None if not
     */
    static func SignedSignalToDec(signal : Signal<V>) : Option<Int64>
    /**
     * Attempt to convert a signal to a decimal number. Returns None
     * if this is not possible for the given signal.
     *
     * @param signal
     * @param signed Whether to interpret the signal as signed
     * @return The corresponding number if possible, or None if not
     */
    static func SignalToDec(signal : Signal<V>, signed : Bool) : Option<Int64>
}
/**
 * Given a signal, attempt to convert it to decimal and return it as a string;
 * if it fails, return the string of the original signal instead.
 *
 * @param signal
 * @param signed
 * @return The string representing the signal, in decimal if possible
 */
public func MaybeDecimalToString<V>(
    signal : Signal<V>, signed: Bool
) : String
    where V <: Decimal<V>
{
    match(V.SignalToDec(signal, signed)) {
        case None => signal.GetName()
        case Some(n) => "${n}"
    }
}
public func GetArgumentString<V>(vs : Array<Signal<V>>, signed!: Bool) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    GetArgumentString(vs, printFn: { s => MaybeDecimalToString(s, signed) })
}
public func GetOutputString<V>(
    vs : Array<Option<Signal<V>>>, signed!: Bool
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    GetOutputString(vs, printFn: { s => MaybeDecimalToString(s, signed)})
}
/**
 * Make a signal circuit for a signal converted from a decimal number.
 *
 * @param x
 * @param width
 * @param signed
 * @return The interfaced hypergraph containing the circuit
 */
public func MakeSignalFromInt<V, G>(
    x : Int64, width : Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Decimal<V>,
        G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(x, width, signed)
    MakeSignal(signal)
}
/**
 * Given an array of numbers, convert them into an array of corresponding
 * signals.
 *
 * @param vs The numbers
 * @param width
 * @param signed
 * @return The array of corresponding signals
 */
func MakeDecimalWaveform<V>(
    vs : Array<Int64>, width: Int64, signed: Bool
) : Waveform<V>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>
{
    let signals = map({ v : Int64 => V.DecToSignal(v, width, signed)}, vs)
    Waveform(signals)
}
/**
 * Convert an array of numbers into an open waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the open waveform
 */
public func MakeOpenWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Decimal<V>,
        G <: PrimitiveSymbol<V, G>
{
    let waveform = MakeDecimalWaveform<V>(xs, width, signed)
    MakeOpenWaveform(waveform)
}
/**
 * Convert an array of numbers into a closed waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the closed waveform
 */
public func MakeClosedWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = MakeDecimalWaveform<V>(xs, width, signed)
    MakeClosedWaveform(waveform)
}
/**
 * Convert an array of numbers into an infinite waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the infinite waveform
 */
public func MakeInfiniteWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = MakeDecimalWaveform<V>(xs, width, signed)
    MakeInfiniteWaveform(waveform)
}
/**
 * Use a signal circuit corresponding to a number.
 *
 * @param x
 * @param width
 * @param signed
 * @return The output wire of the signal
 */
public func UseSignalFromInt<V, G>(
    x : Int64, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(x, width, signed)
    UseSignal(signal)
}
/**
 * Use a signal circuit corresponding to zero.
 *
 * @param width
 * @return The output wire of the zero signal
 */
public func UseInstantZero<V, G>(width!: Int64) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    UseSignalFromInt(0, width: width, signed: false)
}
/**
 * Use an open waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param input The input wire to the waveform
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
func UseOpenWaveformFromInt<V, G>(
    xs : Array<Int64>,  input : Wire<V, G>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = MakeDecimalWaveform<V>(xs, width, signed)
    UseOpenWaveform(waveform, input)
}
/**
 * Use a closed waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
func UseClosedWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = MakeDecimalWaveform<V>(xs, width, signed)
    UseClosedWaveform(waveform)
}
/**
 * Use an infinite waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
func UseInfiniteWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = MakeDecimalWaveform<V>(xs, width, signed)
    UseInfiniteWaveform(waveform)
}
/**
 * Use an infinite waveform circuit that constantly outputs zero.
 *
 * @param width
 * @return The output wire of the zero waveform
 */
public func UseConstantZero<V, G>(width!: Int64) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    UseInfiniteWaveformFromInt([0], width: width, signed: false)
}
/**
 * Interface containing functions for using signals and waveforms converted
 * from decimal.
 */
public interface DecimalSignalUser<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    func UseSignalFromInt(
        x : Int64, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseSignalFromInt<V, G>(x, width: width, signed: signed)
    }
    func UseInstantZero(width!: Int64) : Wire<V, G> {
        UseInstantZero<V, G>(width: width)
    }
    func UseConstantZero(width!: Int64) : Wire<V, G> {
        UseConstantZero<V, G>(width: width)
    }
    func UseOpenWaveformFromInt(
        xs : Array<Int64>, input: Wire<V, G>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseOpenWaveformFromInt<V, G>(xs, input, width: width, signed: signed)
    }
    func UseClosedWaveformFromInt(
        xs : Array<Int64>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseClosedWaveformFromInt<V, G>(xs, width: width, signed: signed)
    }
    func UseInfiniteWaveformFromInt(
        xs : Array<Int64>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseInfiniteWaveformFromInt<V, G>(xs, width: width, signed: signed)
    }
}
extend Signature<V, G> <: DecimalSignalUser<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{}
/**
 * Use a simple register with an initial value converted from a number.
 *
 * @param initial
 * @param width
 * @param signed
 * @param input The input to the register
 * @return The output wire of the register
 */
public func UseSimpleRegister<V, G>(
    initial : Int64,
    width : Int64,
    signed : Bool,
    input : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(initial, width, signed)
    UseSimpleRegister(signal, input)
}
/**
 * Perform register guarded feedback with an initial value converted from a
 * number.
 *
 * @param initial
 * @param width
 * @param signed
 * @param input The wire to feed back
 * @param incoming The wire to connect the feedback to
 */
public func RegisterGuardedFeedback<V, G>(
    initial : Int64, width : Int64, signed : Bool,
    input : Wire<V, G>, incoming : Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(initial, width, signed)
    RegisterGuardedFeedback(signal, input, incoming)
}

public interface DecimalDrawable {
    /**
     * Write the dot graph for a graph to a file with a given name, with the
     * option to toggle representing signals as decimal numbers.
     * @param depth The maximum depth of subgraphs to draw
     * @param file The file name to write to
     * @param signed Whether to interpret signals as signed or not
     * @param debug Whether to print debug info on the graph
     */
    func WriteDotToFile(
        file : String, depth!: Int64, signed!: Bool, debug!: Bool,
        expandSignals!: Bool
    ) : Unit
}
extend Label<V, G>
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func GetDecimalName(signed!: Bool) : String {
        match(this){
            case VALUE(v) =>
                Signal([v]).GetDecimalName(signed: signed)
            case SIGNAL(s) =>
                s.GetDecimalName(signed: signed)
            case REGISTER(s) =>
                "${s.GetDecimalName(signed: signed)} ::"
            case CLOSED_WAVEFORM(wf) =>
                wf.GetDecimalName(signed: signed)
            case OPEN_WAVEFORM(wf) =>
                "${wf.GetDecimalName(signed: signed)} ::"
            case INFINITE_WAVEFORM(wf) =>
                "${wf.GetDecimalName(signed: signed)}^\u{03C9}"
            case _ =>
                this.GetName()
        }
    }
}

public func GetDecimalLabelFn<V, G>(signed : Bool) : (Label<V, G>) -> String
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    { label : Label<V, G> => label.GetDecimalName(signed: signed) }
}

extend Hypergraph<V, G> <: DecimalDrawable
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0, signed!: Bool, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        WriteDotToFile(
            file, depth: depth, edgeLabelFn: GetDecimalLabelFn(signed),
            debug: debug, expandSignals: expandSignals
        )
    }
}
extend InterfacedHypergraph<V, G> <: DecimalDrawable
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0, signed!: Bool, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        WriteDotToFile(
            file, depth: depth, edgeLabelFn: GetDecimalLabelFn(signed),
            debug: debug, expandSignals: expandSignals
        )
    }
}

extend Signal<V> where V <: Decimal<V> & ValueSymbol<V> {
    public func GetDecimalName(signed!: Bool) : String {
        match(V.SignalToDec(this, signed)){
            case Some(n) => "${n}"
            case None => this.GetName()
        }
    }
}

extend Waveform<V> where V <: Decimal<V> & ValueSymbol<V> {
    public func GetDecimalName(signed!: Bool) : String {
        arrayToString(
            this.GetSignals(),
            { s : Signal<V> => match(V.SignalToDec(s, signed)){
                case Some(n) => "${n}"
                case None => s.GetName()
            }},
            openingBracket: "", closingBracket: "", delimiter: "::"
        )
    }
}