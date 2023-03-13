/**
 * syntax/ports.cj
 *
 * Contains the definition of ports with a width and a(n optional) name
 *
 * @author George Kaye
 * @since 0.2
 */
package syntax
/**
 * Interface for things with a width
 */
public interface HasWidth {
    func GetWidth() : Int64
}
/**
 * Given two things with widths, assert that they have the same width.
 * Returns the width if so, throws an exception if not
 *
 * @param t
 * @param u
 * @return The width if t and u have the same width
 */
public func AssertTwoSameWidth<T, U>(t : T, u : U) : Int64
    where T <: HasWidth & ToString, U <: HasWidth & ToString
{
    AssertTwoSameParameter<T, U, Int64>(
        t, u, { t : T => t.GetWidth() }, { u : U => u.GetWidth() }, Width
    )
}
/**
 * Given an array of things with widths, assert that they are all the same
 * width. Returns the width if they are, throws an exception if they are not.
 *
 * @param vs The array of signals
 * @return The width of the signals, if they are all the same
 */
public func AssertAllSameWidth<T>(array : Array<T>) : Int64
    where T <: HasWidth & ToString
{
    AssertAllSameParameter<T, Int64>(
        array, { t : T => t.GetWidth() }, Width
    )
}
/**
 * Given an array of objects with width, get a string of their width array.
 *
 * @param array
 * @return The string of widths e.g. [1,2,3,4,...]
 */
public func PrintWidthArray<T>(array : Array<T>) : String where T <: HasWidth {
    arrayToString<T>(
        array, { t : T => "${t.GetWidth()}" },
        openingBracket: "[", closingBracket: "]", delimiter: ","
    )
}
/**
 * Interface for things with a name
 */
public interface HasName {
    func GetName() : String
}
/**
 * Interface for things with an optional name
 */
public interface HasOptionalName {
    func GetName() : Option<String>
    func GetNameString() : String {
        match(this.GetName()) {
            case None => ""
            case Some(n) => n
        }
    }
}
/**
 * A socket is something with a width, optional name, and string identifier
 */
public interface Socket <: HasWidth & HasOptionalName & ToString {}
/**
 * A port has a width and an optional name
 */
public class Port <: ToString & Equatable<Port> & Socket {
    public Port(
        public let width : Int64,
        public let name!: Option<String> = None
    ){}
    public init(
        width : Int64,
        name : String
    ){
        this(width, name: Some(name))
    }
    public func toString() : String {
        let nameString = match(name) {
            case None => ""
            case Some(n) => " (${n})"
        }
        "${width}${nameString}"
    }
    public operator func ==(rhs : Port) : Bool {
        this.width == rhs.GetWidth() && this.name == rhs.GetName()
    }
    public operator func !=(rhs : Port) : Bool {
        !(this == rhs)
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetName() : Option<String> {
        this.name
    }
}
/**
 * Interface for things that can be specified by their input and output ports
 */
public interface Specifiable<V>
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    /**
     * Get all the input ports
     */
    func GetInputPorts() : Array<Port>
    /**
     * @param i
     * @return the ith input port
     */
    func GetInputPort(i : Int64) : Port {
        this.GetInputPorts()[i]
    }
    /**
     * @return the number of input ports
     */
    func GetArity() : Int64 {
        this.GetInputPorts().size
    }
    /**
     * Get all the output ports
     */
    func GetOutputPorts() : Array<Port>
    /**
     * @param i
     * @return the ith output port
     */
    func GetOutputPort(i : Int64) : Port {
        this.GetOutputPorts()[i]
    }
    /**
     * @return the number of output ports
     */
    func GetCoarity() : Int64 {
        this.GetOutputPorts().size
    }
}