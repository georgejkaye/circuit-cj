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
/**
 * Given an array of signals, get a string representing them as arguments to a
 * circuit, i.e. a string of the form (s1, s2, s3, ...)
 *
 * @param vs The array
 * @return The signa
 */
public func GetArgumentString<V>(
    vs : Array<Signal<V>>,
    printFn!: (Signal<V>) -> String = { s => s.GetName() }
) : String
    where V <: ValueSymbol<V>
{
    arrayToString(
        vs, { s, _ => printFn(s) }, openingBracket: "(", closingBracket: ")",
        delimiter: ", "
    )
}
public func GetOutputString<V>(
    vs : Array<Option<Signal<V>>>,
    printFn!: (Signal<V>) -> String = { s => s.GetName() }
) : String
    where V <: ValueSymbol<V>
{
    arrayToString(
        vs, { opt, _ =>
            match(opt){
                case None => "?"
                case Some(s) => printFn(s)
            }
        }, openingBracket: "(", closingBracket: ")", delimiter: ","
    )
}
/**
 * Enum of inputs that may be parially specified in some way
 */
public enum PartialInputType<V> where V <: ValueSymbol<V> {
    | FIXED(Signal<V>)
    | VARIABLE(Array<Signal<V>>)
    | UNKNOWN
}
extend PartialInputType<V> <: Equatable<PartialInputType<V>> {
    public operator func ==(rhs : PartialInputType<V>) {
        match(this) {
            case FIXED(s) => match(rhs) {
                case FIXED(t) => s == t
                case _ => false
            }
            case VARIABLE(ss) => match(rhs) {
                case VARIABLE(tt) => ss == tt
                case _ => false
            }
            case UNKNOWN => match(rhs) {
                case UNKNOWN => true
                case _ => false
            }
        }
    }
    public operator func !=(rhs : PartialInputType<V>) {
        !(this == rhs)
    }
}
public struct PartialInput<V> where V <: ValueSymbol<V> {
    public PartialInput(
        public let partialType : PartialInputType<V>,
        public let width : Int64
    ){
        match(partialType) {
            case FIXED(s) => AssertHasWidth(s, width)
            case VARIABLE(ss) => AssertAllHaveWidth(ss, width)
            case UNKNOWN => ()
        }
    }
}
extend PartialInputType<V> <: ToString {
    public func toString() : String {
        match(this) {
            case FIXED(v) => "Fixed ${v}"
            case VARIABLE(vs) => "Variable ${arrayToString(vs)}"
            case UNKNOWN => "Unknown"
        }
    }
}
extend PartialInput<V> <: ToString {
    public func toString() : String {
        "${this.partialType} (${this.width})"
    }
}
extend PartialInput<V> <: HasName {
    public func GetName() : String {
        match(this.partialType) {
            case FIXED(v) => "v"
            case VARIABLE(vs) =>
                arrayToString(vs, openingBracket: "{", closingBracket: "}")
            case UNKNOWN => "?"
        }
    }
}
extend PartialInput<V> <: HasWidth {
    public func GetWidth() : Int64 {
        this.width
    }
}
extend PartialInput<V> <: Equatable<PartialInput<V>> {
    public operator func ==(rhs : PartialInput<V>) {
        this.width == rhs.width && this.partialType == rhs.partialType
    }
    public operator func !=(rhs : PartialInput<V>) {
        !(this == rhs)
    }
}