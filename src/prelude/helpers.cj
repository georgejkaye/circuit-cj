/**
 * helpers.cj
 *
 * This file contains some helper functions used within the library
 */
package prelude

from std import collection.ArrayList
from std import math.*
from std import collection.HashMap

public func fold_left<T,U>(f : (U, T) -> U, initial : U,  xs : Iterable<T>) : U {
    var acc = initial
    for (x in xs) {
        acc = f(acc, x)
    }
    acc
}
public func fold_left2<T, U, V>(f : (V, T, U) -> V, initial : V, xs : Array<T>, ys : Array<U>) : V {
    var acc = initial
    for(i in 0..xs.size) {
        let x = xs[i]
        let y = ys[i]
        acc = f(acc, x, y)
    }
    acc
}
public func fold_right<T,U>(f : (U, T) -> U, initial : U,  xs : Array<T>) : U {
    var acc = initial
    for (i in 0..xs.size) {
        acc = f(acc, xs[xs.size - 1 - i])
    }
    acc
}
public func foldi_left<T,U>(f : (U, T, Int64) -> U, initial : U, xs : Array<T>, reverse!: Bool = false) : U {
    var acc = initial
    for(i in 0..xs.size){
        let j = if(reverse) {
            xs.size - 1 - i
        } else {
            i
        }
        let cur = xs[i]
        acc = f(acc, cur, i)
    }
    acc
}
public func foldi_left<T,U>(f : (U, T, Int64) -> U, initial : U, xs : Iterable<T>) : U {
    var acc = initial
    var i = 0
    for (x in xs) {
        acc = f(acc, x, i)
        i++
    }
    acc
}
public func map<T, U>(f : (T) -> U, xs : Array<T>) : Array<U> {
    Array<U>(xs.size, { i : Int64 => f(xs[i]) })
}
public func map2<T, U, V>(f : (T, U) -> V, xs : Array<T>, ys : Array<U>) : Array<V> {
    Array<V>(xs.size, { i : Int64 => f(xs[i], ys[i]) })
}
public func map<T, U>(f : (T) -> U, xs : ArrayList<T>) : ArrayList<U> {
    let acc = ArrayList<U>(xs.size)
    for (x in xs){
        acc.append(f(x))
    }
    acc
}
public func map_list<T, U>(f : (T) -> U, xs : Array<T>) : ArrayList<U> {
    let acc = ArrayList<U>(xs.size)
    for (x in xs){
        acc.append(f(x))
    }
    acc
}
public func mapi<T, U>(f : (T, Int64) -> U, xs : Array<T>) : Array<U> {
    Array<U>(xs.size, { i : Int64 => f(xs[i], i) })
}
public func map_acc<T, U, V>(f : (T, V) -> (U, V), xs : Array<T>, initial : V) : (ArrayList<U>, V) {
    let acc = ArrayList<U>(xs.size)
    var helper = initial
    for (x in xs) {
        let (t, v) = f(x, helper)
        helper = v
        acc.append(t)
    }
    (acc, helper)
}
public func map_acc_2<T,U,V,W>(f : (T, U, V) -> (W, V), xs : Array<T>, ys : Array<U>, initial : V) : (Array<W>, V) {
    let acc = ArrayList<W>(xs.size)
    var helper = initial
    for (i in 0..xs.size) {
        let (w, v) = f(xs[i], ys[i], helper)
        acc.append(w)
        helper = v
    }
    (acc.toArray(), helper)
}
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
