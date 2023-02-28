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
public func max<T>(x : T, y : T) : T where T <: LessOrEqual<T> {
    if(x <= y) {
        y
    } else {
        x
    }
}
public func min<T>(x : T, y : T) : T where T <: LessOrEqual<T> {
    if(x <= y) {
        x
    } else {
        y
    }
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
public func concat<T>(xs : Array<T>, ys : Array<T>){
    Array<T>(xs.size + ys.size, {
        i : Int64 =>
            if (i < xs.size) {
                xs[i]
            } else {
                ys[i - xs.size]
            }
    })
}

public func printOptString(str : Option<String>) : String {
    match(str) {
        case Some(s) => s
        case None => ""
    }
}
public func printArray<T>(
    arr : Array<T>,
    openBracket : String,
    closeBracket : String,
    delim : String,
    print : (T) -> String,
    reverse : Bool
) : String {
    let str = foldi_left(
        {acc : String, cur : T, i : Int64 =>
            let delimiter = if(i != arr.size - 1) {
                delim
            } else {
                ""
            }
            "${acc}${print(cur)}${delimiter}"

        }, "", arr
    )
    "${openBracket}${str}${closeBracket}"
}
public func concatArray<T,U,V>(
    arr1 : Array<T>,
    arr2 : Array<U>,
    ft : (T) -> V,
    fu : (U) -> V
) : Array<V> {
    Array<V>(
        arr1.size + arr2.size,
    ){
            i : Int64 =>
                if(i < arr1.size) {
                    ft(arr1[i])
                } else {
                    fu(arr2[i - arr1.size])
                }
    }
}

public func id<T>(t : T) : T {
    t
}
public func max<T, U>(xs : Array<T>, lowest : U, f : (T) -> U) : U where U <: Comparable<U> {
    fold_left({ acc : U, cur : T => max(acc, f(cur))}, lowest, xs)
}
public func max<T>(xs : Array<T>, f : (T) -> Int64) {
    max(xs, Int64.Min, f)
}
public func min<T, U>(xs : Array<T>, highest : U, f : (T) -> U) : U where U <: Comparable<U> {
    fold_left({ acc : U, cur : T => min(acc, f(cur))}, highest, xs)
}
public func min<T>(xs : Array<T>, f : (T) -> Int64) {
    min(xs, Int64.Max, f)
}
public func printCollection<T>(ts : Collection<T>) : String where T <: ToString {
    let contents = fold_left(
        {acc, cur => "${acc}, ${cur}"},
        "",
        ts
    )
    "{${contents}}"
}