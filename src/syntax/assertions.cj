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

func AssertPortsSameWidth<V>(
    array : Array<Port<V>>
) : Unit where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> {
    AssertArrayAllSameParameter(
        array,
        { p : Port<V> => p.GetWidth() },
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

func AssertTableMonotone<V>(
    lattice : FiniteLattice<V>,
    arity : Int64,
    table : (Array<V>) -> Array<V>
) : Unit where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> & LessOrEqual<V> {
    let inputs = lattice.EnumeratePowers(arity)
    for(input1 in inputs) {
        for(input2 in inputs) {
            if (lattice.LTE(input1, input2)) {
                let result1 = table(input1)
                let result2 = table(input2)
                if(!lattice.LTE(result1, result2)){
                    throw NonMonotoneFunctionException(input1, input2, table)
                }
            }
        }
    }
}

class NonMonotoneFunctionException<T> <: Exception where T <: ToString {
    public init(l : Array<T>, r : Array<T>, f : (Array<T>) -> Array<T>) {
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