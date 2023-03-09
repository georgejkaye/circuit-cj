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

public func AssertNonNegative(x : Int64) : Unit {
    AssertAtLeast(x, 0)
}
public func AssertStrictlyPositive(x : Int64) : Unit {
    AssertAtLeast(x, 1)
}
public func AssertEnoughBits(current : Int64, desired : Int64) {
    AssertAtLeast(current, desired)
}
func AssertNonEmpty<V, G>(ws : Array<Wire<V, G>>) : Unit
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertNonEmpty(ws, Wires)
}
func AssertSignalArrayNonEmpty<V>(signals : Array<Signal<V>>) : Unit
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    AssertNonEmpty(signals, Signals)
}
func AssertSignalsAllSameWidth<V>(signals : Array<Signal<V>>) : Int64
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    AssertArrayAllSameParameter(signals, { s : Signal<V> => s.GetWidth() }, Width)
}
public func AssertWireWidth<V, G, T>(t : T, i : Int64) : Unit
    where
        T <: ContainsWire<V, G> & ToString,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertObjectHasParameter<T, Int64>(
        t,
        i,
        { t : T => t.GetWidth() },
        Width
    )
}
func AssertWireHasWidthAtLeast<V, G, T>(t : T, i : Int64) : Unit
    where
        T <: ContainsWire<V, G> & ToString,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertHasAtLeastParameter<T, Int64>(
        t,
        i,
        { t : T => t.GetWidth() },
        Width
    )
}
public func AssertWiresSameWidth<T>(ws : Array<T>) : Int64
    where T <: ToString & HasWidth
{
    AssertArrayAllSameParameter<T, Int64>(
        ws,
        { t : T => t.GetWidth() },
        Width
    )
}
public func AssertWiresSameWidth<T,U>(
    t : T,
    u : U
) : Int64
    where
        T <: ToString & HasWidth,
        U <: ToString & HasWidth
{
    AssertTwoSameParameter<T,U,Int64>(
        t,
        u,
        { t : T => t.GetWidth() },
        { u : U => u.GetWidth() },
        Width
    )
}
func AssertWireArraysCompatible<V, G>(
    ws : Array<Wire<V, G>>, vs : Array<Wire<V, G>>
) : Array<Int64>
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertArraysSameLength(ws, vs)
    Array<Int64>(ws.size) {
        i : Int64 =>
            AssertWiresSameWidth(ws[i], vs[i])
    }
}
func AssertWireArrayArraysCompatible<V, G>(
    wss : Array<Array<Wire<V, G>>>
) : Int64
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
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
) : Unit
    where
        T <: ToString & HasWidth,
        U <: ToString & HasWidth
{
    AssertArrayElementsHaveParameters<T,U,Int64>(
        ws,
        ns,
        { t : T => t.GetWidth() },
        { u : U => u.GetWidth() },
        Width
    )
}
func AssertAllWiresWidth<T>(ws : Array<T>, n: Int64) : Unit
    where T <: ToString & HasWidth {
    AssertArrayElementsHaveParameter<T,Int64>(
        ws,
        n,
        { t : T => t.GetWidth() },
        Width
    )
}
public func AssertNumberOfWires<T, V, G>(ws : Array<T>, n : Int64) : Unit
    where
        T <: ContainsWire<V, G> & ToString,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertArrayHasLength<T>(ws, n)
}
func AssertMinNumberOfWires<T, V, G>(
    ws : Array<T>,
    n : Int64
) : Unit
    where
        T <: ContainsWire<V, G> & ToString,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertArrayHasMinimumLength<T>(ws, n)
}
func AssertCircuitInputs<V, G>(c : InterfacedHypergraph<V, G>, n : Int64) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertHasParameter(
        c,
        n,
        { c : InterfacedHypergraph<V, G> => c.GetArity() },
        Inputs
    )
}
func AssertCircuitOutputs<V, G>(c : InterfacedHypergraph<V, G>, n : Int64) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertHasParameter<InterfacedHypergraph<V, G>, Int64>(
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
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
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