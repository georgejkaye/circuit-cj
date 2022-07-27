/**
 * ports.cj
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

public interface Specifiable <: ToString {
    func GetName() : String
    func GetInputPorts() : Array<Port>
    func GetOutputPorts() : Array<Port>
    func toString() : String {
        this.GetName()
    }
    func GetNoInputs() : Int64 {
        this.GetInputPorts().size()
    }
    func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size()
    }
}
public interface HasWidth {
    func GetWidth() : Int64
}
extend Int64 <: HasWidth {
    public func GetWidth() : Int64 {
        this
    }
}

/**
 * A port has a width and an optional name
 */
public record Port <: ToString & Equatable<Port> & HasWidth {
    public Port(
        public let width : Int64,
        public let name! : Option<String> = None
    ){}
    public init(width : Int64, name: String) {
        this(width, name: name)
    }
    public func toString() : String {
        let nameString = match(name) {
            case None => ""
            case Some(n) => " ${n}"
        }
        "${width}${nameString}"
    }
    public operator func ==(rhs: Port) : Bool {
        this.width == rhs.width && this.name == rhs.name
    }
    public operator func !=(rhs: Port) : Bool {
        !(this == rhs)
    }
    public func GetWidth() : Int64 {
        this.width
    }
}

/**
 * Generate an array of ports all with a given width
 *
 * @param n The number of ports in the array
 * @param w The width of each port
 * @return The port of arrays
 */
func GeneratePortArray(n : Int64, w : Int64) : Array<Port> {
    Array<Port>(n) {
        i : Int64 => Port(w, numToUppercaseLetter(i+1))
    }
}