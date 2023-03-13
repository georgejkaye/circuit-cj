/**
 * utils/numeric.cj
 *
 * Functions for manipulating collections of numbers.
 *
 * @author George Kaye
 * @since 0.2
 */
package utils

from std import collection.ArrayList
from std import collection.HashMap
/**
 * Given an array of objects which have some numeric property, compute the sum
 * of these numbers, optionally from some start and end index.
 *
 * @param ts The array
 * @param f The function mapping ts to numbers
 * @param start The start index, default 0
 * @param end The end index, default ts.size
 * @return The sum
 */
public func Sum<T>(
    ts : Array<T>, f : (T) -> Int64, start!: Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    fold_left({ acc, cur => acc + f(cur) }, 0, ts, start: start, end: end)
}
/**
 * Given an array of numbers, compute the sum of these numbers, optionally from
 * some start and end index.
 *
 * @param ts The array
 * @param start The start index, default 0
 * @param end The end index, default ts.size
 * @return The sum
 */
public func Sum(
    ts : Array<Int64>, start! : Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    Sum(ts, { i => i }, start: start, end: end)
}
/**
 * Given an array of objects which have some numeric property, compute the
 * product of these numbers, optionally from some start and end index.
 *
 * @param ts The array
 * @param f The function mapping ts to numbers
 * @param start The start index, default 0
 * @param end The end index, default ts.size
 * @return The product
 */
public func Product<T>(
    ts : Array<T>, f : (T) -> Int64, start!: Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    fold_left({ acc, cur => acc * f(cur) }, 1, ts, start: start, end: end)
}
/**
 * Given an array of numbers, compute the product of these numbers, optionally
 * from some start and end index.
 *
 * @param ts The array
 * @param start The start index, default 0
 * @param end The end index, default ts.size
 * @return The sum
 */
public func Product(
    ts : Array<Int64>, start! : Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    Product(ts, { i => i }, start: start, end: end)
}