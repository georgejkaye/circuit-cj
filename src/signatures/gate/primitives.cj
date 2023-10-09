package signatures.gate
/**
 * Enum of Belnap gates
 */
public enum GateLevelPrimitive {
    BUF | NOT | AND | OR | NAND | NOR | XOR | XNOR
}
extend GateLevelPrimitive <: Hashable {
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
}
extend GateLevelPrimitive <: Equatable<GateLevelPrimitive> {
    public operator func ==(rhs: GateLevelPrimitive) {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs: GateLevelPrimitive) {
        !(this == rhs)
    }
}
extend GateLevelPrimitive <: HasName {
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
}
extend GateLevelPrimitive <: ToString {
    public func toString(): String {
        this.GetName()
    }
}
extend GateLevelPrimitive <: Specifiable {
    public func GetInputPorts(): Array<Port> {
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
    // This should use the default implementation but it doesn't compile
    public func GetArity() : Int64 {
        this.GetInputPorts().size
    }
    // This should use the default implementation but it doesn't compile
    public func GetInputPort(i : Int64) : Port {
        this.GetInputPorts()[i]
    }
    public func GetOutputPorts(): Array<Port> {
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
    // This should use the default implementation but it doesn't
    public func GetCoarity() : Int64 {
        this.GetInputPorts().size
    }
    // This should use the default implementation but it doesn't
    public func GetOutputPort(i : Int64) : Port {
        this.GetInputPorts()[i]
    }
}
extend GateLevelPrimitive <:
    PrimitiveSymbol<GateLevelValue, GateLevelPrimitive>
{}
/**
 * Get the logical NOT of a values
 *
 * @param v The argument
 * @return The logical AND of the argument
 */
func not(v: GateLevelValue) {
    match (v) {
        case NONE => NONE
        case FALSE => TRUE
        case TRUE => FALSE
        case BOTH => BOTH
    }
}
/**
 * Get the logical AND of two values
 *
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The logical AND of the two arguments
 */
func and(lhs: GateLevelValue, rhs: GateLevelValue) {
    match (lhs) {
        case FALSE => FALSE
        case TRUE  => rhs
        case NONE => match(rhs) {
            case NONE => NONE
            case TRUE => NONE
            case _ => FALSE
        }
        case BOTH => match(rhs) {
            case NONE => FALSE
            case FALSE => FALSE
            case _ => BOTH
        }
    }
}
/**
 * Get the logical OR of two values
 *
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func or(lhs: GateLevelValue, rhs: GateLevelValue) {
    match (lhs) {
        case TRUE => TRUE
        case FALSE => rhs
        case NONE => match(rhs) {
            case NONE => NONE
            case FALSE => NONE
            case _ => TRUE
        }
        case BOTH => match(rhs) {
            case NONE => TRUE
            case TRUE => TRUE
            case _ => BOTH
        }
    }
}
/**
 * Get the logical XOR of two values
 *
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func xor(lhs: GateLevelValue, rhs: GateLevelValue) {
    or(and(lhs, not(rhs)), and(not(lhs), rhs))
}
/**
 * Given a Belnap gate, interpret it as an appropriate function on Belnap values
 *
 * @param g The Belnap gate
 * @return The function representing the interpretation of the gate
 */
func gateLevelInterpretation(g: GateLevelPrimitive) :
    (Array<Array<GateLevelValue>>) -> Array<Array<GateLevelValue>>
{
    {
        ws: Array<Array<GateLevelValue>> =>
            let output = match (g) {
                case BUF => ws[0][0]
                case NOT => not(ws[0][0])
                case AND => and(ws[0][0], ws[1][0])
                case OR => or(ws[0][0], ws[1][0])
                case NAND => not(and(ws[0][0], ws[1][0]))
                case NOR => not(or(ws[0][0], ws[1][0]))
                case XOR => xor(ws[0][0], ws[1][0])
                case XNOR => not(xor(ws[0][0], ws[1][0]))
            }
            [[output]]
    }
}