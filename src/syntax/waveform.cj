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
    public init(length : Int64, fn : (Int64) -> Signal<V>) {
        this.signals = Array(length, { i => fn(i) })
        this.width = AssertAllSameWidth(this.signals)
    }
    public init(signals : Array<V>) {
        this.signals = map({ v : V => Signal(v) }, signals)
        this.width = 1
    }
    public init(length : Int64, fn : (Int64) -> V) {
        this(length, { i => Signal(fn(i))} )
    }
    public init(width : Int64) {
        this.signals = Array<Signal<V>>()
        this.width = width
    }
    public init(signal : Signal<V>) {
        this([signal])
    }
    public init(signal : Signal<V>, length : Int64) {
        this(Array(length, { i => signal }))
    }
    public init(value : V, length : Int64) {
        this(Signal(value), length)
    }
    public init(values : Array<(Signal<V>, Int64)>) {
        this(ElementNumberArrayToArray(values))
    }
    public init(values : Array<(V, Int64)>) {
        this(ElementNumberArrayToArray(values))
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
        AssertLengthIsGreaterThanOrEqualTo(signals, i+1)
        this.signals[i]
    }
    public func GetLength() : Int64 {
        this.signals.size
    }
}

public func ArrayOfInputsToArrayOfTicks<V, T>(
    waveforms : Array<Waveform<V>>
) : Array<Array<Signal<V>>>
    where V <: ValueSymbol<V>, T <: HasWidth
{
    let numberOfInputs = waveforms.size
    let numberOfTicks = max(waveforms, { i, w => w.GetLength() })
    Array<Array<Signal<V>>>(numberOfTicks, { currentTickIndex : Int64 =>
        Array<Signal<V>>(numberOfInputs, { currentInputIndex : Int64 =>
            let currentInput = waveforms[currentInputIndex]
            let currentInputWidth = waveforms[currentInputIndex].GetWidth()
            if(currentTickIndex >= currentInput.GetLength()) {
                Signal(V.GetDisconnected(), currentInputWidth)
            } else {
                currentInput.GetSignalAtTick(currentTickIndex)
            }
        })
    })
}
public func GenerateClock<V>(
    rate!: Int64, cycles!: Int64, high!: V, low!: V
): Waveform<V>
    where V <: ValueSymbol<V>
{
    let length = 2 * rate * cycles
    let signals = Array<Signal<V>>(length, { i : Int64 =>
        if(i % (rate * 2) < rate) {
            Signal(high)
        } else {
            Signal(low)
        }
    })
    Waveform(signals)
}