/**
 * signature/gate/values.cj
 *
 * The values for gate level circuits
 */
package signatures.gate

from std import collection.ArrayList, collection.HashSet
import syntax.*
import components.*

/**
 * Enum of Belnap values (four valued logic)
 */
public enum GateLevelValue {
    | NONE
    | TRUE
    | FALSE
    | BOTH
}
/**
 * Instantiate Belnap values as a type of value symbols
 */
extend GateLevelValue <: ValueSymbol & Equatable<GateLevelValue> {
    public func hashCode(): Int64 {
        match (this) {
            case NONE => 0
            case TRUE => 1
            case FALSE => 2
            case BOTH => 3
        }
    }
    public operator func ==(rhs: GateLevelValue): Bool {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs: GateLevelValue): Bool {
        !(this == rhs)
    }
    public func toString(): String {
        match (this) {
            case NONE => "\u{22A5}"
            case FALSE => "0"
            case TRUE => "1"
            case BOTH => "\u{22A4}"
        }
    }
    public func GetName(): String {
        this.toString()
    }
    public func Negate() : GateLevelValue {
        match(this) {
            case NONE => NONE
            case FALSE => TRUE
            case TRUE => FALSE
            case BOTH => BOTH
        }
    }
    public func IsTrue() : Bool {
        match(this) {
            case TRUE => true
            case _ => false
        }
    }
}
/**
 * Enum of Belnap gates
 */
public enum GateLevelPrimitive {
    BUF | NOT | AND | OR | NAND | NOR | XOR | XNOR
}
/**
 * Internal package type aliases
 */
type BelnapWire = Wire<GateLevelValue, GateLevelPrimitive>
type BelnapPort = Port<GateLevelValue>
type BelnapCircuit = InterfacedHypergraph<GateLevelValue, GateLevelPrimitive>
/**
 * Instantiate GateLevelPrimitive as a type of gate symbols
 */
extend GateLevelPrimitive <: PrimitiveSymbol<GateLevelValue> & Equatable<GateLevelPrimitive> {
    public func hashCode() {
        match (this) {
            case BUF => 0
            case NOT => 1
            case AND => 2
            case OR => 3
            case NAND => 4
            case NOR => 5
            case XOR => 6
            case XNOR => 7
        }
    }
    public operator func ==(rhs: GateLevelPrimitive) {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs: GateLevelPrimitive) {
        !(this == rhs)
    }
    public func GetName(): String {
        match (this) {
            case BUF => "BUF"
            case NOT => "NOT"
            case AND => "AND"
            case OR => "OR"
            case NAND => "NAND"
            case NOR => "NOR"
            case XOR => "XOR"
            case XNOR => "XNOR"
        }
    }
    public func GetInputPorts(): Array<BelnapPort> {
        match (this) {
            case BUF => [Port(1, "A")]
            case NOT => [Port(1, "A")]
            case AND => [Port(1, "A"), Port(1, "B")]
            case OR => [Port(1, "A"), Port(1, "B")]
            case NAND => [Port(1, "A"), Port(1, "B")]
            case NOR => [Port(1, "A"), Port(1, "B")]
            case XOR => [Port(1, "A"), Port(1, "B")]
            case XNOR => [Port(1, "A"), Port(1, "B")]
        }
    }
    public func GetArity(): Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts(): Array<BelnapPort> {
        match (this) {
            case BUF => [Port(1, "Z")]
            case NOT => [Port(1, "Z")]
            case AND => [Port(1, "Z")]
            case OR => [Port(1, "Z")]
            case NAND => [Port(1, "Z")]
            case NOR => [Port(1, "Z")]
            case XOR => [Port(1, "Z")]
            case XNOR => [Port(1, "Z")]
        }
    }
    public func GetCoarity(): Int64 {
        this.GetOutputPorts().size
    }
    public func toString(): String {
        this.GetName()
    }
    public func GetEnhancedName(n: Int64, w: Int64): String {
        "${this.GetName()}${n}_${w}"
    }
}
/**
 * Given two Belnap values, get their join in the lattice A4
 * @param lhs The left value
 * @param rhs The right value
 * @return The result of lhs v rhs in A4
 */
func GateLevelJoin(lhs: GateLevelValue, rhs: GateLevelValue): GateLevelValue {
    match (lhs) {
        case BOTH => BOTH
        case NONE => rhs
        case TRUE =>
            match (rhs) {
                case BOTH => BOTH
                case FALSE => BOTH
                case _ => TRUE
            }
        case FALSE =>
            match (rhs) {
                case BOTH => BOTH
                case TRUE => BOTH
                case _ => FALSE
            }
    }
}
/**
 * Given two Belnap values, find if the left value is less than or equal
 * to the right in the lattice A4
 * @param lhs The left value
 * @param rhs The right value
 * @return Whether lhs <= rhs in A4
 */
