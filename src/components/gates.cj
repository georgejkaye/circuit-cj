package components

import graphs.*
import syntax.*

func OpMToN(label : Label, inputs: Array<Wire>, outputs : Array<Int64>) : Array<Wire> {
    CheckLabelCompatibility(label, map({ w : Wire => w.GetWidth() }, inputs), outputs)
    let edge = Edge(label, WiresToVertices(inputs), outputs)
    map({ v : Vertex => Wire(v) }, edge.GetTargets())
}

func OpMToOne(label: Label, inputs : Array<Wire>, output : Int64) {
    OpMToN(label, inputs, [output])[0]
}

func OpZeroToOne(label : Label) : Wire {
    OpMToOne(label, [], 1)
}
func OpOneToOne(label : Label, a : Wire) : Wire {
    OpMToOne(label, [a], a.GetWidth())
}
func OpTwoToOne(label : Label, a : Wire, b : Wire) : Wire {
    OpMToOne(label, [a,b], a.GetWidth())
}
func OpThreeToOne(label : Label, a : Wire, b : Wire, c : Wire) : Wire {
    OpMToOne(label, [a,b,c], a.GetWidth())
}
func OpThreeToOne(label : Label, a : Wire, b : Wire, c : Wire, width : Int64) : Wire {
    OpMToOne(label, [a,b,c], width)
}
public func NotGate(a : Wire) : Wire {
    OpOneToOne(NOT(2, a.GetWidth()), a)
}
public func AndGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(AND(2, a.GetWidth()), a, b)
}
public func AndGate(w : Wire) : Wire {
    AndGate([w])
} 
public func AndGate(ws : Array<Wire>) : Wire {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(AND(ws.size(), ws[0].GetWidth()), ws, width)
}
public func OrGate(w : Wire) : Wire {
    OrGate([w])
} 
public func OrGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(OR(2, a.GetWidth()), a, b)
}
public func OrGate(ws : Array<Wire>) : Wire {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(OR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func NandGate(w : Wire) : Wire {
    NandGate([w])
} 
public func NandGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(NAND(2, a.GetWidth()), a, b)
}
public func NandGate(ws : Array<Wire>) : Wire {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(NAND(ws.size(), ws[0].GetWidth()), ws, width)
}
public func NorGate(w : Wire) : Wire {
    NorGate([w])
} 
public func NorGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(NOR(2, a.GetWidth()), a, b)
}
public func NorGate(ws : Array<Wire>) : Wire {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(NOR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func XOrGate(w : Wire) : Wire {
    XorGate([w])
} 
public func XorGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(XOR(2, a.GetWidth()), a, b)
}
public func XorGate(ws : Array<Wire>) : Wire {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(XOR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func XnorGate(w : Wire) : Wire {
    XnorGate([w])
} 
public func XnorGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(XNOR(2, a.GetWidth()), a, b)
}
public func XnorGate(ws : Array<Wire>) : Wire {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(XNOR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func Signal(v : Value) : Wire {
    match(v) {
        case Bottom => BottomSignal()
        case False => FalseSignal()
        case True => TrueSignal()
        case Top => TopSignal()
    }
}
public func BottomSignal() : Wire {
    OpZeroToOne(BOTTOM)
}
public func FalseSignal() : Wire {
    OpZeroToOne(FALSE)
}
public func TrueSignal() : Wire {
    OpZeroToOne(TRUE)
}
public func TopSignal() : Wire {
    OpZeroToOne(TOP)
}
public func BlackBox(spec : Specification, inputs: Array<Wire>) : Array<Wire> {
    OpMToN(BLACKBOX(spec), inputs, spec.GetOutputType())
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
    let outputs = ForEachBit(
        [a, b],
        { ws => 
            let e = Edge(
                MUX(1, 1), 
                [c.GetVertex(), ws[0].GetVertex(), ws[1].GetVertex()], 
                [1], 
                Mux2_1_1(ws[0], ws[1], c)[0]
            )
            Wire(e.GetTarget(0))
        }
    )
    let (graph, wires) = MakeSubcircuit([c, a, b], [outputs], inputs: [sel, low, high], name: "Mux2_1_${width}")
    (graph, wires[0])
}

public func Mux2(sel!: Wire, low!: Wire, high!: Wire) : Wire {
    Mux2_1_W(low, high, sel)[1]
}