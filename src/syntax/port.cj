/**
 * syntax/ports.cj
 *
 * This file contains the definition of ports with a width and a(n optional) name
 *
 * @author George Kaye
 * @since 0.2
 */

package syntax

/**
 * Interfaces
 */

public interface HasWidth {
    func GetWidth() : Int64
}
public interface HasName {
    func GetName() : String
}
public interface HasOptionalName {
    func GetName() : Option<String>
}
public interface Socket <: HasWidth & HasOptionalName & ToString {}
public interface Specifiable<V> where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> {
    func GetInputPorts() : Array<Port<V>>
    func GetInputPort(i : Int64) : Port<V> {
        this.GetInputPorts()[i]
    }
    func GetArity() : Int64 {
        this.GetInputPorts().size
    }
    func GetOutputPorts() : Array<Port<V>>
    func GetOutputPort(i : Int64) : Port<V> {
        this.GetOutputPorts()[i]
    }
    func GetCoarity() : Int64 {
        this.GetOutputPorts().size
    }
}
extend Int64 <: HasWidth {
    public func GetWidth() : Int64 {
        this
    }
}
/**
 * A port has a width and an optional name
 */
public class Port<V> <: ToString & Equatable<Port<V>> & Socket where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> {
    public Port(
        public let width : Int64,
        public let name!: Option<String> = None
    ){}
    public init(width : Int64, name: String) {
        this(width, name: name)
    }
    public func toString() : String {
        let nameString = match(name) {
            case None => ""
            case Some(n) => " (${n})"
        }
        "${width}${nameString}"
    }
    public operator func ==(rhs : Port<V>) : Bool {
        this.width == rhs.GetWidth() && this.name == rhs.GetName()
    }
    public operator func !=(rhs : Port<V>) : Bool {
        !(this == rhs)
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetName() : Option<String> {
        this.name
    }
}
public func PrintWidthArray<T>(array : Array<T>) : String where T <: HasWidth {
    printArray<T>(
        array, { t : T => "${t.GetWidth()}" },
        openingBracket: "[", closingBracket: "]", delimiter: ","
    )
}