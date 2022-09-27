/**
 * syntax/library.cj
 *
 * This file is a library of components that make up
 * our circuits
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
public class Specification <: Specifiable & HasName & Equatable<Specification> {
    public Specification(
        public let name : String,
        public let inputPorts : Array<Port>,
        public let outputPorts : Array<Port>
    ){}
    public func GetName() : String {
        this.name
    }
    public func GetInputPorts() : Array<Port> {
        this.inputPorts
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size()
    }
    public func GetOutputPorts() : Array<Port> {
        this.outputPorts
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size()
    }
    public func toString() : String {
        this.GetName()
    }
    public operator func ==(rhs : Specification) {
        this.name == rhs.name && this.inputPorts == rhs.inputPorts && this.outputPorts == rhs.outputPorts
    }
    public operator func !=(rhs : Specification) {
        !(this == rhs)
    }
}
/**
 * Primitives are the basic building blocks of circuits, i.e.
 * the logic gates that take one bit inputs and return one output
 * of one bit
 */
public struct Primitive <: ToString & Specifiable & HasName & Equatable<Primitive> {
    let spec : Specification
    public init(
        name : String,
        inputs : Array<String>,
        output : String
    ){
        this.spec = Specification(
            name,
            map({ s : String => Port(1, s) }, inputs),
            [Port(1, output)]
        )
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func GetInputPorts() : Array<Port> {
        this.spec.GetInputPorts()
    }
    public func GetNoInputs() : Int64 {
        this.spec.GetNoInputs()
    }
    public func GetOutputPorts() : Array<Port> {
        this.spec.GetOutputPorts()
    }
    public func GetNoOutputs() : Int64 {
        this.spec.GetNoOutputs()
    }
    public func toString() : String {
        this.spec.toString()
    }
    /**
    * Get a name for an 'enhanced' version of this primitive, i.e. one
    * with thicker input wires (where the primitive will be applied bitwise)
    * and multiple input wires (where the primitive will be folded across them)
    *
    * @param n The number of inputs to the composite gate
    * @param w The width of each input to the composite gate
    * @return The name of the composite gate
    */
    public func GetEnhancedName(n : Int64, w : Int64) : String {
        "${this.GetName()}${n}_${w}"
    }
    public operator func ==(rhs : Primitive) : Bool {
        this.spec == rhs.spec
    }
    public operator func !=(rhs : Primitive) : Bool {
        !(this == rhs)
    }
}

public func GetMuxName(n : Int64, c : Int64, w : Int64) : String {
    "MUX${n}_${c}_${w}"
}

public func MuxSpec(n : Int64, c : Int64, w: Int64) : Specification {
    Specification(
        "MUX${n}_1_${w}",
        Array<Port>(c + n, {
            i : Int64 =>
                let (width, name) = if (i < c) {
                    (1, "SEL${i}")
                } else {
                    (w, numToUppercaseLetter(i - c))
                }
                Port(width, name: name)
        }),
        [Port(w, "Z")]
    )
}

public let BUF  = Primitive("BUF" , ["A"], "Z")
public let NOT  = Primitive("BUF" , ["A"], "Z")
public let AND  = Primitive("AND" , ["A", "B"], "Z")
public let OR   = Primitive("OR"  , ["A", "B"], "Z")
public let NAND = Primitive("NAND", ["A", "B"], "Z")
public let NOR  = Primitive("NOR" , ["A", "B"], "Z")
public let XOR  = Primitive("XOR" , ["A", "B"], "Z")
public let XNOR = Primitive("XNOR", ["A", "B"], "Z")