/**
 * syntax.decimal
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
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
    static func UnsignedDecToSignal(x : Int64, width!: Int64) : Signal<V>
    /**
     * Convert a number to an signed signal of values of a given width.
     *
     * @param x
     * @param width
     * @return The corresponding signal
     */
    static func SignedDecToSignal(x : Int64, width!: Int64) : Signal<V>
    /**
     * Convert a number to an signal of values of a given width.
     *
     * @param x
     * @param width
     * @param signed
     * @return The corresponding signal
     */
    static func DecToSignal(
        x  : Int64, width!: Int64, signed!: Bool
    ) : Signal<V> {
        if(signed) {
            SignedDecToSignal(x, width: width)
        } else {
            UnsignedDecToSignal(x, width: width)
        }
    }
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
    static func SignalToDec(signal : Signal<V>, signed!: Bool) : Option<Int64> {
        if(signed) {
            SignedSignalToDec(signal)
        } else {
            UnsignedSignalToDec(signal)
        }
    }
}
/**
 * Given a signal, attempt to convert it to decimal and return it as a string;
 * if it fails, return the string of the original signal instead.
 *
 * @param signal
 * @param signed
 * @return The string representing the signal, in decimal if possible
 */
public func MaybeDecimalToString<V>(signal : Signal<V>, signed: Bool) : String
    where V <: Decimal<V>
{
    match(V.SignalToDec(signal, signed: signed)) {
        case None => signal.GetName()
        case Some(n) => "${n}"
    }
}
/**
 * Get a comma separated string of arguments represented in decimal
 *
 * @param args
 * @param signed
 * @return The argument string in decimal
 */
public func GetArgumentString<V>(
    args : Array<Signal<V>>, signed!: Bool
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    GetArgumentString(args, printFn: { s => MaybeDecimalToString(s, signed) })
}
public func GetOutputString<V>(
    vs : Array<Option<Signal<V>>>, signed!: Bool
) : String
    where V <: ValueSymbol<V> & Decimal<V>
{
    GetOutputString(vs, printFn: { s => MaybeDecimalToString(s, signed)})
}
extend Signal<V> where V <: Decimal<V> & ValueSymbol<V> {
    public func GetDecimalName(signed!: Bool) : String {
        match(V.SignalToDec(this, signed: signed)){
            case Some(n) => "${n}"
            case None => this.GetName()
        }
    }
}
extend Waveform<V> where V <: Decimal<V> & ValueSymbol<V> {
    public func GetDecimalName(signed!: Bool) : String {
        arrayToString(
            this.GetSignals(),
            { s : Signal<V> => match(V.SignalToDec(s, signed: signed)){
                case Some(n) => "${n}"
                case None => s.GetName()
            }},
            openingBracket: "", closingBracket: "", delimiter: "::"
        )
    }
}
extend Label<V, G>
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func GetDecimalName(signed!: Bool) : String {
        match(this){
            case VALUE(v) =>
                "${v}"
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
public func BuildWaveform<V> (
    signals!: Array<Int64>, width!: Int64, signed!: Bool
)
    where V <: ValueSymbol<V> & Decimal<V>
{
    let actualSignals =
    map(
        { v : Int64 => V.DecToSignal(v, width: width, signed: signed)},
        signals
    )
    Waveform(actualSignals)
}
extend Signature<V, G>
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    /**
     * Given an array of numbers, convert them into an array of corresponding
     * signals.
     *
     * @param vs The numbers
     * @param width
     * @param signed
     * @return The array of corresponding signals
     */
    public func BuildWaveform(
        signals!: Array<Int64>, width!: Int64, signed!: Bool
    ) : Waveform<V> {
        BuildWaveform<V>(signals: signals, width: width, signed: signed)
    }
}