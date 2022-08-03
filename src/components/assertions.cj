package components

import debug.*
import assertions.*
import graphs.*

func AssertWireHasNoInEdge(w : Wire) {
    AssertVertexHasNoInEdge(w.GetVertex())
}
func AssertWireArrayNonEmpty(ws : Array<Wire>) : Unit {
    AssertArrayNonEmpty(ws)
}
func AssertWireWidth<T>(t : T, i : Int64) : Unit where T <: ContainsWire, T <: ToString {
    AssertObjectHasParameter<T, Int64>(
        t,
        i,
        { t : T => t.GetWidth() },
        Width
    )
}
func AssertWireHasWidthAtLeast<T>(t : T, i : Int64) : Unit where T <: ContainsWire, T <: ToString {
    AssertHasAtLeastParameter<T, Int64>(
        t,
        i,
        { t : T => t.GetWidth() },
        Width
    )
}
func AssertWiresSameWidth<T>(ws : Array<T>) : Int64 where T <: ToString, T <: HasWidth {
    AssertArrayAllSameParameter<T, Int64>(
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
func AssertNumberOfWires<T>(ws : Array<T>, n : Int64) : Unit where T <: ContainsWire, T <: ToString {
    AssertArrayHasLength<T>(ws, n)
}
func AssertMinNumberOfWires<T>(
    ws : Array<T>,
    n : Int64
) : Unit where T <: ContainsWire, T <: ToString {
    AssertArrayHasMinimumLength<T>(ws, n)
}
func AssertCircuitInputs(c : InterfacedHypergraph, n : Int64) {
    AssertHasParameter(
        c,
        n,
        { c : InterfacedHypergraph => c.GetInputs() },
        Inputs
    )
}
func AssertCircuitOutputs(c : InterfacedHypergraph, n : Int64) {
    AssertHasParameter(
        c,
        n,
        { c : InterfacedHypergraph => c.GetOutputs() },
        Inputs
    )
}