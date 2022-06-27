package components

public func BlackBox(spec : Specification, inputs: Array<Wire>) : Array<Wire> {
    MakeEdge(BLACKBOX(spec), inputs, spec.GetOutputType())
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

public func Not(a : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => NotGate(ws[0])}, [a], NOT(a.GetWidth()))
}
public func And(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => AndGate(ws[0], ws[1])}, [a, b], AND(2, a.GetWidth()))
}
public func And(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => AndGate(w, v)}, ws, AND(ws.size(), ws[0].GetWidth()))
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

func Mux2_1_1() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let c = MakeWire(1)
    let z = OrGate(
        AndGate(a, NotGate(c)),
        AndGate(c, b)
    )
    MakeSubcircuit([c, a, b], [z], name: "Mux2_1_1")
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
    MakeSubcircuit([c, a, b], [outputs], name: "Mux2_1_${width}")
}

public func Mux2(sel!: Wire, low!: Wire, high!: Wire) : Wire {
    AssertWiresSameWidth(low, high)
    let width = low.GetWidth()
    let mux2 = Mux2_1_W(width)
    UseSubcircuit(mux2, [sel, low, high])[0]
}