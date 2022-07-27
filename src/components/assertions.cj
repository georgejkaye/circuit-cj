package components

import debug.*

enum ParamType {
    Width
}
extend ParamType <: ToString {
    public func toString() : String {
        match(this) {
            case Width => "width"
        }
    }
}

func AssertNonEmpty<T>(array : Array<T>) : Unit {
    if(array.size() == 0) {
        throw EmptyArrayException()
    }
}

func AssertArraysSameLength<T,U>(xs : Array<T>, ys : Array<U>) : Unit {
    if(xs.size() != ys.size()) {
        throw IncompatibleArrayLengthException(xs.size(), ys.size(), true)
    }
}

func AssertArrayHasLength<T>(xs : Array<T>, n : Int64) : Unit {
    if(xs.size() != n) {
        throw IncompatibleArrayLengthException(n, xs.size(), true)
    }
}

func AssertArrayHasMinimumLength<T>(xs : Array<T>, n : Int64) : Unit {
    if (xs.size() < n) {
        throw IncompatibleArrayLengthException(n, xs.size(), false)
    }
}

func AssertObjectHasParameter<T,U>(
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

func AssertArrayAllSameParameter<T,U>(
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

func AssertArrayElementsHaveParameters<T,U,V>(
    xs : Array<T>,
    desiredParams : Array<U>,
    fnt : (T) -> V,
    fnu : (U) -> V,
    paramType : ParamType
) : Unit where T <: ToString, U <: ToString, V <: ToString, V <: Equatable<V> {
    AssertArraysSameLength(xs, desiredParams)
    for(i in 0..xs.size()) {
        let current = xs[i]
        let currentParam = fnt(current)
        let desiredParam = fnu(desiredParams[i])
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
func AssertArrayElementsHaveParameter<T,U>(
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
func AssertTwoSameParameter<T,U,V>(
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

func AssertWireWidth(w : Wire, i : Int64) : Unit {
    AssertObjectHasParameter(
        w,
        i,
        { w : Wire => w.GetWidth() },
        Width
    )
}

func AssertWiresSameWidth<T>(ws : Array<T>) : Int64 where T <: ToString, T <: HasWidth {
    AssertArrayAllSameParameter<T,Int64>(
        ws,
        { t : T => t.GetWidth() },
        Width
    )
}

func AssertWiresSameWidth<T,U>(
    t : T,
    u : U
) : Int64 where T <: ToString, U <: ToString, T <: HasWidth, U <: HasWidth {
    AssertTwoSameParameter<T,U,Int64>(
        t,
        u,
        { t : T => t.GetWidth() },
        { u : U => u.GetWidth() },
        Width
    )
}


func AssertWireArraysCompatible(ws : Array<Wire>, vs : Array<Wire>) : Array<Int64> {
    if (ws.size() != vs.size()) {
        throw DifferentNumberOfWiresException(ws, vs)
    }
    Array<Int64>(ws.size()) {
        i : Int64 =>
            AssertWiresSameWidth(ws[i], vs[i])
    }
}

func AssertWiresHaveWidths<T,U>(
    ws : Array<T>,
    ns: Array<U>
) : Unit where T <: ToString, U <: ToString, T <: HasWidth, U <: HasWidth {
    AssertArrayElementsHaveParameters<T,U,Int64>(
        ws,
        ns,
        { t : T => t.GetWidth() },
        { u : U => u.GetWidth() },
        Width
    )
}

func AssertAllWiresWidth<T>(ws : Array<T>, n: Int64) : Unit where T <: ToString, T <: HasWidth {
    AssertArrayElementsHaveParameter<T,Int64>(
        ws,
        n,
        { t : T => t.GetWidth() },
        Width
    )
}

func AssertNumberOfWires<T>(ws : Array<T>, n : Int64) : Unit where T <: ContainsWire {
    AssertArrayHasLength(ws, n)
}

func AssertMinNumberOfWires<T>(ws : Array<T>, n : Int64) : Unit where T <: ContainsWire {
    AssertArrayHasMinimumLength(ws, n)
}

func AssertCircuitOutputs(c : InterfacedHypergraph, n : Int64) {
    if(c.GetOutputs() != n){
        throw IncompatibleOutputsException(c, n)
    }
}