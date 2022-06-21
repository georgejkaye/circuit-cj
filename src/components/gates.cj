package components

import graphs.*
import syntax.*

func OpMToN(label : Label, inputs: Array<WireEnd>, outputs : Array<Int64>) : Array<WireEnd> {
    CheckLabelCompatibility(label, map({ w : WireEnd => w.GetWidth() }, inputs), outputs)
    let edge = Edge(label, WiresToVertices(inputs), outputs)
    map({ v : Vertex => WireEnd(v) }, edge.GetTargets())
}

func OpMToOne(label: Label, inputs : Array<WireEnd>, output : Int64) {
    OpMToN(label, inputs, [output])[0]
}

func OpZeroToOne(label : Label) : WireEnd {
    OpMToOne(label, [], 1)
}
func OpOneToOne(label : Label, a : WireEnd) : WireEnd {
    OpMToOne(label, [a], a.GetWidth())
}
func OpTwoToOne(label : Label, a : WireEnd, b : WireEnd) : WireEnd {
    OpMToOne(label, [a,b], a.GetWidth())
}
func OpThreeToOne(label : Label, a : WireEnd, b : WireEnd, c : WireEnd) : WireEnd {
    OpMToOne(label, [a,b,c], a.GetWidth())
}
func OpThreeToOne(label : Label, a : WireEnd, b : WireEnd, c : WireEnd, width : Int64) : WireEnd {
    OpMToOne(label, [a,b,c], width)
}
public func NotGate(a : WireEnd) : WireEnd {
    OpOneToOne(NOT(2, a.GetWidth()), a)
}
public func AndGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(AND(2, a.GetWidth()), a, b)
}
public func AndGate(w : WireEnd) : WireEnd {
    AndGate([w])
} 
public func AndGate(ws : Array<WireEnd>) : WireEnd {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(AND(ws.size(), ws[0].GetWidth()), ws, width)
}
public func OrGate(w : WireEnd) : WireEnd {
    OrGate([w])
} 
public func OrGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(OR(2, a.GetWidth()), a, b)
}
public func OrGate(ws : Array<WireEnd>) : WireEnd {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(OR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func NandGate(w : WireEnd) : WireEnd {
    NandGate([w])
} 
public func NandGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(NAND(2, a.GetWidth()), a, b)
}
public func NandGate(ws : Array<WireEnd>) : WireEnd {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(NAND(ws.size(), ws[0].GetWidth()), ws, width)
}
public func NorGate(w : WireEnd) : WireEnd {
    NorGate([w])
} 
public func NorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(NOR(2, a.GetWidth()), a, b)
}
public func NorGate(ws : Array<WireEnd>) : WireEnd {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(NOR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func XOrGate(w : WireEnd) : WireEnd {
    XorGate([w])
} 
public func XorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(XOR(2, a.GetWidth()), a, b)
}
public func XorGate(ws : Array<WireEnd>) : WireEnd {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(XOR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func XnorGate(w : WireEnd) : WireEnd {
    XnorGate([w])
} 
public func XnorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(XNOR(2, a.GetWidth()), a, b)
}
public func XnorGate(ws : Array<WireEnd>) : WireEnd {
    AssertNonEmpty(ws)
    let width = ws[0].GetWidth()
    OpMToOne(XNOR(ws.size(), ws[0].GetWidth()), ws, width)
}
public func Signal(v : Value) : WireEnd {
    match(v) {
        case Bottom => BottomSignal()
        case False => FalseSignal()
        case True => TrueSignal()
        case Top => TopSignal()
    }
}
public func BottomSignal() : WireEnd {
    OpZeroToOne(BOTTOM)
}
public func FalseSignal() : WireEnd {
    OpZeroToOne(FALSE)
}
public func TrueSignal() : WireEnd {
    OpZeroToOne(TRUE)
}
public func TopSignal() : WireEnd {
    OpZeroToOne(TOP)
}
public func BlackBox(spec : Specification, inputs: Array<WireEnd>) : Array<WireEnd> {
    OpMToN(BLACKBOX(spec), inputs, spec.GetOutputType())
}

func Mux2_1_1() : InterfacedHypergraph {
    let a = Wire(1)
    let b = Wire(1)
    let sel = Wire(1)
    let z = OrGate(
        AndGate(a, NotGate(sel)),
        AndGate(sel, b)
    )
    MakeCircuit([sel,a,b],[z])
}

func Mux2_1_W(w : Int64) : InterfacedHypergraph {
    let a = Wire(w)
    let b = Wire(w)
    let sel = Wire(1)
    let outputs = ForEachBit(
        [a, b],
        { ws => 
            let e = Edge(
                MUX(2, 1), 
                [ws[0].GetVertex(), ws[1].GetVertex()], 
                [w], 
                Mux2_1_1()
            )
            WireEnd(e.GetTarget(0))
        }
    )
    MakeCircuit([a, b], [outputs])
}

public func Mux2(sel!: WireEnd, low!: WireEnd, high!: WireEnd) : WireEnd {
    AssertWireWidth(sel, 1)
    let width = AssertWiresSameWidth(low, high)
    let edge = Edge(
        MUX(2, width),
        [sel.GetVertex(), low.GetVertex(), high.GetVertex()],
        [width],
        Some(Mux2_1_W(width))
    )
    WireEnd(edge.GetTarget(0))
}