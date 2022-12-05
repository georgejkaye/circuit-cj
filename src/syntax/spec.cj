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

import settings.*

/**
 * Convert a given decimal ASCII code to a string
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
 * A specification defines an arbitrary label with a name and arrays of input/output ports
 */
public class Specification<V> <: Specifiable<V> & HasName & Equatable<Specification<V>> & Hashable
    where V <: ValueSymbol, V <: Equatable<V>
{
    static var nextId = 0
    public let id : Int64
    public Specification(
        public let name : String,
        public let inputPorts : Array<Port<V>>,
        public let outputPorts : Array<Port<V>>
    ){
        this.id = nextId
        nextId++
    }
    public func GetName() : String {
        this.name
    }
    public func GetInputPorts() : Array<Port<V>> {
        this.inputPorts
    }
    public func GetArity() : Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts() : Array<Port<V>> {
        this.outputPorts
    }
    public func GetCoarity() : Int64 {
        this.GetOutputPorts().size
    }
    public func toString() : String {
        this.GetName()
    }
    public operator func ==(rhs : Specification<V>) {
        this.name == rhs.name &&
            this.inputPorts == rhs.inputPorts &&
            this.outputPorts == rhs.outputPorts
    }
    public operator func !=(rhs : Specification<V>) {
        !(this == rhs)
    }
    public func hashCode() : Int64 {
        this.id
    }
}