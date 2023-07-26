/**
 * syntax/spec.cj
 *
 * Contains the definition of a Specification, which determines
 * the name and interfaces of components
 *
 * @author George Kaye
 * @since 0.2
 */
package syntax
/**
 * Convert a given decimal ASCII code to a string
 *
 * @param n The decimal number
 * @return The corresponding ascii character as a string
 */
public func ASCIIToString(n : UInt32) : String {
    let char = Char(n)
    String([char])
}
/**
 * Convert a number to an uppercase letter.
 * A=1, B=2, ..., Z=26
 *
 * @param n The number to convert
 * @return The corresponding uppercase letter
 */
public func numToUppercaseLetter(n : Int64) : String {
    ASCIIToString(65 + UInt32(n))
}
/**
 * A specification defines an arbitrary label with a name and arrays of
 * input/output ports
 */
public class Specification
     <: Specifiable & HasName & Equatable<Specification> & Hashable
{
    let id : Int64
    public Specification(
        let name : String,
        let inputPorts : Array<Port>,
        let outputPorts : Array<Port>
    ){
        this.id = GetNextId()
    }
    public func GetName() : String {
        this.name
    }
    public func toString() : String {
        this.GetName()
    }
    public func GetInputPorts() : Array<Port> {
        this.inputPorts
    }
    public func GetOutputPorts() : Array<Port> {
        this.outputPorts
    }
    public operator func ==(rhs : Specification) {
        this.name == rhs.name &&
            this.inputPorts == rhs.inputPorts &&
            this.outputPorts == rhs.outputPorts
    }
    public operator func !=(rhs : Specification) {
        !(this == rhs)
    }
    public func hashCode() : Int64 {
        this.id
    }
}