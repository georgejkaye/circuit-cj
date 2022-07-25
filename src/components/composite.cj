package components

public func BlackBox(
    name : String, 
    domain : Array<Int64>,
    codomain : Array<Int64>,
    inputs: Array<Wire>
) : Array<Wire> {
    MakeEdge(BLACKBOX(Specification(name, domain, codomain)), inputs, codomain)
}

/**
 * Bitwise logic gates
 */

func BitwiseGate(gate : (Array<Wire>) -> Wire, inputs: Array<Wire>, label: Label) : Wire {
    let internalInputs = map({ w : Wire => MakeWire(w.GetWidth()) }, inputs)
    let internalOutputs = Bitwise(internalInputs, gate)
    let circuit = MakeSubcircuit(internalInputs, [internalOutputs], name: label.GetName())
    UseSubcircuit(circuit, inputs)[0]
}
func RippleGate(gate : (Wire, Wire) -> Wire, inputs: Array<Wire>, label: Label) : Wire {
    let internalInputs = map({ w : Wire => MakeWire(w.GetWidth()) }, inputs)
    let internalOutputs = Ripple(internalInputs, gate)
    let circuit = MakeSubcircuit(internalInputs, [internalOutputs], name: label.GetName())
    UseSubcircuit(circuit, inputs)[0]
}
func InternalRippleGate(gate : (Wire, Wire) -> Wire, inputs: Wire, label: Label) : Wire {
    let internalInputs = MakeWire(inputs.GetWidth())
    let internalOutputs = InternalRipple(internalInputs, gate)
    let circuit = MakeSubcircuit([internalInputs], [internalOutputs], name: label.GetName())
    UseSubcircuit(circuit, [inputs])[0]
}

public func Buf(a : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => NotGate(ws[0])}, [a], BUF(a.GetWidth()))
}
public func Not(a : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => NotGate(ws[0])}, [a], NOT(a.GetWidth()))
}
public func And(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => AndGate(ws[0], ws[1])}, [a, b], AND(2, a.GetWidth()))
}
public func And(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => AndGate(w, v)}, ws, AND(ws.size(), ws[0].GetWidth()))
}
public func And(w : Wire) : Wire {
    InternalRippleGate({ w : Wire , v : Wire => AndGate(w, v)}, w, AND(w.GetWidth(), 1))
}
public func Or(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => OrGate(ws[0], ws[1])}, [a, b], OR(2, a.GetWidth()))
}
public func Or(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => OrGate(w, v)}, ws, OR(ws.size(), ws[0].GetWidth()))
}
public func Or(w : Wire) : Wire {
    InternalRippleGate({ w : Wire , v : Wire => OrGate(w, v)}, w, OR(w.GetWidth(), 1))
}
public func Xor(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => XorGate(ws[0], ws[1])}, [a, b], XOR(2, a.GetWidth()))
}
public func Xor(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => XorGate(w, v)}, ws, XOR(ws.size(), ws[0].GetWidth()))
}
public func Nor(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => NorGate(ws[0], ws[1])}, [a, b], NOR(2, a.GetWidth()))
}
public func Nor(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => NorGate(w, v)}, ws, NOR(ws.size(), ws[0].GetWidth()))
}
public func Nor(w : Wire) : Wire {
    InternalRippleGate({ w : Wire , v : Wire => NorGate(w, v)}, w, NOR(w.GetWidth(), 1))
}

func Mux2_1_1() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let c = MakeWire(1)
    let z = OrGate(
        AndGate(a, NotGate(c)),
        AndGate(c, b)
    )
    MakeSubcircuit([a, b, c], [z], name: "mux2_1_1")
}

func Mux2_1_W(width : Int64) : InterfacedHypergraph {
    let a = MakeWire(width)
    let b = MakeWire(width)
    let c = MakeWire(1)
    let outputs = Bitwise(
        [a, b],
        { ws => 
            MakeEdge(
                MUX(2, 1, 1), 
                [c, ws[0], ws[1]], 
                [1], 
                Mux2_1_1()
            )[0]
        }
    )
    MakeSubcircuit([a, b, c], [outputs], name: "mux2_1_${width}")
}

func Mux4_1_W(width: Int64) : InterfacedHypergraph {
    let a  = MakeWire(width)
    let b  = MakeWire(width)
    let c  = MakeWire(width)
    let d  = MakeWire(width)
    let s0 = MakeWire(1)
    let s1 = MakeWire(1)
    let m1 = UseSubcircuit_1(Mux2_1_W(width), [a,b,s0])
    let m2 = UseSubcircuit_1(Mux2_1_W(width), [c,d,s0])
    let m3 = UseSubcircuit_1(Mux2_1_W(width), [m1,m2,s1])
    MakeSubcircuit([a,b,c,d,s0,s1], [m3], name: "mux4_1_${width}")
}

public func Mux2(a: Wire, b: Wire, sel: Wire) : Wire {
    AssertWiresSameWidth(a, b)
    let width = a.GetWidth()
    let mux2 = Mux2_1_W(width)
    UseSubcircuit_1(mux2, [a, b, sel])
}

public func Mux4(a: Wire, b: Wire, c: Wire, d: Wire, s0: Wire, s1: Wire) : Wire {
    AssertWiresSameWidth(a, b)
    AssertWiresSameWidth(b, c)
    AssertWiresSameWidth(c, d)
    AssertWireWidth(s0, 1)
    AssertWireWidth(s1, 1)
    let width = a.GetWidth()
    UseSubcircuit_1(Mux4_1_W(width), [a, b, c, d, s0, s1])
}