func GateLevelLTE(lhs: GateLevelValue, rhs: GateLevelValue): Bool {
    match (lhs) {
        case NONE => true
        case FALSE =>
            match (rhs) {
                case NONE => false
                case TRUE => false
                case _ => true
            }
        case TRUE =>
            match (rhs) {
                case NONE => false
                case FALSE => false
                case _ => true
            }
        case BOTH =>
            match (rhs) {
                case BOTH => true
                case _ => false
            }
    }
}
/**
 * The lattice A4 on the Belnap values
 */
let gateLevelLatticeStructure = FiniteLattice<GateLevelValue>(
    HashSet<GateLevelValue>([NONE, TRUE, FALSE, BOTH]),
    NONE,
    BOTH,
    GateLevelLTE,
    GateLevelJoin
)
/**
 * Get the logical NOT of a values
 * @param v The argument
 * @return The logical AND of the argument
 */
func not(v: GateLevelValue) {
    match (v) {
        case BOTH => BOTH
        case NONE => NONE
        case TRUE => FALSE
        case FALSE => TRUE
    }
}
/**
 * Get the logical AND of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The logical AND of the two arguments
 */
func and(lhs: GateLevelValue, rhs: GateLevelValue) {
    match (lhs) {
        case BOTH => BOTH
        case NONE => NONE
        case TRUE => rhs
        case FALSE =>
            match (rhs) {
                case BOTH => BOTH
                case NONE => NONE
                case _ => FALSE
            }
    }
}
/**
 * Get the logical OR of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func or(lhs: GateLevelValue, rhs: GateLevelValue) {
    match (lhs) {
        case BOTH => BOTH
        case NONE => NONE
        case FALSE => rhs
        case TRUE =>
            match (rhs) {
                case BOTH => BOTH
                case NONE => NONE
                case _ => TRUE
            }
    }
}
/**
 * Get the logical XOR of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func xor(lhs: GateLevelValue, rhs: GateLevelValue) {
    match (lhs) {
        case BOTH => BOTH
        case NONE => NONE
        case FALSE => rhs
        case TRUE =>
            match (rhs) {
                case BOTH => BOTH
                case NONE => NONE
                case v => not(v)
            }
    }
}
/**
 * Given a Belnap gate, interpret it as an appropriate function on Belnap values
 * @param g The Belnap gate
 * @return The function from an array of Belnap values to an array of Belnap values
 */
func gateLevelInterpretation(g: GateLevelPrimitive): (Array<GateLevelValue>) -> Array<GateLevelValue> {
    {
        ws: Array<GateLevelValue> =>
            let output = match (g) {
                case BUF => ws[0]
                case NOT => not(ws[0])
                case AND => and(ws[0], ws[1])
                case OR => or(ws[0], ws[1])
                case NAND => not(and(ws[0], ws[1]))
                case NOR => not(or(ws[0], ws[1]))
                case XOR => xor(ws[0], ws[1])
                case XNOR => not(xor(ws[0], ws[1]))
            }
            [output]
    }
}
/**
 * Convert an array of Belnap values to the corresponding number, if appropriate
 * @param values The array of Belnap values
 * @param signed Whether to interpret this as a signed value
 * @return An option containing the number represented, if appropriate
 */
func GateLevelValueToDec(values : Array<GateLevelValue>, signed : Bool) : Option<Int64> {
    var x = 0
    var negative = false
    if (signed) {
        // In a signed number, the first bit indicates if
        // the number is negative
        match(values[values.size - 1]) {
            case TRUE => negative = true
            case FALSE => ()
            case _ => return None<Int64>
        }
        for (i in 0..values.size) {
            var carry = true
            match(values[i]) {
                case TRUE =>
                    if(!carry) {
                        x += 2**UInt64(i)
                    }
                case FALSE =>
                    if(carry) {
                        x += 2**UInt64(i)
                        carry = false
                    }
                case _ => return None<Int64>
            }
        }
    } else {
        for (i in 0..values.size) {
            match(values[i]) {
                case TRUE =>
                    x += 2**UInt64(i)
                case FALSE => ()
                case _ => return None<Int64>
            }
        }
    }
    if(negative){
        x = -x
    }
    Some(x)
}
/**
 * Signature for Belnap circuits
 */
public let gateLevelSignature = Signature<GateLevelValue, GateLevelPrimitive>(
    gateLevelLatticeStructure,
    gateLevelInterpretation,
    GateLevelValueToDec
)