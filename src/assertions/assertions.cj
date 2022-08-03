/**
 * assertions/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package assertions

import prelude.map

public enum ParamType {
    | Width
    | InEdge
    | Owner
    | Inputs
    | Outputs
}
extend ParamType <: ToString {
    public func toString() : String {
        match(this) {
            case Width => "width"
            case InEdge => "in edges"
            case Owner => "owner"
            case Inputs => "inputs"
            case Outputs => "outputs"
        }
    }
}
public func AssertAtLeast(i : Int64, t : Int64) : Unit {
    if(i < t) {
        throw InsufficientParameterException(i, t)
    }
}
public func AssertArrayNonEmpty<T>(array : Array<T>) : Unit {
    if(array.size() == 0) {
        throw EmptyArrayException()
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
                None<T>,
                opt,
                t
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
    if(xs.size() != ys.size()) {
        throw IncompatibleArrayLengthException<T>(xs, ys.size(), true)
    }
}
public func AssertArrayHasLength<T>(
    xs : Array<T>,
    n : Int64
) : Unit where T <: ToString {
    if(xs.size() != n) {
        throw IncompatibleArrayLengthException<T>(xs, n, true)
    }
}
public func AssertArrayHasMinimumLength<T>(
    xs : Array<T>,
    n : Int64
) : Unit where T <: ToString {
    if (xs.size() < n) {
        throw IncompatibleArrayLengthException<T>(xs, n, false)
    }
}
public func AssertObjectHasParameter<T, U>(
    t : T,
    u : U,
    fn : (T) -> U,
    paramType: ParamType
) : Unit where T <: ToString, U <: ToString, U <: Equatable<U> {
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
) : U where T <: ToString, U <: ToString, U <: Equatable<U> {
    AssertArrayNonEmpty(xs)
    let targetParam = fn(xs[0])
    for(i in 1..xs.size()) {
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
) : Unit where T <: ToString, U <: ToString, V <: ToString, V <: Equatable<V> {
    AssertArraysSameLength<T,U>(xs, desiredParams)
    for(i in 0..xs.size()) {
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
) : Unit where T <: ToString, V <: ToString, V <: Equatable<V> {
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
) : V where T <: ToString, U <: ToString, V <: ToString, V <: Equatable<V> {
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
) : Unit where T <: ToString, U <: ToString, U <: Equatable<U> {
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
) : Unit where T <: ToString, U <: ToString, U <: Comparable<U> {
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