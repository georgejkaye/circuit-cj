package components

import debug.*
import assertions.*
import graphs.*

class TodoException <: Exception {
    public init(msg : String){
        TodoMessage(msg)
    }
}

public func Todo(msg : String){
    throw TodoException(msg)
}

public func AssertNonNegative(x : Int64) {
    AssertAtLeast(x, 0)
}
func AssertStrictlyPositive(x : Int64) {
    AssertAtLeast(x, 1)
}
public func AssertEnoughBits(current : Int64, desired : Int64) {
    AssertAtLeast(current, desired)
}
func AssertWireHasNoInEdge<V, G>(w : Wire<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertVertexHasNoInEdge(w.GetVertex())
}
func AssertWireArrayNonEmpty<V, G>(ws : Array<Wire<V, G>>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertNonEmpty(ws, "wires")
}
public func AssertWireWidth<V, G, T>(t : T, i : Int64) : Unit
    where T <: ContainsWire<V, G>, T <: ToString,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertObjectHasParameter<T, Int64>(
        t,
        i,
        { t : T => t.GetWidth() },
        Width
    )
}
func AssertWireHasWidthAtLeast<V, G, T>(t : T, i : Int64) : Unit
    where T <: ContainsWire<V, G>, T <: ToString,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertHasAtLeastParameter<T, Int64>(
        t,
        i,
        { t : T => t.GetWidth() },
        Width
    )
}
public func AssertWiresSameWidth<T>(ws : Array<T>) : Int64 where T <: ToString, T <: HasWidth {
    AssertArrayAllSameParameter<T, Int64>(
        ws,
        { t : T => t.GetWidth() },
        Width
    )
}
public func AssertWiresSameWidth<T,U>(
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
func AssertWireArraysCompatible<V, G>(ws : Array<Wire<V, G>>, vs : Array<Wire<V, G>>) : Array<Int64>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArraysSameLength(ws, vs)
    Array<Int64>(ws.size) {
        i : Int64 =>
            AssertWiresSameWidth(ws[i], vs[i])
    }
}
func AssertWireArrayArraysCompatible<V, G>(wss : Array<Array<Wire<V, G>>>) : Int64
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    if(wss.size > 0) {
        let size = AssertArraysSameLength(wss)
        for(i in 0..size){
            AssertWiresSameWidth(Array<Wire<V, G>>(wss.size){ j : Int64 => wss[j][i] })
        }
        size
    } else {
        0
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
public func AssertNumberOfWires<T, V, G>(ws : Array<T>, n : Int64) : Unit
    where T <: ContainsWire<V, G>, T <: ToString,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayHasLength<T>(ws, n)
}
func AssertMinNumberOfWires<T, V, G>(
    ws : Array<T>,
    n : Int64
) : Unit
    where T <: ContainsWire<V, G>, T <: ToString,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayHasMinimumLength<T>(ws, n)
}
func AssertCircuitInputs<V, G>(c : InterfacedHypergraph<V, G>, n : Int64) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertHasParameter(
        c,
        n,
        { c : InterfacedHypergraph<V, G> => c.GetArity() },
        Inputs
    )
}
func AssertCircuitOutputs<V, G>(c : InterfacedHypergraph<V, G>, n : Int64) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertHasParameter(
        c,
        n,
        { c : InterfacedHypergraph<V, G> => c.GetCoarity() },
        Outputs
    )
}
func AssertArgumentsCompatible<V, G>(
    f : InterfacedHypergraph<V, G>,
    args : Array<InterfacedHypergraph<V, G>>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArrayElementsHaveParameters(
        args,
        f.GetInputs(),
        { ih : InterfacedHypergraph<V, G> =>
            AssertArrayHasLength(ih.GetOutputs(), 1)
            ih.GetOutput(0).GetWidth()
        },
        { iv : InterfaceVertex<V, G> => iv.GetWidth() },
        Width
    )
}