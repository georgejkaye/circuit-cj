/**
 * values.cj
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
extend Value <: ToString {
    public func toString() : String {
        match(this) {
            case Bottom => "⊥"
            case False => "0"
            case True => "1"
            case Top => "⊤"
        }
    }
}

/**
 * Generate a string in binary corresponding to an array of values.
 * True and False are printed as 1 and 0 as standard, Bottom and Top
 * as ⊥ and ⊤.
 *
 * @param bits The array of values to convert. Most significant bit is bits[0].
 * @return The bitstring corresponding to the array
 */
public func BitString(bits : Array<Value>) : String {
    AssertNonEmpty(bits)
    fold_left({acc : String, v : Value => "${acc}${v}"}, "", bits)
}

/**
 * Number representaions, can be BINary or DECimal
 */
public enum NumberRepresentation {
    | BIN
    | DEC
}

/**
 * Print a string in a given number representation corresponding to 
 * an array of values.
 * Decimal representation is only computable if there are no Top or Bottom
 * values in the array; if there are then the bitstring will be returned.
 *
 * @param vs The array of values to convert. Most significant bit is bits[0].
 * @param rep The number representation to use
 * @return The string corresponding to the array
 */
public func PrintValue(vs : Array<Value>, signed : Bool, rep : NumberRepresentation) : String {
    AssertNonEmpty(vs)
    match(rep) {
        case BIN => BitString(vs)
        case DEC =>
            var x = 0
            var negative = ""
            if (signed) {
                // In a signed number, the first bit indicates if
                // the number is negative
                match(vs[0]) {
                    case Bottom => return BitString(vs)
                    case True => negative = "-"
                    case False => ()
                    case Top => return BitString(vs)
                }
                for (i in 0..vs.size()) {
                    var carry = true
                    match(vs[vs.size() - i - 1]) {
                        case Bottom => return BitString(vs)
                        case True => 
                            if(!carry) {
                                x += 2**i
                            }
                        case False => 
                            if(carry) {
                                x += 2**i
                                carry = false
                            }
                        case Top => return BitString(vs)
                    }
                }
            } else {
                for (i in 0..vs.size()) {
                    match(vs[i]) {
                        // Only a 1 contributes to the total sum
                        case True   => x += 2**(vs.size() - 1 - i)
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

/**
 * Signal labels
 */

public let BOTTOM : Label = VALUE([Bottom], false)
public let FALSE : Label = VALUE([False], false)
public let TRUE : Label = VALUE([True], false)
public let TOP : Label = VALUE([Top], false)