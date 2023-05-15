/**
 * syntx/value.cj
 *
 * Contains the definition of Signals and Waveforms, constructs that
 * contain multiple values in different ways
 *
 * @author George Kaye
 * @since 0.2
 */
package syntax
import assertions.*
/**
 * A signal is an array of values.
 */
public struct Signal<V>
    <: ToString & HasName & Specifiable & HasWidth & Equatable<Signal<V>>
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    public Signal(
        public let values : Array<V>
    ){
        AssertNonEmpty(values)
    }
    /**
     * Create a signal with one value multiple times in parallel.
     *
     * @param v The value
     * @param n The number of times to have the value
     */
    public init(v: V, n : Int64) {
        this(Array<V>(n, {i : Int64 => v}))
    }
    /**
     * Create a signal of width 1
     *
     * @param v The single element of the signal
     */
    public init(v : V) {
        this([v])
    }
    public func GetName() : String {
        fold_right({acc : String, v : V => "${acc}${v}"}, "", values)
    }
    public func GetValues() : Array<V> {
        this.values
    }
    public func toString() : String {
        "${values}"
    }
    public func GetInputPorts() : Array<Port> {
        []
    }
    public func GetArity() : Int64 {
        0
    }
    public func GetOutputPorts() : Array<Port> {
        [Port(values.size)]
    }
    public func GetCoarity() : Int64 {
        1
    }
    public func GetWidth() : Int64 {
        this.values.size
    }
    public operator func ==(rhs : Signal<V>) : Bool {
        this.values == rhs.values
    }
    public operator func !=(rhs : Signal<V>) : Bool {
        !(this == rhs)
    }
    /**
     * @param v a value
     * @return Whether each element of this signal is v
     */
    public func IsAll(v : V) : Bool {
        for(value in this.values) {
            if(value != v) {
                return false
            }
        }
        true
    }
}
/**
 * Given an array of signals, get a string representing them as arguments to a
 * circuit, i.e. a string of the form (s1, s2, s3, ...)
 *
 * @param vs The array
 * @return The signa
 */
public func GetArgumentString<V>(vs : Array<Signal<V>>) : String
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    arrayToString(
        vs, { s => s.GetName() },
        openingBracket: "(", closingBracket: ")", delimiter: ", "
    )
}
public func GetOutputString<V>(vs : Array<Option<Signal<V>>>) : String
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    arrayToString(
        vs, { opt =>
            match(opt){
                case None => "?"
                case Some(s) => s.GetName()
            }
        }, openingBracket: "(", closingBracket: ")", delimiter: ","
    )
}
/**
 * Types of waveform used in circuits.
 */
public enum WaveformType {
    // A waveform with finitely many elements and an input wire
    | FINITE_OPEN
    // A waveform with finitely many elements followed by a disconnected value
    | FINITE_CLOSED
    // An waveform with finitely many elements under a loop
    | INFINITE
}
/**
 * Given an array of signals, get a string representing their waveform, i.e.
 * a string of the form s1 :: s2 :: s3 :: ...
 *
 * @param signals
 * @return The waveform string
 */
public func GetWaveformString<V>(signals : Array<Signal<V>>) : String
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    arrayToString(
        signals, { s : Signal<V> => s.GetName() },
        openingBracket: "", closingBracket: "", delimiter: " :: "
    )
}