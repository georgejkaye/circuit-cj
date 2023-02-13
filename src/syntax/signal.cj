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

public struct Signal<V> <: ToString & HasName & Specifiable<V> & HasWidth & Equatable<Signal<V>>
    where V <: ValueSymbol & Equatable<V> {
    public Signal(
        public let values : Array<V>
    ){
        AssertNonEmpty(values, "values")
    }
    public init(v: V, n : Int64) {
        this(Array<V>(n, {i : Int64 => v}))
    }
    public init(v : V) {
        this([v])
    }
    public func GetName() : String {
        fold_right({acc : String, v : V => "${acc}${v}"}, "", values)
    }
    public func toString() : String {
        "${values}"
    }
    public func GetInputPorts() : Array<Port<V>> {
        []
    }
    public func GetArity() : Int64 {
        0
    }
    public func GetOutputPorts() : Array<Port<V>> {
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
    public func IsAll(v : V) : Bool {
        for(value in this.values) {
            if(value != v) {
                return false
            }
        }
        true
    }
}

public func GetSignal<V>(v : V, w : Int64) : Signal<V> where V <: ValueSymbol & Equatable<V> {
    Signal(Array<V>(w){ i : Int64 => v })
}

public enum WaveformType {
    | FINITE_OPEN
    | FINITE_CLOSED
    | INFINITE
}
extend WaveformType <: Hashable & Equatable<WaveformType> {
    public func hashCode() : Int64 {
        match(this) {
            case FINITE_OPEN => 0
            case FINITE_CLOSED => 1
            case INFINITE => 2
        }
    }
    public operator func == (rhs : WaveformType) {
        this.hashCode() == rhs.hashCode()
    }
    public operator func != (rhs : WaveformType) {
        !(this == rhs)
    }
}
public func GetWaveformString<V>(signals : Array<Signal<V>>) : String
    where V <: ValueSymbol & Equatable<V>
{
    printArray(signals, "", "", " :: ", { s : Signal<V> => s.GetName() }, false)
}