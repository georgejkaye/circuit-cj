/**
 * helpers.cj
 *
 * This file contains some helper functions used within the library
 */
package utils

from std import collection.ArrayList
from std import math.*
from std import collection.HashMap

// This exists in bigint, but should probably be in the main math library
public func log2Ceil(n: Int64): Int64 {
    unsafe { return Int64(ceil(log2(Float64(n)))) }
}

public func unsafeGet<T,U>(map : HashMap<T,U>, key: T, exn : ((T)
 -> Exception)) : U where T <: Equatable<T> & Hashable {
    match (map.get(key)) {
        case Some(v) => v
        case None => throw exn(key)
    }
}
public func unsafeGet<T,U>(map : HashMap<T,U>, key: T) : U where T <: Equatable<T> & Hashable {
    unsafeGet<T,U>(map, key, { k : T => throw NoAssociatedValueException("unsafeGet")})
}

public func Sum(ns : Array<Int64>) : Int64 {
    fold_left({ acc : Int64, cur : Int64 => acc + cur}, 0, ns)
}
public func prepend<T>(x : T, ys : Array<T>) {
    Array<T>(ys.size + 1){
        i : Int64 =>
            if(i == 0) {
                x
            } else {
                ys[i-1]
            }
    }
}
public func append<T>(xs : Array<T>, y : T) {
    Array<T>(xs.size + 1){
        i : Int64 =>
            if(i == xs.size) {
                y
            } else {
                xs[i]
            }
    }
}
/**
 * Get a bespokely printed string of a collection.
 *
 * @param collection
 * @param printFn The function that generates a string for an element
 * @param openingBracket
 * @param closingBracket
 * @param delimiter
 */
public func printCollection<T>(
    collection : Collection<T>,
    printFn : (T) -> String,
    openingBracket!: String = "{",
    closingBracket!: String = "}",
    delimiter!: String = ","
) : String {
    let str = foldi_left(
        {acc : String, cur : T, i : Int64 =>
            let delimiter = if(i != collection.size - 1) {
                delimiter
            } else {
                ""
            }
            "${acc}${printFn(cur)}${delimiter}"

        }, "", collection
    )
    "${openingBracket}${str}${closingBracket}"
}
/**
 * Get a bespokely printed string of an array.
 *
 * @param array
 * @param printFn The function that generates a string for an element
 * @param openingBracket
 * @param closingBracket
 * @param delimiter
 */
public func printArray<T>(
    array : Array<T>,
    printFn : (T) -> String,
    openingBracket!: String = "[",
    closingBracket!: String = "]",
    delimiter!: String = ",",
    reverse!: Bool = false
) : String {
    printCollection(
        array, printFn, openingBracket: openingBracket,
        closingBracket: closingBracket, delimiter: delimiter
    )
}