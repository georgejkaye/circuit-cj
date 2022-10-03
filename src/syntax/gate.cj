package syntax

public enum GateLevelValue {
    | NONE
    | TRUE
    | FALSE
    | BOTH
}

extend GateLevelValue <: Equatable<GateLevelValue> & Hashable & LE<GateLevelValue> & ToString {
    public operator func ==(rhs: GateLevelValue): Bool {
        match (this) {
            case NONE =>
                match (rhs) {
                    case NONE => true
                    case _ => false
                }
            case FALSE =>
                match (rhs) {
                    case FALSE => true
                    case _ => false
                }
            case TRUE =>
                match (rhs) {
                    case TRUE => true
                    case _ => false
                }
            case BOTH =>
                match (rhs) {
                    case BOTH => true
                    case _ => false
                }
        }
    }
    public operator func !=(rhs: GateLevelValue): Bool {
        !(this == rhs)
    }
    public operator func <=(rhs: GateLevelValue): Bool {
        match (this) {
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
    public func hashCode(): Int64 {
        match (this) {
            case NONE => 0
            case TRUE => 1
            case FALSE => 2
            case BOTH => 3
        }
    }
    public func toString(): String {
        match (this) {
            case NONE => "\u{22A5}"
            case FALSE => "0"
            case TRUE => "1"
            case BOTH => "\u{22A4}"
        }
    }
}

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

let values = ArrayList<GateLevelValue>([NONE, TRUE, FALSE, BOTH])

let gateLevelLattice = FiniteLattice<GateLevelValue>(
    HashSet<GateLevelValue>([NONE, TRUE, FALSE, BOTH]),
    NONE,
    BOTH,
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
 * Get the join of two values in the lattice
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The join of the two values
 */
func join(lhs: GateLevelValue, rhs: GateLevelValue) {
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
let bufGate = Primitive(
    gateLevelLattice,
    "BUF",
    ["A"],
    ["Z"],
    {vs: Array<GateLevelValue> => vs[0]}
)
let notGate = Primitive(
    gateLevelLattice,
    "NOT",
    ["A"],
    ["Z"],
    {vs: Array<GateLevelValue> => not(vs[0])}
)
let andGate = Primitive(
    gateLevelLattice,
    "AND",
    ["A", "B"],
    ["Z"],
    {vs: Array<GateLevelValue> => and(vs[0], vs[1])}
)
let orGate = Primitive(
    gateLevelLattice,
    "OR",
    ["A", "B"],
    ["Z"],
    {vs: Array<GateLevelValue> => or(vs[0], vs[1])}
)
let nandGate = Primitive(
    gateLevelLattice,
    "NAND",
    ["A", "B"],
    ["Z"],
    {vs: Array<GateLevelValue> => nand(vs[0], vs[1])}
)
let norGate = Primitive(
    gateLevelLattice,
    "NAND",
    ["A", "B"],
    ["Z"],
    {vs: Array<GateLevelValue> => nor(vs[0], vs[1])}
)
let xorGate = Primitive(
    gateLevelLattice,
    "XOR",
    ["A", "B"],
    ["Z"],
    {vs: Array<GateLevelValue> => xor(vs[0], vs[1])}
)
let xnorGate = Primitive(
    gateLevelLattice,
    "XNOR",
    ["A", "B"],
    ["Z"],
    {vs: Array<GateLevelValue> => xnor(vs[0], vs[1])}
)
let gateLevelPrimitives = HashSet<GateLevelValue>(
    [
        bufGate,
        notGate,
        andGate,
        orGate,
        nandGate,
        norGate,
        xorGate,
        xnorGate
    ]
)
let gateLevelSignature = Signature<GateLevelValue>(
    gateLevelLattice,
    gateLevelPrimitives
)
