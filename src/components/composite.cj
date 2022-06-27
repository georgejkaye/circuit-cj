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
    let (circuit, wires) = MakeSubcircuit(internalInputs, [internalOutputs], inputs: inputs, name: label.GetName())
    wires[0]
}
func RippleGate(gate : (Wire, Wire) -> Wire, inputs: Array<Wire>, label: Label) : Wire {
    let internalInputs = map({ w : Wire => MakeWire(w.GetWidth()) }, inputs)
    let internalOutputs = Ripple(internalInputs, gate)
    let (circuit, wires) = MakeSubcircuit(internalInputs, [internalOutputs], inputs: inputs, name: label.GetName())
    wires[0]
}
func InternalRippleGate(gate : (Wire, Wire) -> Wire, inputs: Wire, label: Label) : Wire {
    let internalInputs = MakeWire(inputs.GetWidth())
    let internalOutputs = InternalRipple(internalInputs, gate)
    let (circuit, wires) = MakeSubcircuit([internalInputs], [internalOutputs], inputs: [inputs], name: label.GetName())
    wires[0]
}

public func Not(a : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => NotGate(ws[0])}, [a], NOT)
}
public func And(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => AndGate(ws[0], ws[1])}, [a, b], AND)
}
public func And(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => AndGate(w, v)}, ws, AND)
}
public func Or(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => OrGate(ws[0], ws[1])}, [a, b], OR)
}
public func Or(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => OrGate(w, v)}, ws, OR)
}
public func Or(w : Wire) : Wire {
    InternalRippleGate({ w : Wire , v : Wire => OrGate(w, v)}, w, OR)
}
public func Xor(a : Wire, b : Wire) : Wire {
    BitwiseGate({ ws : Array<Wire> => XorGate(ws[0], ws[1])}, [a, b], XOR)
}
public func Xor(ws : Array<Wire>) : Wire {
    RippleGate({ w : Wire, v : Wire => XorGate(w, v)}, ws, XOR)
}

func Mux2_1_1(low : Wire, high : Wire, sel : Wire) : (InterfacedHypergraph, Wire) {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let c = MakeWire(1)
    let z = OrGate(
        AndGate(a, NotGate(c)),
        AndGate(c, b)
    )
    let (graph, wires) = MakeSubcircuit([c, a, b], [z], inputs: [sel, low, high], name: "Mux2_1_1")
    (graph, wires[0])
}

func Mux2_1_W(low : Wire, high : Wire, sel : Wire) : (InterfacedHypergraph, Wire) {
    AssertWireWidth(sel, 1)
    let width = AssertWiresSameWidth(low, high)
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
                Mux2_1_1(ws[0], ws[1], c)[0]
            )[0]
        }
    )
    let (graph, wires) = MakeSubcircuit([c, a, b], [outputs], inputs: [sel, low, high], name: "Mux2_1_${width}")
    (graph, wires[0])
}

public func Mux2(sel!: Wire, low!: Wire, high!: Wire) : Wire {
    Mux2_1_W(low, high, sel)[1]
}