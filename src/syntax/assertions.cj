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
) : Int64 where V <: ValueSymbol, V <: Equatable<V> {
    AssertArrayAllSameParameter<Signal<V>, Int64>(
        vs,
        { v : Signal<V> => v.GetWidth() },
        Width
    )
}

class NonMonotoneFunctionException<T> <: Exception where T <: ToString {
    public init(l : Array<T>, r : Array<T>, f : (Array<T>) -> Array<T>) {
        ErrorMsg("Expected function to be monotone, but f(${l}) = ${f(l)} is not less than f(${r}) = ${f(r)}")
    }
}

func AssertTableMonotone<V>(
    lattice : FiniteLattice<V>,
    arity : Int64,
    table : (Array<V>) -> Array<V>
) : Unit where V <: ValueSymbol & Equatable<V> {
    let inputs = lattice.EnumeratePowers(arity)
    for(input1 in inputs) {
        for(input2 in inputs) {
            if (lattice.LTEPowers(input1, input2)) {
                let result1 = table(input1)
                let result2 = table(input2)
                if(!lattice.LTEPowers(result1, result2)){
                    throw NonMonotoneFunctionException(input1, input2, table)
                }
            }
        }
    }
}