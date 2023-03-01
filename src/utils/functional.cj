/**
 * utils/functional.cj
 *
 * Standard higher order functional paradigms (map, fold etc)
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
/**
 * Given some initial value init, a function (acc1, cur) -> acc2, and an
 * iterable xs, compute
 *
 *     f(... f(f(init, xs[0]), xs[1]) ...), xs[n-1])
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The iterable
 * @return The result of the fold
 */
public func fold_left<T,U>(
    f : (U, T) -> U, initial : U,  xs : Iterable<T>
) : U {
    var acc = initial
    for (x in xs) {
        acc = f(acc, x)
    }
    acc
}
/**
 * Given a function (acc1, cur) -> acc2, and an iterable xs, compute
 *
 *     f(... f(f(xs[0], xs[1]), xs[2]) ...), xs[n-1])
 *
 * This can fail: returns None if there is no such element xs[0]
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The iterable
 * @return Some result of the fold if successful, None otherwise
 */
public func fold_left<T>(f : (T, T) -> T, xs : Iterable<T>) : Option<T> {
    var acc = None<T>
    for (x in xs) {
        acc = match(acc) {
            case None => x
            case Some(y) => f(y, x)
        }
    }
    acc
}
/**
 * Given some initial value init, a function (acc1, cur) -> acc2, and two
 * iterables xs and ys, compute
 *
 *     f(... f(f(init, xs[0], ys[0]), xs[1], ys[1]) ...), xs[n-1], ys[n-1])
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The iterable
 * @return The result of the fold
 */
public func fold_left2<T, U, V>(
    f : (V, T, U) -> V, initial : V, xs : Array<T>, ys : Array<U>
) : V {
    var acc = initial
    for(i in 0..xs.size) {
        let x = xs[i]
        let y = ys[i]
        acc = f(acc, x, y)
    }
    acc
}
/**
 * Given some initial value init, a function (acc1, cur, index) -> acc2, and an
 * iterable xs, compute
 *
 *     f(... f(f(init, xs[0], 0), xs[1], 1) ...), xs[n-1], n-1)
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The iterable
 * @return The result of the fold
 */
public func foldi_left<T,U>(
    f : (U, T, Int64) -> U, initial : U, xs : Iterable<T>
) : U {
    var acc = initial
    var i = 0
    for (x in xs) {
        acc = f(acc, x, i)
        i++
    }
    acc
}
/**
 * Given some initial value init, a function (acc1, cur) -> acc2, and an
 * iterable xs, compute
 *
 *     f(xs[0], f(xs[1], f(... f(xs[n-1], init))))
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The iterable
 * @return The result of the fold
 */
public func fold_right<T,U>(f : (U, T) -> U, initial : U,  xs : Array<T>) : U {
    var acc = initial
    for (i in 0..xs.size) {
        acc = f(acc, xs[xs.size - 1 - i])
    }
    acc
}
/**
 * Given a function f and an array xs, create the array ys in which
 * ys[i] = f(xs[i])
 *
 * @param The function (elem, index) -> u
 * @param xs The array
 * @return The result of the map
 */
public func map<T, U>(f : (T) -> U, xs : Array<T>) : Array<U> {
    Array<U>(xs.size, { i : Int64 => f(xs[i]) })
}
/**
 * Given a function f and a collection xs, create the array ys in which
 * each element is the result of applying f to each element obtained using the
 * iterator of xs
 *
 * @param The function (elem, index) -> u
 * @param xs The array
 * @return The result of the map
 */
public func mapCollection<T, U>(f : (T) -> U, xs : Collection<T>) : Array<U> {
    let iterator = xs.iterator()
    Array<U>(xs.size, { i : Int64 => f(iterator.next().getOrThrow()) })
}
/**
 * Given a function f and an array xs, create the array ys in which
 * ys[i] = f(xs[i], i)
 *
 * @param The function (elem, index) -> u
 * @param xs The array
 * @return The result of the map
 */
public func mapi<T, U>(f : (T, Int64) -> U, xs : Array<T>) : Array<U> {
    Array<U>(xs.size, { i : Int64 => f(xs[i], i) })
}
/**
 * Given a function f and two arrays xs and yes, create the array zs in which
 * zs[i] = f(xs[i], ys[i])
 *
 * @param The function (elem, index) -> u
 * @param xs The array
 * @return The result of the map
 */
public func map2<T, U, V>(
    f : (T, U) -> V, xs : Array<T>, ys : Array<U>
) : Array<V> {
    Array<V>(xs.size, { i : Int64 => f(xs[i], ys[i]) })
}