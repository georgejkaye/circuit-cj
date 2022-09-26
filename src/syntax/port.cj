/**
 * syntax/ports.cj
 *
 * This file contains the definition of ports with a width and a(n optional) name
 *
 * @author George Kaye
 * @since 0.2
 */

package syntax

import prelude.*

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
public interface Specifiable {
    func GetInputPorts() : Array<Port>
    func GetOutputPorts() : Array<Port>
}
extend Int64 <: HasWidth {
    public func GetWidth() : Int64 {
        this
    }
}

/**
 * A port has a width and an optional name
 */
public class Port <: ToString & Equatable<Port> & Socket {
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
 * Generate an array of ports all with a given width
 *
 * @param n The number of ports in the array
 * @param w The width of each port
 * @return The port of arrays
 */
func GeneratePortArray(n : Int64, w : Int64) : Array<Socket> {
    Array<Socket>(n) {
        i : Int64 => Port(w, numToUppercaseLetter(i+1))
    }
}

public func PrintWidthArray<T>(array : Array<T>) : String where T <: HasWidth {
    printArray<T>(
        array,
        "[",
        "]",
        ", ",
        { t : T => "${t.GetWidth()}" },
        false
    )
}