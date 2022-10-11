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
    where V <: ValueSymbol, V <: Equatable<V> {
    public Signal(
        public let values : Array<V>
    ){
        AssertNonEmpty(values, "values")
    }
    public init(v: V, n : Int64) {
        this(Array<V>(n, {i : Int64 => v}))
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
}

public struct Waveform<V> <: ToString & HasName & HasWidth where V <: ValueSymbol, V <: Equatable<V> {
    let width : Int64
    public Waveform(
        public let signals : Array<Signal<V>>
    ){
        this.width = AssertSignalsSameWidth(signals)
    }
    public func toString() : String {
        printArray(
            this.signals,
            "",
            "",
            " :: ",
            { s : Signal<V> => s.GetName() },
            true
        )
    }
    public func GetName() : String {
        this.toString()
    }
    public func GetWidth() : Int64 {
        this.width
    }
}