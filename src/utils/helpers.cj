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
public func Sum<T>(
    ts : Array<T>, f : (T) -> Int64, start!: Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    var sum = 0
    for(i in start..end) {
        sum = sum + f(ts[i])
    }
    sum
}
public func Sum(
    ts : Array<Int64>, start! : Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    Sum(ts, { i => i }, start: start, end: end)
}
public func Product<T>(
    ts : Array<T>, f : (T) -> Int64, start!: Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    var product = 1
    for(i in start..end) {
        product = product * f(ts[i])
    }
    product
}
public func Product(
    ts : Array<Int64>, start! : Int64 = 0, end!: Int64 = ts.size
) : Int64 {
    Product(ts, { i => i }, start: start, end: end)
}