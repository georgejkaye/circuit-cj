/**
 * semantics/logic.cj
 *
 * Logic operations on values
 *
 * @author George Kaye
 * @since 0.1
 */

package semantics

import syntax.*

/**
 * Get the logical NOT of a values
 * @param v The argument
 * @return The logical AND of the argument
 */
func not(v : Value){
    match(v){
        case Top    => Top
        case Bottom => Bottom
        case True   => False
        case False  => True
    }
}
/**
 * Get the logical AND of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The logical AND of the two arguments
 */
func and(lhs : Value, rhs : Value){
    match(lhs){
        case Top    => Top
        case Bottom => Bottom
        case True   => rhs
        case False  => match(rhs){
                case Top    => Top
                case Bottom => Bottom
                case _       => False
        }
    }
}
/**
 * Get the logical OR of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func or(lhs : Value, rhs : Value){
    match(lhs){
        case Top    => Top
        case Bottom => Bottom
        case False   => rhs
        case True  => match(rhs){
                case Top    => Top
                case Bottom => Bottom
                case _       => True
        }
    }
}
/**
 * Get the logical XOR of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func xor(lhs : Value, rhs : Value){
    match(lhs){
        case Top    => Top
        case Bottom => Bottom
        case False   => rhs
        case True  => match(rhs){
                case Top    => Top
                case Bottom => Bottom
                case v       => not(v)
        }
    }
}
/**
 * Get the join of two values in the lattice
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The join of the two values
 */
func join(lhs : Value, rhs : Value){
    match(lhs){
        case Top    => Top
        case Bottom => rhs
        case True   => match(rhs){
            case Top   => Top
            case False => Top
            case _      => True
        }
        case False  => match(rhs){
            case Top   => Top
            case True  => Top
            case _      => False
        }
    }
}