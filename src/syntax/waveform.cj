/**
 * syntax/waveform.cj
 *
 * Struct for storing waveforms, sequences of signals over time.
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
/**
 * A waveform is a sequence of signals over time.
 *
 * A waveform has a *width*, which is the width of its underlying signals, and
 * a *length*, which is the length of the sequence. The length could be zero.
 */
public struct Waveform<V>
    <: HasName & HasWidth & ToString & Equatable<Waveform<V>>
    where V <: ValueSymbol<V>
{
    let signals : Array<Signal<V>>
    let width : Int64
    public init(signals : Array<Signal<V>>) {
        this.width = AssertAllSameWidth(signals)
        this.signals = signals
    }
    public init(signals : Array<V>) {
        this.signals = map({ v : V => Signal(v) }, signals)
        this.width = 1
    }
    public init(width : Int64) {
        this.signals = Array<Signal<V>>()
        this.width = width
    }
    public init(signal : Signal<V>) {
        this([signal])
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetName() : String {
        arrayToString(
            signals, { s : Signal<V> => s.GetName() },
            openingBracket: "", closingBracket: "", delimiter: " :: "
        )
    }
    public func toString() : String {
        this.GetName()
    }
    public operator func ==(rhs : Waveform<V>) : Bool {
        this.signals == rhs.GetSignals()
    }
    public operator func !=(rhs : Waveform<V>) : Bool {
        this.signals != rhs.GetSignals()
    }
    public func GetSignals() : Array<Signal<V>> {
        this.signals
    }
    public func GetSignalAtTick(i : Int64) : Signal<V> {
        AssertMinimumLength(signals, i+1)
        this.signals[i]
    }
    public func GetLength() : Int64 {
        this.signals.size
    }
}