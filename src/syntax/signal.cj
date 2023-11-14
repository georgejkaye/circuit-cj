/**
 * syntax/signal.cj
 *
 * Contains the definition of Signals: multiple values in parallel.
 *
 * @author George Kaye
 * @since 0.2
 */
package syntax
/**
 * A signal is an array of values.
 */
public struct Signal<V> where V <: ValueSymbol<V>
{
    public Signal(
        let values : Array<V>
    ){
        AssertNonEmpty(values)
        // We enforce that signals are at most 256 bits long
        // so that we can hash them; this should be plenty
        AssertLengthIsLessThanOrEqualTo(values, 256)
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
    public func GetValues() : Array<V> {
        this.values
    }
    public func GetBit(i : Int64) : V {
        this.values[i]
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
extend Signal<V> <: ToString {
    public func toString() : String {
        concatStrings({ v : V => "${v}" }, this.values, delimiter: "")
    }
}
extend Signal<V> <: Equatable<Signal<V>> {
    public operator func ==(rhs : Signal<V>) : Bool {
        this.values == rhs.values
    }
    public operator func !=(rhs : Signal<V>) : Bool {
        !(this == rhs)
    }
}
extend Signal<V> <: Hashable {
    public func hashCode() : Int64 {
        /**
         * Kind of a hack, but it will probably work for everything anyone is
         * going to make
         */
        let string =
            arrayToString<V>(
                this.values, { v : V, _ => "${v.hashCode()}" },
                openingBracket: "", closingBracket: "", delimiter: " "
            )
        string.hashCode()
    }
}
extend Signal<V> <: HasName {
    public func GetName() : String {
        fold_right({acc : String, v : V => "${acc}${v}"}, "", values)
    }
}
extend Signal<V> <: HasWidth {
    public func GetWidth() : Int64 {
        this.values.size
    }
}
extend Signal<V> <: Specifiable {
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
}