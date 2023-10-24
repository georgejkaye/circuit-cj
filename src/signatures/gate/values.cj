/**
 * signatures/gate/values.cj
 *
 * Gate level values
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
/**
 * Enum of Belnap values (four valued logic)
 */
public enum GateLevelValue {
    | NONE | FALSE | TRUE | BOTH
}
let trueLevel = 1
extend GateLevelValue <: Hashable {
    public func hashCode(): Int64 {
        match (this) {
            case NONE => 0
            case FALSE => 1
            case TRUE => 2
            case BOTH => 3
        }
    }
}
extend GateLevelValue <: Equatable<GateLevelValue> {
    public operator func ==(rhs: GateLevelValue) : Bool {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs: GateLevelValue) : Bool {
        !(this == rhs)
    }
}
extend GateLevelValue <: LessOrEqual<GateLevelValue> {
    public operator func <=(rhs : GateLevelValue) : Bool {
        match(this) {
            case NONE => true
            case FALSE => match(rhs) {
                case TRUE => false
                case NONE => false
                case _   => true
            }
            case TRUE => match(rhs) {
                case FALSE => false
                case NONE => false
                case _   =>  true
            }
            case BOTH => match(rhs) {
                case BOTH => true
                case _   => false
            }
        }
    }
}
extend GateLevelValue <: HasName {
    public func GetName(): String {
        this.toString()
    }
}
extend GateLevelValue <: ToString {
    public func toString(): String {
        match (this) {
            case NONE => "\u{22A5}"
            case FALSE => "0"
            case TRUE => "1"
            case BOTH => "\u{22A4}"
        }
    }
}
extend GateLevelValue <: ValueSymbol<GateLevelValue>
{
    public static func GetDisconnected() : GateLevelValue {
        NONE
    }
    public static func GetWaveformHeight() : Int64 {
        trueLevel
    }
    public func GetWaveformLevel() : Option<Int64> {
        match(this) {
            case NONE => None
            case FALSE => Some(0)
            case TRUE => Some(trueLevel)
            case BOTH => None
        }
    }
}
extend GateLevelValue <: Decimal<GateLevelValue> {
    /**
     * Convert a decimal number to a list of truth values
     * The list is ordered with the lsb first
     * e.g. 10 => [0, 1, 0, 1, 0, ...]
     *
     * @param w The width of the resulting list
     * @param x The decimal number to convert
     */
    public static func UnsignedDecToSignal(
        x : Int64, width!: Int64
    ) : Signal<GateLevelValue> {
        AssertNonNegative(x)
        let required = Int64(ceil(log2(Float64(x + 1))))
        AssertGreaterThanOrEqualTo(width, required)
        // Set up the list
        let bin = Array<GateLevelValue>(width, {_ => FALSE})
        var num = x
        // Divide by two w times, setting the remainder to the ith bit of the
        // list. If we run out of w before we run out of list, the msbs will be
        // ignored
        for(i in 0..width){
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
    public static func SignedDecToSignal(
        x : Int64, width!: Int64
    ) : Signal<GateLevelValue> {
        let numberRepresented = if (x < 0) { abs(x) } else { x + 1 }
        let bitsRequired = Int64(ceil(log2(Float64(numberRepresented)))) + 1
        AssertGreaterThanOrEqualTo(width, bitsRequired)
        let bin = UnsignedDecToSignal(abs(x), width: width).GetValues()
        if(x < 0) {
            Invert(bin)
            AddOne(bin)
        }
        if(x < 0) {

        }
        Signal(bin)
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
}
/**
 * Miscellaneous helper functions
 */
extend GateLevelValue {
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
 * The lattice A4 on the Belnap values
 */
let gateLevelLatticeStructure = FiniteLattice(
    HashSet([NONE, TRUE, FALSE, BOTH])
)
/**
 * Generate a clock waveform of Belnap values: a waveform of regularly
 * alternating TRUE and FALSE values
 *
 * @param rate
 * @param cycles
 * @return The clock waveform
 */
public func GenerateClock(
    period!: Int64, duty!: Float64 = 0.5, cycles!: Int64
) : Waveform<GateLevelValue> {
    GenerateClock(
        period: period, cycles: cycles, duty: duty, high: TRUE, low: FALSE
    )
}