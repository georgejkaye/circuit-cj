/**
 * utils/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
from std import collection.HashSet
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
class IncompatibleParameterException <: Exception {
    public init(message : String) {
        ErrorMsg(message)
    }
}
class UnreachableCodeException <: Exception {
    public init() {
        ErrorMsg("This code should be unreachable")
    }
}
/**
 * Format a string about a failed assertion.
 *
 * @param msg
 * @return the assertion string
 */
func AssertionFailedMessage(msg : String) : String {
    "Assertion failed: ${msg}"
}
/**
 * @param t
 * @param u
 */
public func AssertEqual<T, U>(t : T, u : U) : Unit
    where
        T <: Equatable<U> & ToString,
        U <: ToString
{
    if (t != u) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${t} must be equal to ${u}"
            )
        )
    }
}
/**
 * @param t
 * @param u
 */
public func AssertNotEqual<T, U>(t : T, u : U) : Unit
    where
        T <: Equatable<U> & ToString,
        U <: ToString
{
    if (t == u) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${t} must not be equal to ${u}"
            )
        )
    }
}
/**
 * @param x
 * @param y
 */
public func AssertGreaterThanOrEqualTo(x : Int64, y : Int64) : Unit {
    if(x < y) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("${x} must be greater than or equal to ${y}")
        )
    }
}
/**
 * @param x
 * @param y
 */
public func AssertGreaterThan(x : Int64, y : Int64) : Unit {
    if(x <= y) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("${x} must be greater than ${y}")
        )
    }
}
/**
 * @param x
 * @param y
 */
public func AssertLessThanOrEqualTo(x : Int64, y : Int64) : Unit {
    if(x > y) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("${x} must be less than or equal to ${y}")
        )
    }
}
/**
 * @param x The number to check
 * @param t The target number
 */
public func AssertLessThan(x : Int64, t : Int64) : Unit {
    if(x >= t) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("${x} must be less than ${t}")
        )
    }
}
/**
 * @param x
 * @param start
 * @param end
 */
public func AssertInRange(x : Int64, start : Int64, end : Int64) : Unit {
    if(x < start || x >= end) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("${x} must be in range ${start}..${end}")
        )
    }
}
/**
 * @param x
 */
public func AssertNonNegative(x : Int64) : Unit {
    AssertGreaterThanOrEqualTo(x, 0)
}
/**
 * @param x
 */
public func AssertStrictlyPositive(x : Int64) : Unit {
    AssertGreaterThanOrEqualTo(x, 1)
}
/**
 * @param x
 * @param multiple
 * @return The multiple
 */
public func AssertMultipleOf(x : Int64, multiple : Int64) : Int64 {
    if(x % multiple != 0) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${x} must be multiple of ${multiple}"
            )
        )
    }
    x / multiple
}
/**
 * @param opt
 */
public func AssertIsNone<T>(opt : Option<T>) : Unit
    where T <: ToString
{
    match (opt) {
        case None => ()
        case Some(t) =>
            throw IncompatibleParameterException(
                AssertionFailedMessage("${opt} must be None")
            )
    }
}
/**
 * @param opt
 */
public func AssertIsNotNone<T>(opt : Option<T>) : T
    where T <: ToString
{
    match (opt) {
        case None =>
            throw IncompatibleParameterException(
                AssertionFailedMessage("${opt} must not be None")
            )
        case Some(t) => t
    }
}
/**
 * @param xs
 */
public func AssertNonEmpty<T>(xs : Collection<T>) : Unit {
    if(xs.size == 0) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("Collection must be non-empty")
        )
    }
}
/**
 * Assert that a collection of collections is non-empty and each of its elements
 * is also non-empty.
 *
 * @param xss
 */
public func AssertElementsNonEmpty<T>(xss : Collection<Collection<T>>) : Unit {
    AssertNonEmpty(xss)
    for(xs in xss) {
        AssertNonEmpty(xs)
    }
}
/**
 * @param xs
 */
public func AssertEmpty<T>(xs : Collection<T>) : Unit where T <: ToString {
    if(xs.size != 0) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "Collection ${collectionToString(xs)} must be empty"
            )
        )
    }
}
/**
 * @param xs
 * @param length
 */
