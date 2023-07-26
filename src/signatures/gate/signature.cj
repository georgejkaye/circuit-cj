/**
 * signature/gate/signature.cj
 *
 * The 'belnap signature' for gate level circuits
 */
package signatures.gate
from std import collection.ArrayList, collection.HashSet
from std import math.log2, math.ceil
import assertions.*
/**
 * Enum of Belnap values (four valued logic)
 */
public enum GateLevelValue {
    | NONE | TRUE | FALSE | BOTH
}
let trueLevel = 1

/**
 * Instantiate Belnap values as a type of value symbols
 */
extend GateLevelValue
    <: ValueSymbol<GateLevelValue> & Decimal<GateLevelValue>
{
    public static func GetDisconnected() : GateLevelValue {
        NONE
    }
    public static func GetHighestWaveformLevel() : Int64 {
        trueLevel
    }
    public func GetWaveformLevel() : Option<Int64> {
        match(this) {
            case NONE => None
            case TRUE => Some(trueLevel)
            case FALSE => Some(0)
            case BOTH => None
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
    public operator func <=(rhs : GateLevelValue) : Bool {
        match(this) {
            case NONE => true
            case TRUE => match(rhs) {
                case FALSE => false
                case NONE => false
                case _   =>  true
            }
            case FALSE => match(rhs) {
                case TRUE => false
                case NONE => false
                case _   => true
            }
            case BOTH => match(rhs) {
                case BOTH => true
                case _   => false
            }
        }
    }
    public operator func ==(rhs: GateLevelValue) : Bool {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs: GateLevelValue) : Bool {
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
    /**
     * Convert a decimal number to a list of truth values
     * The list is ordered with the lsb first
     * e.g. 10 => [0, 1, 0, 1, 0, ...]
     *
     * @param w The width of the resulting list
     * @param x The decimal number to convert
     */
    public static func UnsignedDecToSignal(
        x : Int64, w : Int64
    ) : Signal<GateLevelValue> {
        AssertNonNegative(x)
        let required = Int64(ceil(log2(Float64(x+1))))
        AssertAtLeast(w, required)
        // Set up the list
        let bin = Array<GateLevelValue>(w, {x : Int64 => FALSE})
        var num = x
        // Divide by two w times, setting the remainder to the ith bit of the
        // list. If we run out of w before we run out of list, the msbs will be
        // ignored
        for(i in 0..w){
            let rem = if(num % 2 == 1){ TRUE } else { FALSE }
            bin.set(i, rem)
            num = num / 2
        }
        return Signal(bin)
    }
    /**
     * 'Add one' to an array of booleans, i.e. flip the lowest bit and
     * propagate the changes throughout the list
     *
     * @param x The array of booleans
     */
    static func AddOne(x : Array<GateLevelValue>) : Unit {
        for (i in 0..(x.size - 1)) {
            if (x[i].IsTrue()) {
                x[i] = FALSE
            } else {
                x[i] = TRUE
                return
            }
        }
    }
    /**
     * Invert an array of bools, i.e. flip each bit
     *
     * @param x The array of booleans
     */
    static func Invert(x : Array<GateLevelValue>) : Unit {
        for (i in 0..(x.size)){
            x[i] = x[i].Negate()
        }
    }
    /**
     * Convert a decimal number to a list of truth values in two's complement
     * The list is ordered with the lsb first
     * e.g. 10 => [0, 1, 0, 1, 0, ...]
     *
     * @param x The number to convert
     * @param w The width of the bitstring
     * @return The corresponding bitstring
     */
    public static func SignedDecToSignal(
        x : Int64, w : Int64
    ) : Signal<GateLevelValue> {
        let bin = UnsignedDecToSignal(abs(x), w).values
        if(x < 0) {
            Invert(bin)
            AddOne(bin)
        }
        Signal(bin)
    }
    /**
     * Convert a decimal number to a list of truth values
     * The list is ordered with the lsb first
     * e.g. 10 => [0, 1, 0, 1, 0, ...]
     * If signed, the number is represented in two's complement.
     *
     * @param x The number to convert
     * @param w The width of the bitstring
     * @param signed
     * @return The corresponding bitstring
     */
    public static func DecToSignal(
        x : Int64, w : Int64, signed : Bool
    ) : Signal<GateLevelValue> {
        if(signed) {
            GateLevelValue.SignedDecToSignal(x, w)
        } else {
            GateLevelValue.UnsignedDecToSignal(x, w)
        }
    }
    public static func UnsignedSignalToDec(
        signal : Signal<GateLevelValue>
    ) : Option<Int64> {
        var x = 0
        for(i in 0..signal.GetWidth()) {
            let bit = signal.GetBit(i)
            let exponent = i
            match(bit) {
                case NONE => return None
                case FALSE => ()
                case TRUE => x += pow(2, exponent)
                case BOTH => return None
            }
        }
        Some(x)
    }
    public static func SignedSignalToDec(
        signal : Signal<GateLevelValue>
    ) : Option<Int64> {
        let isPositive = match(signal.GetBit(signal.GetWidth() - 1)) {
            case NONE => return None
            case FALSE => true
            case TRUE => false
            case BOTH => return None
        }
        let complemented = if(isPositive) {
            signal
        } else {
            let values = Array(signal.GetValues())
            Invert(values)
            AddOne(values)
            Signal(values)
        }
        let value = UnsignedSignalToDec(complemented)
        match(value) {
            case None => None
            case Some(v) =>
                if(isPositive) {
                    v
                } else {
                    -v
                }
        }
    }
    public static func SignalToDec(
        signal : Signal<GateLevelValue>, signed : Bool
    ) : Option<Int64> {
        if(signed) {
            SignedSignalToDec(signal)
        } else {
            UnsignedSignalToDec(signal)
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
type BelnapCircuit = Hypergraph<GateLevelValue, GateLevelPrimitive>
type BelnapInterfacedCircuit =
    InterfacedHypergraph<GateLevelValue, GateLevelPrimitive>
/**
 * Instantiate GateLevelPrimitive as a type of gate symbols
 */
extend GateLevelPrimitive <:
    PrimitiveSymbol<GateLevelValue, GateLevelPrimitive>
{
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
    public func GetArity(): Int64 {
        this.GetInputPorts().size
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
 * The lattice A4 on the Belnap values
 */
let gateLevelLatticeStructure = FiniteLattice(
    HashSet([NONE, TRUE, FALSE, BOTH])
)
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
/**
 * Convert an array of Belnap values to the corresponding number, if appropriate
 *
 * @param values The array of Belnap values
 * @param signed Whether to interpret this as a signed value
 * @return An option containing the number represented, if appropriate
 */
func GateLevelValueToDec(
    values : Array<GateLevelValue>, signed : Bool
) : Option<Int64> {
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
        var carry = true
        for (i in 0..values.size) {
            match(values[i]) {
                case TRUE =>
                    if(!carry) {
                        x += pow(2, i)
                    }
                case FALSE =>
                    if(carry) {
                        x += pow(2, i)
                        carry = false
                    }
                case _ => return None<Int64>
            }
        }
    } else {
        for (i in 0..values.size) {
            match(values[i]) {
                case TRUE =>
                    x += pow(2, i)
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
public let belnapSignature = Signature<GateLevelValue, GateLevelPrimitive>(
    "Belnap",
    gateLevelLatticeStructure,
    HashSet([BUF, NOT, AND, OR, NAND, NOR, XOR, XNOR]),
    gateLevelInterpretation,
    GateLevelValueToDec
)
public func GenerateClock(
    rate!: Int64, cycles!: Int64
) : Waveform<GateLevelValue> {
    GenerateClock(rate: rate, cycles: cycles, high: TRUE, low: FALSE)
}