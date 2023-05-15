/**
 * assertions/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package assertions

import utils.map, utils.mapCollection
/**
 * Types of paramaters to assert conditions about. Used to make debugging
 * messages clearer.
 */
public enum ParamType {
    | Width
    | InEdge
    | OutEdges
    | Owner
    | Inputs
    | Outputs
    | Values
    | Signals
    | Wires
    | InstantFeedback
}
extend ParamType <: ToString {
    public func toString() : String {
        match(this) {
            case Width           => "width"
            case InEdge          => "in edges"
            case OutEdges        => "out edges"
            case Owner           => "owner"
            case Inputs          => "inputs"
            case Outputs         => "outputs"
            case Values          => "values"
            case Signals         => "signals"
            case Wires           => "wires"
            case InstantFeedback => "non-delay-guarded feedback"
        }
    }
}
/**
 * Assert that two objects of are equal.
 *
 * @param t
 * @param u
 */
public func AssertEqual<T, U>(t : T, u : U) : Unit
    where
        T <: Equatable<U> & ToString,
        U <: ToString
{
    if (t != u) {
        throw IncompatibleParameterException2<T, U>(t, u)
    }
}
/**
 * Assert that a number is at least some target number.
 *
 * @param i The number to check
 * @param t The target number
 */
public func AssertAtLeast(i : Int64, t : Int64) : Unit {
    if(i < t) {
        throw InsufficientParameterException(i, t)
    }
}
/**
 * Assert a number is greater than or equal to zero.
 *
 * @param x
 */
public func AssertNonNegative(x : Int64) : Unit {
    AssertAtLeast(x, 0)
}
/**
 * Assert a number is greater than zero.
 *
 * @param x
 */
public func AssertStrictlyPositive(x : Int64) : Unit {
    AssertAtLeast(x, 1)
}
/**
 * Assert that an option is None.
 *
 * @param opt
 * @param paramType
 */
public func AssertIsNone<T>(opt : Option<T>, paramType : ParamType) : Unit
    where T <: ToString
{
    match (opt) {
        case None => ()
        case Some(t) =>
            throw IncompatibleParameterException2(
                paramType, opt, t, None<T>
            )
    }
}
/**
 * Assert that an option is Some.
 *
 * @param opt
 * @param paramType
 * @return The paramType of the option
 */
public func AssertIsNotNone<T>(opt : Option<T>, paramType : ParamType) : T
    where T <: ToString
{
    match (opt) {
        case None =>
            throw IncompatibleParameterException(paramType, opt)
        case Some(t) =>
            t
    }
}
/**
 * Assert that a collection is non-empty
 *
 * @param xs
 * @param paramType
 */
public func AssertNonEmpty<T>(
    xs : Collection<T>
) : Unit {
    if(xs.size == 0) {
        throw EmptyException()
    }
}
/**
 * Assert that a collection of collections is non-empty and each of its elements
 * is also non-empty.
 *
 * @param xss
 * @param paramType
 */
public func AssertElementsNonEmpty<T>(
    xss : Collection<Collection<T>>, paramType : ParamType
) : Unit {
    AssertNonEmpty(xss)
    for(xs in xss) {
        AssertNonEmpty(xs)
    }
}
/**
 * Assert that a collection is empty.
 *
 * @param xs
 * @param paramType
 */
public func AssertEmpty<T>(
    xs : Collection<T>, paramType : ParamType
) : Unit {
    if(xs.size != 0) {
        throw NonEmptyException(paramType)
    }
}
/**
 * Assert that a collection has a given length.
 *
 * @param xs
 * @param length
 */
public func AssertHasLength<T>(
    xs : Collection<T>, length : Int64
) : Unit where T <: ToString {
    if(xs.size != length) {
        throw IncompatibleLengthException<T>(xs, length, true)
    }
}
/**
 * Assert that two collections have the same length.
 *
 * @param xs
 * @param ys
 * @return The length of the two collections
 */
public func AssertSameLength<T, U>(
    xs : Collection<T>, ys : Collection<U>
) : Int64 where T <: ToString {
    if(xs.size != ys.size) {
        throw IncompatibleLengthException<T>(xs, ys.size, true)
    }
    xs.size
}
/**
 * Assert that all the elements of a collection of collections are the same
 * length.
 *
 * @param xss The collection of collections
 * @return The length of each element of the parent collection
 */
public func AssertAllSameLength<T>(
    xss : Collection<Array<T>>
) : Int64 where T <: ToString {
    AssertNonEmpty(xss)
    let iterator = xss.iterator()
    let candidateSize = iterator.next().getOrThrow().size
    for(i in 1..xss.size) {
        let next = iterator.next().getOrThrow()
        AssertHasLength(next, candidateSize)
    }
    candidateSize
}
/**
 * Assert a collection has a length greater than some minimum.
 *
 * @param collection
 * @param n The minimum length
 */