public func AssertHasLength<T>(xs : Collection<T>, length : Int64) : Unit
    where T <: ToString
{
    if(xs.size != length) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${collectionToString<T>(xs)} must have length ${length}"
            )
        )
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
) : Int64 where T <: ToString, U <: ToString {
    if(xs.size != ys.size) {
        throw IncompatibleParameterException(
            AssertionFailedMessage("Collections must have the same size")
        )
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
    xss : Collection<Array<T>>, start!: Int64 = 0, end!: Int64 = xss.size,
    excluding!: HashSet<Int64> = HashSet()
) : Int64 where T <: ToString {
    AssertCollectionHasSameParameter<Array<T>, Int64>(
        xss, { ts : Array<T> => ts.size }, Width, start: start, end: end,
        excluding: excluding
    )
}
/**
 * @param xs
 * @param minimum
 */
public func AssertMinimumLength<T>(xs : Collection<T>, minimum : Int64) : Unit
    where T <: ToString
{
    if (xs.size < minimum) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "Collection ${collectionToString(xs)} " +
                "must have minimum length ${minimum} (it has length ${xs.size})"
            )
        )
    }
}
/**
 * @param xs
 * @param multiple
 * @return The multiple
 */
public func AssertLengthMultipleOf<T>(
    xs : Collection<T>, multiple : Int64
) : Int64 where T <: ToString {
    if (xs.size % multiple != 0) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "Collection length must be multiple of ${multiple} " +
                "(it has length ${xs.size})")
        )
    }
    xs.size / multiple
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
    xs : Collection<T>, fn : (T) -> U, paramType : ParamType,
    start!: Int64 = 0, end!: Int64 = xs.size,
    excluding!: HashSet<Int64> = HashSet()
) : U where T <: ToString, U <: ToString & Equatable<U> {
    AssertNonEmpty(xs)
    AssertNotEqual(xs.size, excluding.size)
    AssertGreaterThanOrEqualTo(start, 0)
    AssertLessThanOrEqualTo(end, xs.size)
    AssertLessThan(start, end)
    let iterator = xs.iterator()
    var targetParamOpt = None<U>
    for(i in 0..start) {
        iterator.next()
    }
    for(i in start..end) {
        if(!excluding.contains(i)) {
            let current = iterator.next().getOrThrow()
            let targetParam = match(targetParamOpt) {
                case Some(p) => p
                case None =>
                    let currentParam = fn(current)
                    targetParamOpt = Some(currentParam)
                    currentParam
            }
            let currentParam = fn(current)
            if (targetParam != currentParam) {
                throw IncompatibleParameterException(
                    AssertionFailedMessage(
                        "Collection elements must all have ${paramType} " +
                        "${targetParam} (they have ${paramType} " +
                        "${mapCollection<T, U>(fn, xs)})"
                    )
                )
            }
        } else {
            iterator.next()
        }
    }
    targetParamOpt.getOrThrow()
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
                throw IncompatibleParameterException(
                    AssertionFailedMessage(
                        "Collection elements must have ${paramType} " +
                        "${map(fnu, desiredParams)} (they have ${paramType} " +
                        "${map(fnt, xs)})"
                    )
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
    xs : Collection<T>, desiredParam : V, fn : (T) -> V, paramType : ParamType
) : Unit where T <: ToString, V <: ToString & Equatable<V> {
    for (x in xs){
        if (fn(x) != desiredParam){
            let desired = mapCollection({ t : T => desiredParam }, xs)
            throw IncompatibleParameterException(
                AssertionFailedMessage(
                    "Collection elements must have ${paramType} " +
                    "${desiredParam} (they have ${mapCollection(fn, xs)})"
                )
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
public func AssertBothSameParameter<T, U, V>(
    x : T, y : U, fnt : (T) -> V, fnu : (U) -> V, paramType : ParamType
) : V where T <: ToString, U <: ToString, V <: ToString & Equatable<V> {
    let xParam = fnt(x)
    let yParam = fnu(y)
    if (xParam != yParam) {
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${x} and ${y} must have ${paramType} ${paramType}" +
                "(they have ${fnt(x)} and ${fnu(y)} respectively)"
            )
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
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${t} must have ${paramType} ${desired}" +
                "(it has ${param})"
            )
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
        throw IncompatibleParameterException(
            AssertionFailedMessage(
                "${t} must have ${paramType} at least ${desired}" +
                "(it has ${param})"
            )
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
    throw IncompatibleParameterException(
        AssertionFailedMessage(
            "${t} must be in ${collectionToString(xs)}"
        )
    )
}
public func AssertUnreachable() : Unit {
    throw UnreachableCodeException()
}
public class IncompatibleVariantException<T> <: Exception where T <: ToString {
    public init(t : T, desired : String) {
        AssertionFailedMessage(
            "${t} must be variant ${desired}"
        )
    }
}