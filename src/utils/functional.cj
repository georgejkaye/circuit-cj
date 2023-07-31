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
 * Given some initial value init, a function (acc1, cur) -> (acc2, b), and an
 * collection xs, begin computing
 *
 *     f(... f(f(init, xs[0]), xs[1]) ...), xs[n-1])
 *
 * but immediately return when b is true.
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The collection
 * @return The result of the fold
 */
public func fold_left_while<T, U>(
    f : (U, T) -> (U, Bool), initial: U, xs : Collection<T>,
    start!: Int64 = 0, end!: Int64 = xs.size
) : U {
    var acc = initial
    var done = false
    let iter = xs.iterator()
    for(_ in 0..start) {
        iter.next()
    }
    for(_ in start..end){
        let cur = iter.next().getOrThrow()
        let (newAcc, newDone) = f(acc, cur)
        acc = newAcc
        done = newDone
        if(done) {
            return acc
        }
    }
    acc
}
/**
 * Given some initial value init, a function (acc1, cur) -> acc2, and an
 * collection xs, compute
 *
 *     f(... f(f(init, xs[0]), xs[1]) ...), xs[n-1])
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The collection
 * @return The result of the fold
 */
public func fold_left<T,U>(
    f : (U, T) -> U, initial : U,  xs : Collection<T>,
    start!: Int64 = 0, end!: Int64 = xs.size
) : U {
    fold_left_while(
        { acc, cur => (f(acc, cur), false) },
        initial, xs, start: start, end: end
    )
}
/**
 * Given some initial value init, a function (acc1, cur) -> acc2, and start and
 * end integers, compute
 *
 *     f(... f(f(init, start), start+1) ...), end-1)
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The collection
 * @return The result of the fold
 */
public func fold_left<U>(
    f : (U, Int64) -> U, initial : U, start!: Int64 = 0, end!: Int64
) : U {
    var acc = initial
    for(i in start..end) {
        acc = f(acc, i)
    }
    acc
}
/**
 * Given a function (acc1, cur) -> acc2, and a collection xs, compute
 *
 *     f(... f(f(xs[0], xs[1]), xs[2]) ...), xs[n-1])
 *
 * This throws a NoneValueException if the collection is empty
 *
 * @param f The function (acc, cur) -> new acc
 * @param initial The initial value of the accumulator
 * @param xs The collection
 * @return Some result of the fold if successful, None otherwise
 */
public func fold_left<T>(
    f : (T, T) -> T, xs : Collection<T>, end!: Int64 = xs.size
) : T {
    let iter = xs.iterator()
    var acc = iter.next().getOrThrow()
    for(i in 1..end) {
        let cur = iter.next().getOrThrow()
        acc = f(acc, cur)
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
    f : (U, Int64, T) -> U, initial : U,  xs : Collection<T>,
    start!: Int64 = 0, end!: Int64 = xs.size
) : U {
    var acc = initial
    let iter = xs.iterator()
    for(_ in 0..start) {
        iter.next()
    }
    for(i in start..end) {
        let cur = iter.next().getOrThrow()
        acc = f(acc, i, cur)
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
/**
 * Get an array containing the first elements of an array of pairs.
 *
 * @param xs The array of pairs
 * @return the array of first elements
 *
 */
public func fsts<T, U>(xs : Array<(T, U)>) : Array<T> {
    map({ pair : (T, U) => pair[0] }, xs)
}
/**
 * Get an array containing the second elements of an array of pairs.
 *
 * @param xs The array of pairs
 * @return the array of second elements
 *
 */
public func snds<T, U>(xs : Array<(T, U)>) : Array<U> {
    map({ pair : (T, U) => pair[1] }, xs)
}