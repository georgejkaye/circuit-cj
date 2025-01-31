/**
 * syntax/waveform.cj
 *
 * Struct for storing waveforms, sequences of signals over time.
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
public enum WaveformType {
    | OPEN | CLOSED | INFINITE
}

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
    let signals : Array<CycleInput<V>>
    let width : Int64
    public init(signals : Array<CycleInput<V>>) {
        this.width = AssertAllHaveSameWidth(signals)
        this.signals = signals
    }
    public init(length : Int64, fn : (Int64) -> Signal<V>) {
        this.signals = Array(length, { i => DEFINITE(fn(i)) })
        this.width = AssertAllHaveSameWidth(this.signals)
    }
    public init(signals : Array<V>) {
        this.signals = map({ v : V => DEFINITE(Signal(v)) }, signals)
        this.width = 1
    }
    public init(length : Int64, fn : (Int64) -> V) {
        this(length, { i => Signal(fn(i))} )
    }
    // public init(width : Int64) {
    //     this.signals = Array<Signal<V>>()
    //     this.width = width
    // }
    public init(signal : Signal<V>) {
        this([DEFINITE(signal)])
    }
    public init(signal : Signal<V>, length : Int64) {
        this(Array(length, { i => DEFINITE(signal) }))
    }
    public init(value : V, length : Int64) {
        this(Signal(value), length)
    }
    public init(values : Array<(CycleInput<V>, Int64)>) {
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
            signals, { s : CycleInput<V>, _ => s.GetName() },
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
    public func GetSignals() : Array<CycleInput<V>> {
        this.signals
    }
    public func GetSignalAtTick(i : Int64, infinite : Bool) : CycleInput<V> {
        let index = if(infinite) {
            i % signals.size
        } else {
            AssertLengthIsGreaterThanOrEqualTo(signals, i+1)
            i
        }
        this.signals[index]
    }
    public func GetLength() : Int64 {
        this.signals.size
    }
}
/**
 * 'Transpose' an array of waveforms over time, producing an array of arrays
 * of signals, in which each element of the array is the array of signals at
 * a given tick of the clock.
 *
 * @param waveforms The array of waveforms
 * @return The array in which each element is an array of signals at a tick
 */
public func ArrayOfInputsToArrayOfTicks<V, T>(
    waveforms : Array<Waveform<V>>, infinite!: Bool = false
) : Array<Array<CycleInput<V>>>
    where V <: ValueSymbol<V>, T <: HasWidth
{
    let numberOfInputs = waveforms.size
    let numberOfTicks = max(waveforms, { i, w => w.GetLength() })
    Array<Array<CycleInput<V>>>(numberOfTicks, { currentTickIndex : Int64 =>
        Array<CycleInput<V>>(numberOfInputs, { currentInputIndex : Int64 =>
            let currentInput = waveforms[currentInputIndex]
            let currentInputWidth = waveforms[currentInputIndex].GetWidth()
            if(currentTickIndex >= currentInput.GetLength()) {
                DEFINITE(Signal(V.GetDisconnected(), currentInputWidth))
            } else {
                currentInput.GetSignalAtTick(currentTickIndex, infinite)
            }
        })
    })
}
/**
 * Generate a clock waveform: a waveform that alternately pulses high and low
 *
 * @param period The length of time from the start of a high pulse to the next
 * @param duty The proportion of the period that pulses high
 * @param cycles How many cycles to include in this waveform
 * @param high
 * @param low
 */
public func GenerateClock<V>(
    period!: Int64, duty!: Float64 = 0.5, cycles!: Int64, high!: V, low!: V
): Waveform<V>
    where V <: ValueSymbol<V>
{
    AssertLessThan(duty, 1.0)
    let length = period * cycles
    let highLength = Int64(Float64(period) * duty)
    let signals = Array<CycleInput<V>>(length, { i : Int64 =>
        if(i % period < highLength) {
            DEFINITE(Signal(high))
        } else {
            DEFINITE(Signal(low))
        }
    })
    Waveform(signals)
}
/**
 * Create a waveform from a list of pairs, containing a signal and the length
 * of time to pulse it.
 *
 * @param signals
 * @return The wavefom
 */
public func BuildWaveform<V>(
    signals: Array<(CycleInput<V>, Int64)>
) : Waveform<V> where V <: ValueSymbol<V> {
    let totalLength = Sum(signals, { elem => elem[1] })
    let signalList = ArrayList<CycleInput<V>>()
    for((signal, i) in signals) {
        for(j in 0..i) {
            signalList.append(signal)
        }
    }
    Waveform(signalList.toArray())
}
/**
 * Create a waveform from a list of pairs, containing a value and the length
 * of time to pulse it.
 *
 * @param signals
 * @return The wavefom
 */
public func BuildWaveform<V>(
    values: Array<(V, Int64)>
) : Waveform<V> where V <: ValueSymbol<V> {
    let signals = map(
        { value : (V, Int64) => (DEFINITE(Signal([value[0]])), value[1]) },
        values
    )
    BuildWaveform<V>(signals)
}
