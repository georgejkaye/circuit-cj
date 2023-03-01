/**
 * syntax/assertions,cj
 *
 * Assertions for the syntax package
 *
 * @author George Kaye
 * @since 0.3
 */

package syntax

func AssertSignalsSameWidth<V>(
    vs : Array<Signal<V>>
) : Int64 where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> {
    AssertArrayAllSameParameter<Signal<V>, Int64>(
        vs,
        { v : Signal<V> => v.GetWidth() },
        Width
    )
}

func AssertPortsSameWidth(
    array : Array<Port>
) : Unit {
    AssertArrayAllSameParameter(
        array,
        { p : Port => p.GetWidth() },
        Width
    )
}

class CannotRipplePrimitiveException<V, G> <: Exception
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    public init(primitive : G) {
        ErrorMsg(
            "Cannot ripple over primitive ${primitive} as its type is" +
            "${primitive.GetInputPorts()} -> ${primitive.GetOutputPorts()}" +
            "wheras rippling requires type [m, m] -> [m]"
        )
    }
}

class CannotBitwiseMapPrimitiveException<V, G> <: Exception
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    public init(primitive : G) {
        ErrorMsg(
            "Cannot bitwise map over primitive ${primitive} as its type is" +
            "${primitive.GetInputPorts()} -> ${primitive.GetOutputPorts()}" +
            "wheras rippling requires type [m, ..., m] -> [n, ..., n]"
        )
    }
}

class NonMonotoneFunctionException<T> <: Exception where T <: ToString {
    public init(l : Array<Array<T>>, r : Array<Array<T>>, f : (Array<Array<T>>) -> Array<Array<T>>) {
        ErrorMsg("Found an issue with ${l} and ${r}")
        ErrorMsg("Expected function to be monotone, but f(${l}) = ${f(l)} is not less than f(${r}) = ${f(r)}")
    }
}

class IncompleteLatticeException<V> <: Exception
    where V <: ToString
{
    public init(lhs : V, rhs : V, op : String) {
        ErrorMsg("Attempted to define complete lattice but ${lhs} ${op} ${rhs} does not exist")
    }
}