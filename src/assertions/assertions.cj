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
}
extend ParamType <: ToString {
    public func toString() : String {
        match(this) {
            case Width => "width"
            case InEdge => "in edges"
            case Owner => "owner"
        }
    }
}
public func AssertNonEmpty<T>(array : Array<T>) : Unit {
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
            throw IncompatibleParameterException(
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
public func AssertArraysSameLength<T,U>(
    xs : Array<T>,
    ys : Array<U>
) : Unit where U <: ToString {
    if(xs.size() != ys.size()) {
        throw IncompatibleArrayLengthException<U>(ys, xs.size(), true)
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
public func AssertObjectHasParameter<T,U>(
    t : T,
    u : U,
    fn : (T) -> U,
    paramType: ParamType
) : Unit where T <: ToString, U <: ToString, U <: Equatable<U> {
    let currentParam = fn(t)
    if (currentParam != u) {
        throw IncompatibleParameterException<U,T,U>(
            paramType,
            u,
            t,
            currentParam
        )
    }
}
public func AssertArrayAllSameParameter<T,U>(
    xs : Array<T>,
    fn : (T) -> U,
    paramType : ParamType
) : U where T <: ToString, U <: ToString, U <: Equatable<U> {
    AssertNonEmpty(xs)
    let targetParam = fn(xs[0])
    for(i in 1..xs.size()) {
        let current = xs[i]
        let currentParam = fn(current)
        if (targetParam != currentParam) {
            throw IncompatibleParameterException<U,T,U>(
                paramType,
                targetParam,
                current,
                currentParam
            )
        } 
    }
    targetParam
}

public func AssertArrayElementsHaveParameters<T,U,V>(
    xs : Array<T>,
    desiredParams : Array<U>,
    fnt : (T) -> V,
    fnu : (U) -> V,
    paramType : ParamType
) : Unit where T <: ToString, U <: ToString, V <: ToString, V <: Equatable<V> {
    AssertArraysSameLength(xs, desiredParams)
    for(i in 0..xs.size()) {
        let current = xs[i]
        let desired = desiredParams[i]
        let currentParam = fnt(current)
        let desiredParam = fnu(desired)
        if (desiredParam != currentParam) {
            throw IncompatibleParameterException<U,T,V>(
                paramType,
                desiredParams,
                map(fnu, desiredParams),
                xs,
                map(fnt, xs)
            )
        }
    }
}
public func AssertArrayElementsHaveParameter<T,U>(
    xs : Array<T>,
    desiredParam : U,
    fn : (T) -> U,
    paramType : ParamType
) : Unit where T <: ToString, U <: ToString, U <: Equatable<U> {
    for (x in xs){
        if (fn(x) != desiredParam){
            let desired = map({ t : T => desiredParam }, xs)
            throw IncompatibleParameterException<U,T,U>(
                paramType,
                desired,
                desired,
                xs,
                map(fn, xs)
            )
        }
    }
}
public func AssertTwoSameParameter<T,U,V>(
    x : T,
    y : U,
    fnt : (T) -> V,
    fnu : (U) -> V,
    paramType : ParamType
) : V where T <: ToString, U <: ToString, V <: ToString, V <: Equatable<V> {
    let xParam = fnt(x)
    let yParam = fnu(y)
    if (xParam != yParam) {
        throw IncompatibleParameterException<T,U,V>(
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
        throw IncompatibleParameterException<U,T,U>(
            paramType,
            desired,
            t,
            param
        )
    }
}