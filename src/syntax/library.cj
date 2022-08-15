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
    ASCIIToString(64 + UInt32(n))
}

public class ValueSpec <: ToString & Specifiable {
    public ValueSpec(
        let values : Array<Value>,
        let signed : Bool
    ){}
    public func GetName() : Option<String> {
        PrintValue(this.values, this.signed, BIN)
    }
    public func GetValueAsRepresentation(rep : NumberRepresentation) : String {
        PrintValue(this.values, this.signed, rep)
    }
    public func toString() : String {
        "${values}"
    }
    public func GetInputPorts() : Array<Socket> {
        []
    }
    public func GetOutputPorts() : Array<Socket> {
        [Port(values.size)]
    }
    public func GetSize() : Int64 {
        this.values.size
    }
}

public let BOTTOM : ValueSpec = ValueSpec([Bottom], false)
public let TRUE   : ValueSpec = ValueSpec([True], false)
public let FALSE  : ValueSpec = ValueSpec([False], false)
public let TOP    : ValueSpec = ValueSpec([Top], false)

/**
 * Primitives are the basic building blocks of circuits, i.e.
 * the logic gates that take one bit inputs
 */
public enum Primitive {
    | BUF
    | NOT
    | AND
    | OR
    | NAND
    | NOR
    | XOR
    | XNOR
}
extend Primitive <: ToString & Specifiable {
    public func GetName() : Option<String> {
        match(this) {
            case BUF  => "BUF"
            case NOT  => "NOT"
            case AND  => "AND"
            case OR   => "OR"
            case NAND => "NAND"
            case NOR  => "NOR"
            case XOR  => "XOR"
            case XNOR => "XNOR"
        }
    }
    public func GetInputPorts() : Array<Socket> {
        match(this) {
            case BUF  => [Port(1, "A")]
            case NOT  => [Port(1, "A")]
            case AND  => [Port(1, "A"), Port(1, "B")]
            case OR   => [Port(1, "A"), Port(1, "B")]
            case NAND => [Port(1, "A"), Port(1, "B")]
            case NOR  => [Port(1, "A"), Port(1, "B")]
            case XOR  => [Port(1, "A"), Port(1, "B")]
            case XNOR => [Port(1, "A"), Port(1, "B")]
        }
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts() : Array<Socket> {
        match(this) {
            case BUF  => [Port(1, "Z")]
            case NOT  => [Port(1, "Z")]
            case AND  => [Port(1, "Z")]
            case OR   => [Port(1, "Z")]
            case NAND => [Port(1, "Z")]
            case NOR  => [Port(1, "Z")]
            case XOR  => [Port(1, "Z")]
            case XNOR => [Port(1, "Z")]
        }
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size
    }
    public func toString() : String {
        match(this.GetName()) {
            case None => ""
            case Some(s) => s
        }
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
}

/**
 * A specification defines an arbitrary label with a name and arrays of input/output ports
 */
public class Specification <: Specifiable {
    public Specification(
        let name : Option<String>,
        let inputPorts : Array<Port>,
        let outputPorts : Array<Port>
    ){}
    public func GetName() : Option<String> {
        this.name
    }
    public func GetInputPorts() : Array<Socket> {
        (this.inputPorts as Array<Socket>).getOrThrow()
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts() : Array<Socket> {
        (this.outputPorts as Array<Socket>).getOrThrow()
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size
    }
    public func toString() : String {
        match(this.GetName()){
            case None => ""
            case Some(s) => s
        }
    }
}

public func GetMuxName(n : Int64, c : Int64, w : Int64) : String {
    "MUX{n}_${c}_{w}"
}

public func MuxSpec(n : Int64, c : Int64, w: Int64) : Specification {
    Specification(
        "MUX{n}_1_{w}",
        Array<Port>(c + n){
            i : Int64 =>
                let (width, name) = if (i < c) {
                    (1, "SEL${i}")
                } else {
                    (w, numToUppercaseLetter(i - c))
                }
                Port(width, name: name)
        },
        [Port(w, "Z")]
    )
}