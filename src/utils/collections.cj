/**
 * utils/arrays.cj
 *
 * Functions for handling arrays and general collections
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
/**
 * Given an array and an element, create a new array with the contents of the
 * first array preceeded by the new element.
 *
 * @param x
 * @param ys
 * @return The array x ++ ys
 */
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
/**
 * Given an array and an element, create a new array with the contents of the
 * first array followed by the new element.
 *
 * @param xs
 * @param y
 * @return The array xs ++ u
 */
public func append<T>(xs : Array<T>, y : T) : Array<T> {
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
 * Given two arrays, create a new array with their concatenation.
 *
 * @param xs
 * @param ys
 * @return The concatenation of xs and ys
 */
public func concat<T>(xs : Array<T>, ys : Array<T>) : Array<T> {
    Array<T>(xs.size + ys.size){
        i : Int64 =>
            if(i < xs.size) {
                xs[i]
            } else {
                ys[i - xs.size]
            }
    }
}
public func concat<T>(xss : Array<Array<T>>) : Array<T> {
    concat(xss, { t => t })
}
public func concat<T, U>(xss : Array<Array<T>>, f : (T) -> U) : Array<U> {
    Array(Sum(xss, { xs => xs.size }), {
        i =>
            var j = i
            var elm = 0
            for(xs in xss){
                elm++
                if(j < xs.size) {
                    return f(xs[j])
                }
                j -= xs.size
            }
            throw UnreachableCodeException()
    })
}

public interface ExtraArrayUtils<T> {
    func sliceArray(start!: Int64, end!: Int64) : Array<T>
    func partition(at : Int64) : (Array<T>, Array<T>)
}

extend Array<T> <: ExtraArrayUtils<T> {
    public func sliceArray(
        start!: Int64 = 0, end!: Int64 = this.size
    ) : Array<T> {
        let len = end - start
        this.slice(start, len)
    }
    public func partition(at : Int64) : (Array<T>, Array<T>) {
        let first = this.sliceArray(end: at)
        let second = this.sliceArray(start: at)
        (first, second)
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
public func collectionToString<T>(
    collection : Collection<T>, printFn : (T, Int64) -> String,
    openingBracket!: String = "{", closingBracket!: String = "}",
    delimiter!: String = ", "
) : String {
    let str = foldi_left(
        {acc : String, i : Int64, cur : T =>
            let delimiter = if(i != collection.size - 1) {
                delimiter
            } else {
                ""
            }
            "${acc}${printFn(cur, i)}${delimiter}"

        }, "", collection
    )
    "${openingBracket}${str}${closingBracket}"
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
public func collectionToString<T>(
    collection : Collection<T>, openingBracket!: String = "{",
    closingBracket!: String = "}", delimiter!: String = ", "
) : String where T <: ToString {
    collectionToString(
        collection, { t, i => "${t}" }, openingBracket: openingBracket,
        closingBracket: closingBracket, delimiter: delimiter
    )
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
public func arrayToString<T>(
    array : Array<T>, printFn : (T, Int64) -> String,
    openingBracket!: String = "[", closingBracket!: String = "]",
    delimiter!: String = ", "
) : String {
    collectionToString(
        array, printFn, openingBracket: openingBracket,
        closingBracket: closingBracket, delimiter: delimiter
    )
}
/**
 * Get a bespokely printed string of an arraylist.
 *
 * @param array
 * @param printFn The function that generates a string for an element
 * @param openingBracket
 * @param closingBracket
 * @param delimiter
 */
public func arrayListToString<T>(
    list : ArrayList<T>, printFn : (T, Int64) -> String,
    openingBracket!: String = "[", closingBracket!: String = "]",
    delimiter!: String = ", "
) : String {
    collectionToString(
        list, printFn, openingBracket: openingBracket,
        closingBracket: closingBracket, delimiter: delimiter
    )
}
/**
 * Attempt to get the value mapped to by a key in a hashmap in an unsafe way,
 * throwing NoneException if it doesn't exist.
 *
 * @param map
 * @param key
 * @return The value mapped by the key
 */
public func unsafeGet<T,U>(map : HashMap<T,U>, key: T) : U
    where T <: Equatable<T> & Hashable
{
    map.get(key).getOrThrow()
}
/**
 * Given an array of strings, concatenate them together with some delimiter.
 *
 * @param strings
 * @param delimiter The delimiter between the strings, by default ", "
 * @return The concatenated string
 */
public func concatStrings(
    strings : Collection<String>, delimiter!: String = ", "
) : String {
    collectionToString<String>(
        strings, {s, _ => s}, openingBracket: "", closingBracket: "",
        delimiter: delimiter
    )
}
/**
 * Given an array of collections of elements, get the length of the longest one.
 *
 * @param xss The array of collections
 * @return The length of the longest collection
 */
public func longest<T, U>(xss : Array<U>) : Int64 where U <: Collection<T> {
    max(xss, { i, xs => xs.size })
}
public func ElementNumberArrayToArray<T>(ts : Array<(T, Int64)>) : Array<T> {
    let length = Sum(ts, { tx => tx[1] })
    Array<T>(length, {
        i =>
            var runningSum = 0
            for(tx in ts) {
                let (elem, len) = tx
                if(i < runningSum + len) {
                    return elem
                }
            }
            return ts[ts.size - 1][0]
    })
}