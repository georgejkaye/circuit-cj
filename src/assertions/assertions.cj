/**
 * assertions/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package assertions

import utils.map

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
public func AssertEqual<T, U>(t : T, u : U) : Unit where T <: Equatable<U> & ToString, U <: ToString {
    if (t != u) {
        throw IncompatibleParameterException2<T, U>(t, u)
    }
}
public func AssertAtLeast(i : Int64, t : Int64) : Unit {
    if(i < t) {
        throw InsufficientParameterException(i, t)
    }
}
public func AssertNonEmpty<T>(collection : Collection<T>, contents : ParamType) : Unit {
    if(collection.size == 0) {
        throw EmptyException(contents)
    }
}
public func AssertArrayArraysNonEmpty<T>(xss : Array<Array<T>>, contents : ParamType) : Unit {
    AssertNonEmpty(xss, contents)
    for(xs in xss) {
        AssertNonEmpty(xs, contents)
    }
}
public func AssertEmpty<T>(collection : Collection<T>, contents : ParamType) : Unit {
    if(collection.size != 0) {
        throw NonEmptyException(contents)
    }
}
public func AssertIsNone<T>(
    opt : Option<T>,
    paramType: ParamType
) : Unit where T <: ToString{
    match (opt) {
        case None => ()
        case Some(t) =>
            throw IncompatibleParameterException2(
                paramType,
                opt,
                t,
                None<T>
            )
    }
}
public func AssertIsNotNone<T>(
    opt : Option<T>,
    paramType : ParamType
) : T where T <: ToString{
    match (opt) {
        case None => throw IncompatibleParameterException(
            paramType,
            opt
        )
        case Some(t) => return t
    }
}
public func AssertArraysSameLength<T, U>(
    xs : Array<T>,
    ys : Array<U>
) : Unit where T <: ToString {
    if(xs.size != ys.size) {
        throw IncompatibleLengthException<T>(xs, ys.size, true)
    }
}
public func AssertArraysSameLength<T>(
    xss : Array<Array<T>>
) : Int64 where T <: ToString {
    if(xss.size > 0) {
        let size = xss[0].size
        for(i in 1..xss.size) {
            AssertArrayHasLength(xss[i], size)
        }
        size
    } else {
        0
    }
}
public func AssertArrayHasLength<T>(
    xs : Array<T>,
    n : Int64
) : Unit where T <: ToString {
    if(xs.size != n) {
        throw IncompatibleLengthException<T>(xs, n, true)
    }
}
public func AssertArrayHasMinimumLength<T>(
    xs : Array<T>,
    n : Int64
) : Unit where T <: ToString {
    if (xs.size < n) {
        throw IncompatibleLengthException<T>(xs, n, false)
    }
}
public func AssertObjectHasParameter<T, U>(
    t : T,
    u : U,
    fn : (T) -> U,
    paramType: ParamType
) : Unit where T <: ToString, U <: ToString & Equatable<U> {
    let currentParam = fn(t)
    if (currentParam != u) {
        throw IncompatibleParameterException2<T,U>(
            paramType,
            t,
            u,
            currentParam
        )
    }
}
public func AssertArrayAllSameParameter<T, U>(
    xs : Array<T>,
    fn : (T) -> U,
    paramType : ParamType
) : U where T <: ToString, U <: ToString & Equatable<U> {
    AssertNonEmpty(xs, paramType)
    let targetParam = fn(xs[0])
    for(i in 1..xs.size) {
        let current = xs[i]
        let currentParam = fn(current)
        if (targetParam != currentParam) {
            throw IncompatibleParameterException2<T, U>(
                paramType,
                current,
                currentParam,
                targetParam
            )
        }
    }
    targetParam
}
public func AssertArrayElementsHaveParameters<T, U, V>(
    xs : Array<T>,
    desiredParams : Array<U>,
    fnt : (T) -> V,
    fnu : (U) -> V,
    paramType : ParamType
) : Unit where T <: ToString, U <: ToString, V <: ToString & Equatable<V> {
    AssertArraysSameLength<T,U>(xs, desiredParams)
    for(i in 0..xs.size) {
        let current = xs[i]
        let desired = desiredParams[i]
        let currentParam = fnt(current)
        let desiredParam = fnu(desired)
        if (desiredParam != currentParam) {
            throw IncompatibleParameterException3<T, U, V>(
                paramType,
                xs,
                map(fnt, xs),
                desiredParams,
                map(fnu, desiredParams)
            )
        }
    }
}
public func AssertArrayElementsHaveParameter<T, V>(
    xs : Array<T>,
    desiredParam : V,
    fn : (T) -> V,
    paramType : ParamType
) : Unit where T <: ToString, V <: ToString & Equatable<V> {
    for (x in xs){
        if (fn(x) != desiredParam){
            let desired = map({ t : T => desiredParam }, xs)
            throw IncompatibleParameterException2<T, V>(
                paramType,
                xs,
                map(fn, xs),
                desiredParam
            )
        }
    }
}
public func AssertTwoSameParameter<T, U, V>(
    x : T,
    y : U,
    fnt : (T) -> V,
    fnu : (U) -> V,
    paramType : ParamType
) : V where T <: ToString, U <: ToString, V <: ToString & Equatable<V> {
    let xParam = fnt(x)
    let yParam = fnu(y)
    if (xParam != yParam) {
        throw IncompatibleParameterException3<T, U, V>(
            paramType,
            x,
            xParam,
            y,
            yParam
        )
    }
    xParam
}
public func AssertHasParameter<T,U>(
    t : T,
    desired : U,
    fn : (T) -> U,
    paramType : ParamType
) : Unit where T <: ToString, U <: ToString & Equatable<U> {
    let param = fn(t)
    if (param != desired) {
        throw IncompatibleParameterException2<T, U>(
            paramType,
            t,
            param,
            desired
        )
    }
}
public func AssertHasAtLeastParameter<T, U>(
    t : T,
    desired : U,
    fn : (T) -> U,
    paramType : ParamType
) : Unit where T <: ToString, U <: ToString & Comparable<U> {
    let param = fn(t)
    if (param < desired) {
        throw InsufficientParameterException2<T, U>(
            paramType,
            t,
            param,
            desired
        )
    }
}
public func AssertElementInCollection<T>(
    t : T,
    collection : Collection<T>
) : Unit where T <: ToString & Equatable<T> {
    for(x in collection) {
        if(x == t){
            return
        }
    }
    throw ElementNotInCollectionException(t, collection)
}
public func AssertCollectionHasLengthAtLeast<T>(
    collection : Collection<T>,
    len : Int64
) where T <: ToString {
    if (collection.size < len) {
        throw IncompatibleLengthException(collection, len, false)
    }
}