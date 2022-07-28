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
    let char = chr(n)
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
    public func GetName() : String {
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
    public func GetInputPorts() : Array<Port> {
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
        this.GetInputPorts().size()
    }
    public func GetOutputPorts() : Array<Port> {
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
        this.GetOutputPorts().size()
    }
    public func toString() : String {
        this.GetName()
    }
}

/**
 * Composites are more advanced components that are constructed from 
 * the primitives. 
 * 
 * Users can of course define their own composites, but these are
 * common components so are predefined
 */
public enum Composite {
    | BUF(Int64)
    | NOT(Int64)
    | AND(Int64, Int64)
    | OR(Int64, Int64)
    | NAND(Int64, Int64)
    | NOR(Int64, Int64)
    | XOR(Int64, Int64)
    | XNOR(Int64, Int64)
    | MUX(Int64, Int64, Int64)
    | USER(String, Array<Port>, Array<Port>)

}
extend Composite <: Specifiable {
    public func GetName() : String {
        match(this) {
            case BUF(w)        => "BUF_${w}"
            case NOT(w)        => "NOT_${w}"
            case AND(n, w)     => "AND${n}_${w}"
            case OR(n, w)      => "OR${n}_${w}"
            case NAND(n, w)    => "NAND${n}_${w}"
            case NOR(n, w)     => "NOR${n}_${w}"
            case XOR(n, w)     => "XOR${n}_${w}"
            case XNOR(n, w)    => "XNOR${n}_${w}"
            case MUX(n, c, w)  => "MUX${n}_${c}_${w}"
            case USER(s, _, _) => s
        }
    }
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case BUF(w)       => GeneratePortArray(1, w)
            case NOT(w)       => GeneratePortArray(1, w)
            case AND(n, w)    => GeneratePortArray(n, w)
            case OR(n, w)     => GeneratePortArray(n, w)
            case NAND(n, w)   => GeneratePortArray(n, w)
            case NOR(n, w)    => GeneratePortArray(n, w)
            case XOR(n, w)    => GeneratePortArray(n, w)
            case XNOR(n, w)   => GeneratePortArray(n, w)
            case MUX(n, c, w) => 
                Array<Port>(c + n){
                    i : Int64 => 
                        if (i < c){
                            Port(1, "SEL${i}")
                        } else {
                            Port(w, numToUppercaseLetter(i - c + 1))
                        }
                }
            case USER(_, i, _) => i
        }
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size()
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case BUF(_)        => [Port(1, "Z")]
            case NOT(_)        => [Port(1, "Z")]
            case AND(_, _)     => [Port(1, "Z")]
            case OR(_, _)      => [Port(1, "Z")]
            case NAND(_, _)    => [Port(1, "Z")]
            case NOR(_, _)     => [Port(1, "Z")]
            case XOR(_, _)     => [Port(1, "Z")]
            case XNOR(_, _)    => [Port(1, "Z")]
            case MUX(_, _, _)  => [Port(1, "Z")]
            case USER(_, _, o) => o
        }
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size()
    }
    public func toString() : String {
        this.GetName()
    }
}

/**
 * A black box is a component that we can't look inside,
 * we only know its external interface
 */
public record BlackBox <: Specifiable {
    BlackBox(
        let name : String,
        let inputPorts : Array<Port>,
        let outputPorts : Array<Port>
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
}