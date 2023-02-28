/**
 * src/comparable.cj
 *
 * Utility functions for reasoning with comparable
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
/**
 * Get the maximum element in an iterable of elements which can be mapped to
 * comparables, given some minimum threshold
 *
 * @param xs The iterable
 * @param lowest Some predetermined base minimum element
 * @param f A function mapping each element in xs to a comparable
 * @return The highest element
 */
public func max<T, U>(
    xs : Iterable<T>, lowest : U, f : (T) -> U
): U where U <: Comparable<U> {
    fold_left({ acc : U, cur : T => max(acc, f(cur))}, lowest, xs)
}
/**
 * Get the maximum element in an iterable of elements which can be mapped to
 * integers
 *
 * @param xs The iterable
 * @param f A function mapping each element in xs to an integer
 * @return The highest element
 */
public func max<T>(xs : Array<T>, f : (T) -> Int64) {
    max(xs, Int64.Min, f)
}
/**
 * Get the minimum element in an iterable of elements which can be mapped to
 * comparables, given some maximum threshold
 *
 * @param xs The iterable
 * @param lowest Some predetermined base maximum element
 * @param f A function mapping each element in xs to a comparable
 * @return The lowest element
 */
public func min<T, U>(
    xs : Array<T>, highest : U, f : (T) -> U
) : U where U <: Comparable<U> {
    fold_left({ acc : U, cur : T => min(acc, f(cur))}, highest, xs)
}
/**
 * Get the minimum element in an iterable of elements which can be mapped to
 * integers
 *
 * @param xs The iterable
 * @param f A function mapping each element in xs to an integer
 * @return The lowest element
 */
public func min<T>(xs : Array<T>, f : (T) -> Int64) {
    min(xs, Int64.Max, f)
}
/**
 * Get the maximum element from two elements with a less or equal relation
 *
 * @param x
 * @param y
 * @return The greatest element of x and y
 */
public func max<T>(x : T, y : T) : T where T <: LessOrEqual<T> {
    if(x <= y) {
        y
    } else {
        x
    }
}
/**
 * Get the minimum element from two elements with a less or equal relation
 *
 * @param x
 * @param y
 * @return The least element of x and y
 */
public func min<T>(x : T, y : T) : T where T <: LessOrEqual<T> {
    if(x <= y) {
        x
    } else {
        y
    }
}