public func AssertMinimumLength<T>(
    xs : Collection<T>, n : Int64
) : Unit where T <: ToString {
    if (xs.size < n) {
        throw IncompatibleLengthException<T>(xs, n, false)
    }
}
/**
 * Assert all elements of a collection have the same parameter.
 *
 * @param xs The collection
 * @param fn The function to translate each element into a parameter
 * @param paramType
 * @return The parameter the elements all share, if such a parameter exists
 */
public func AssertCollectionHasSameParameter<T, U>(
    xs : Collection<T>, fn : (T) -> U, paramType : ParamType
) : U where T <: ToString, U <: ToString & Equatable<U> {
    AssertNonEmpty(xs)
    let iterator = xs.iterator()
    let targetParam = fn(iterator.next().getOrThrow())
    for(i in 1..xs.size) {
        let current = iterator.next().getOrThrow()
        let currentParam = fn(current)
        if (targetParam != currentParam) {
            throw IncompatibleParameterException2<T, U>(
                paramType, current, currentParam, targetParam
            )
        }
    }
    targetParam
}
/**
 * Given an array of desired parameters, assert that each corresponding
 * element of another array has these parameters.
 *
 * @param xs The array to check
 * @param desiredParams The array of desired parameters
 * @param fnt The function to translate from xs into a parameter
 * @param fnu The function to translate from desired into a parameter
 * @param paramType
 */
public func AssertElementsHaveParameters<T, U, V>(
    xs : Array<T>, desiredParams : Array<U>,
    fnt : (T) -> V, fnu : (U) -> V, paramType : ParamType
) : Array<V>
    where
        T <: ToString, U <: ToString,
        V <: ToString & Equatable<V>
{
    let size = AssertSameLength<T,U>(xs, desiredParams)
    Array<V>(size, {
        i : Int64 =>
            let current = xs[i]
            let desired = desiredParams[i]
            let currentParam = fnt(current)
            let desiredParam = fnu(desired)
            if (desiredParam != currentParam) {
                throw IncompatibleParameterException3<T, U, V>(
                    paramType, xs, map(fnt, xs),
                    desiredParams, map(fnu, desiredParams)
                )
            } else {
                currentParam
            }
        }
    )
}
/**
 * Assert that each element in a collection has a parameter.
 *
 * @param xs The collection
 * @param desiredParam
 * @param fn The function to translate from xs into a parameter
 * @param paramType
 */
public func AssertElementsHaveParameter<T, V>(
    xs : Collection<T>, desiredParam : V, fn : (T) -> V,paramType : ParamType
) : Unit where T <: ToString, V <: ToString & Equatable<V> {
    for (x in xs){
        if (fn(x) != desiredParam){
            let desired = mapCollection({ t : T => desiredParam }, xs)
            throw IncompatibleParameterException2<T, V>(
                paramType, xs, mapCollection(fn, xs), desiredParam
            )
        }
    }
}
/**
 * Assert that two objects have the same parameter.
 *
 * @param x
 * @param y
 * @param fnt The function to translate x into a parameter
 * @param fnu The function to transalte y into a parameter
 * @param paramType
 */
public func AssertTwoSameParameter<T, U, V>(
    x : T, y : U, fnt : (T) -> V, fnu : (U) -> V, paramType : ParamType
) : V where T <: ToString, U <: ToString, V <: ToString & Equatable<V> {
    let xParam = fnt(x)
    let yParam = fnu(y)
    if (xParam != yParam) {
        throw IncompatibleParameterException3<T, U, V>(
            paramType, x, xParam, y, yParam
        )
    }
    xParam
}
/**
 * Assert an object has a desired parameter.
 *
 * @param t
 * @param desired
 * @param fn The function to translate from t into a parameter
 * @param paramType
 */
public func AssertHasParameter<T,U>(
    t : T, desired : U, fn : (T) -> U, paramType : ParamType
) : Unit where T <: ToString, U <: ToString & Equatable<U> {
    let param = fn(t)
    if (param != desired) {
        throw IncompatibleParameterException2<T, U>(
            paramType, t, param, desired
        )
    }
}
/**
 * Assert an object as a parameter greater than some target.
 *
 * @param t
 * @param desired
 * @param fn The function to translate from t into a parameter
 * @param paramType
 */
public func AssertHasAtLeastParameter<T, U>(
    t : T, desired : U, fn : (T) -> U, paramType : ParamType
) : Unit where T <: ToString, U <: ToString & Comparable<U> {
    let param = fn(t)
    if (param < desired) {
        throw InsufficientParameterException2<T, U>(
            paramType, t, param, desired
        )
    }
}
/**
 * Assert an element is in a collection.
 *
 * @param t
 * @param collection
 */
public func AssertElementInCollection<T>(
    t : T, xs : Collection<T>
) : Unit where T <: ToString & Equatable<T> {
    for(x in xs) {
        if(x == t){
            return
        }
    }
    throw ElementNotInCollectionException(t, xs)
}