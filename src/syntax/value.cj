/**
 * syntx/value.cj
 *
 * This file contains the values (or signals) that flow in circuits
 *
 * @author George Kaye
 * @since 0.2
 */

package syntax

import assertions.*

/**
 * A value is a signal that flows in our wires
 * The Bottom value represents a disconnected wire (no information)
 * and the Top value represents a short circuit (too much information).
 * True and False are standard.
 */
public enum Value { Bottom | False | True | Top }
extend Value <: ToString & Equatable<Value> {
    public func toString() : String {
        match(this) {
            case Bottom => "\u{22A5}"
            case False => "0"
            case True => "1"
            case Top => "\u{22A4}"
        }
    }
    public func IsTrue() : Bool {
        match(this){
            case True => true
            case _ => false
        }
    }
    public func Negate() : Value {
        match(this) {
            case Bottom => Bottom
            case False => True
            case True => False
            case Top => Top
        }
    }
    public operator func ==(rhs : Value) : Bool {
        match(this) {
            case Bottom => match(rhs) {
                case Bottom => true
                case _ => false
            }
            case False => match(rhs) {
                case False => true
                case _ => false
            }
            case True => match(rhs) {
                case True => true
                case _ => false
            }
            case Top => match(rhs) {
                case Top => true
                case _ => false
            }
        }
    }
    public operator func !=(rhs : Value) : Bool {
        !(this == rhs)
    }
}

/**
 * Generate a string in binary corresponding to an array of values.
 * True and False are printed as 1 and 0 as standard, Bottom and Top
 * as B and T.
 *
 * @param bits The array of values to convert. Most significant bit is bits[0].
 * @return The bitstring corresponding to the array
 */
public func BitString(bits : Array<Value>) : String {
    AssertNonEmpty(bits, "values")
    fold_right({acc : String, v : Value => "${acc}${v}"}, "", bits)
}

/**
 * Print a string in a given number representation corresponding to
 * an array of values.
 * Decimal representation is only computable if there are no Top or Bottom
 * values in the array; if there are then the bitstring will be returned.
 *
 * @param vs The array of values to convert. Least significant bit is bits[0].
 * @param rep The number representation to use
 * @return The string corresponding to the array
 */
public func PrintValue(
    vs : Array<Value>,
    signed : Bool,
    rep : NumberRepresentation
) : String {
    AssertNonEmpty(vs, "values")
    match(rep) {
        case BIN => BitString(vs)
        case DEC =>
            var x = 0
            var negative = ""
            if (signed) {
                // In a signed number, the first bit indicates if
                // the number is negative
                match(vs[vs.size - 1]) {
                    case Bottom => return BitString(vs)
                    case True => negative = "-"
                    case False => ()
                    case Top => return BitString(vs)
                }
                for (i in 0..vs.size) {
                    var carry = true
                    match(vs[i]) {
                        case Bottom => return BitString(vs)
                        case True =>
                            if(!carry) {
                                x += 2**UInt64(i)
                            }
                        case False =>
                            if(carry) {
                                x += 2**UInt64(i)
                                carry = false
                            }
                        case Top => return BitString(vs)
                    }
                }
            } else {
                for (i in 0..vs.size) {
                    match(vs[i]) {
                        // Only a 1 contributes to the total sum
                        case True   => x += 2**UInt64(i)
                        case False  => ()
                        // We can't translate Bottom or Top, so
                        // fallback to bitstring
                        case Bottom => return BitString(vs)
                        case Top    => return BitString(vs)
                    }
                }
            }
            "${negative}${x}"
    }
}

public struct Signal <: ToString & HasName & Specifiable & HasWidth & Equatable<Signal> {
    public Signal(
        public let values : Array<Value>,
        public let signed : Bool
    ){}
    public init(v: Value, n : Int64) {
        this(Array<Value>(n, {i : Int64 => v}), false)
    }
    public func GetName() : String {
        PrintValue(this.values, this.signed, GetNumberRepresentation())
    }
    public func GetValueAsRepresentation(rep : NumberRepresentation) : String {
        PrintValue(this.values, this.signed, rep)
    }
    public func toString() : String {
        "${values}"
    }
    public func GetInputPorts() : Array<Port> {
        []
    }
    public func GetOutputPorts() : Array<Port> {
        [Port(values.size)]
    }
    public func GetWidth() : Int64 {
        this.values.size
    }
    public operator func ==(rhs : Signal) : Bool {
        this.values == rhs.values
    }
    public operator func !=(rhs : Signal) : Bool {
        !(this == rhs)
    }
}

public struct Waveform <: ToString & HasName & HasWidth {
    let width : Int64
    public Waveform(
        public let signals : Array<Signal>
    ){
        this.width = AssertSignalsSameWidth(signals)
    }
    public func toString() : String {
        printArray(
            this.signals,
            "",
            "",
            " :: ",
            { s : Signal => s.GetName() },
            true
        )
    }
    public func GetName() : String {
        this.toString()
    }
    public func GetWidth() : Int64 {
        this.width
    }
}