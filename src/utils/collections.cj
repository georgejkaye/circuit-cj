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
public func concat<T, U, V>(
    xs : Array<T>, fx : (T) -> V, ys : Array<U>, fy : (U) -> V
) : Array<V> {
    Array<V>(xs.size + ys.size){
        i : Int64 =>
            if(i < xs.size) {
                fx(xs[i])
            } else {
                fy(ys[i - xs.size])
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
    concat(xs, { t => t }, ys, { t => t})
}
public func concat<T>(xss : Array<Array<T>>) : Array<T> {
    concat(xss, { t : T => t })
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
public func concat<T, U>(xs : Array<T>, f : (T) -> Array<U>) : Array<U> {
    Array(Sum(xs, { xs => f(xs).size }), {
        i =>
            var j = i
            var elm = 0
            for(x in xs){
                elm++
                let array = f(x)
                if(j < array.size) {
                    return array[j]
                }
                j -= array.size
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
 * @param start
 * @param end
 */
public func collectionToString<T>(
    collection : Collection<T>, printFn : (T, Int64) -> String,
    openingBracket!: String = "{", closingBracket!: String = "}",
    delimiter!: String = ", ", start!: Int64 = 0, end!: Int64 = collection.size
) : String {
    let str = foldi_left(
        {acc : String, i : Int64, cur : T =>
            let delimiter = if(i != collection.size - 1) {
                delimiter
            } else {
                ""
            }
            "${acc}${printFn(cur, i)}${delimiter}"

        }, "", collection, start: start, end: end
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
 * @param start
 * @param end
 */
public func collectionToString<T>(
    collection : Collection<T>, openingBracket!: String = "{",
    closingBracket!: String = "}", delimiter!: String = ", ",
    start!: Int64 = 0, end!: Int64 = collection.size
) : String where T <: ToString {
    collectionToString(
        collection, { t, i => "${t}" }, openingBracket: openingBracket,
        closingBracket: closingBracket, delimiter: delimiter, start: start,
        end: end
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
 * Get a bespokely printed string of an array.
 *
 * @param array
 * @param printFn The function that generates a string for an element
 * @param openingBracket
 * @param closingBracket
 * @param delimiter
 */
public func arrayToString<T>(
    array : Array<T>, openingBracket!: String = "[",
    closingBracket!: String = "]", delimiter!: String = ", "
) : String where T <: ToString {
    arrayToString(
        array, { t, _ => "${t}" }, openingBracket: openingBracket,
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
 * Given an array of things and a way of getting strings out of them,
 * concatenate these strings together with some delimiter.
 *
 * @param fn
 * @param ts
 * @param initial
 * @param delimiter
 * @param start
 * @param end
 * @return The concatenated string
 */
public func concatStrings<T>(
    fn : (T, Int64) -> String, ts : Collection<T>, initial!: String = "",
    delimiter!: String = "", start!: Int64 = 0, end!: Int64 = ts.size
) : String {
    foldi_left(
        { acc, i, cur =>
            let str = fn(cur, i)
            if(i == 0) {
                str
            } else {
                "${acc}${delimiter}${str}"
            }
        }, initial, ts, start: start, end: end
    )
}
/**
 * Given an array of things and a way of getting strings out of them,
 * concatenate these strings together with some delimiter.
 *
 * @param fn
 * @param ts
 * @param initial
 * @param delimiter
 * @param start
 * @param end
 * @return The concatenated string
 */
public func concatStrings<T>(
    fn : (T) -> String, ts : Collection<T>, initial!: String = "",
    delimiter!: String = "", start!: Int64 = 0, end!: Int64 = ts.size
) : String {
    concatStrings(
        { t : T, _ : Int64 => fn(t) }, ts, initial: initial,
        delimiter: delimiter, start: start, end: end
    )
}
/**
 * Given a way of translating numbers into strings, concatenate these strings
 * over a range together with some delimiter.
 *
 * @param fn
 * @param initial
 * @param delimiter
 * @param start
 * @param end
 * @return The concatenated string
 */
public func concatStrings(
    fn : (Int64) -> String, initial!: String = "", delimiter!: String = "",
    start!: Int64 = 0, end!: Int64
) : String {
    fold_left(
        { acc, i =>
            let cur = fn(i)
            if(i == 0) {
                cur
            } else {
                "${acc}${delimiter}${cur}"
            }
        }, initial, start: start, end: end
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
/**
 * Given an array of pairs (x, n), create an array of each element x repeated n
 * times.
 *
 * @param ts
 * @return the array
 */
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
/**
 * Given a function that maps Ts to W-arrays, and a hashmap that maps Us to Ts,
 * create an array in which each element is a hash map from Us to Ws,
 * representing a different way of picking the elements in the W-arrays.
 * For example:
 *
 * [a: [0,1], b: [0,1,2]] ->
 * [[a: 0, b: 0],[a: 0, b: 1],[a: 0, b: 2],[a: 1, b: 0],[a: 1, b: 1],
 *  [a: 1, b: 2]]
 *
 * @param ts
 * @return the array of combinations
 */
public func GetAllCombinations<T,U,W>(
    xss : HashMap<U, T>, fn : (T) -> HashSet<W>
) : Array<HashMap<U, W>>
    where U <: Hashable & Equatable<U>, W <: Hashable & Equatable<W>
{
    if(xss.size == 0) {
        Array<HashMap<U, W>>()
    } else {
        let fixedMap = HashMap<U, Array<W>>()
        forEach<(U, T)>({ kv : (U, T), i : Int64 =>
            let (k, v) = kv
            fixedMap.put(k, fn(v).toArray())
        }, xss)
        let fixedMapArray = fixedMap.toArray()
        let subCombinations = Array<Int64>(xss.size){ i =>
            fold_left({
                acc, cur =>
                    let (_, v) = cur
                    acc * v.size
            }, 1, fixedMapArray, start: i )
        }
        Array<HashMap<U, W>>(subCombinations[0]){ i : Int64 =>
            let comb = HashMap<U, W>(fixedMapArray.size)
            forEach<(U, Array<W>)>({
                kv : (U, Array<W>), j : Int64 =>
                let (k, ws) = kv
                let divisor = if(j == fixedMapArray.size - 1){
                    1
                } else {
                    subCombinations[j+1]
                }
                let modulo = ws.size
                let element = (i / divisor) % modulo
                comb.put(k, ws[element])
            }, fixedMapArray)
            comb
        }
    }
}