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
public func ForEachBit(ws : Array<WireEnd>, gate : (Array<WireEnd>) -> Array<WireEnd>) {
    if (ws.size() == 0) {
        return Array<WireEnd>()
    }
    let inputs = ws.size()
    let width = ws[0].GetWidth()
    for (w in ws){
        if (width != w.GetWidth()){
            throw WiresNotAllSameWidthException("ForEachBit", width, w)
        }
    }
    let splitOutputs = Array<Array<WireEnd>>(inputs) {
        i : Int64 => Split(ws[i], Array<Int64>(width){ j : Int64 => 1 })
    }
    let gateOutputs = Array<Array<WireEnd>>(width) {
        i : Int64 =>
            let currentInputs = 
                Array<WireEnd>(splitOutputs.size()){j : Int64 => splitOutputs[j][i]}
            gate(currentInputs)
    }
    Array<WireEnd>(gateOutputs[0].size()) {
        i : Int64 =>
             let currentOutputs = Array<WireEnd>(gateOutputs.size()){
                j : Int64 => gateOutputs[j][i]
            }
            Combine(currentOutputs)
    }
}
public func ForEachBitMToOne(ws : Array<WireEnd>, gate : (Array<WireEnd>) -> WireEnd) : WireEnd {
    ForEachBit(ws, { ws : Array<WireEnd> => [gate(ws)] })[0]
}
public func ForEachBitOneToOne(a : WireEnd, gate : (WireEnd) -> WireEnd) : WireEnd {
    ForEachBitMToOne([a], { ws : Array<WireEnd> => gate(ws[0]) })
}
public func ForEachBitTwoToOne(a : WireEnd, b : WireEnd, gate : (WireEnd, WireEnd) -> WireEnd) : WireEnd {
    ForEachBitMToOne([a, b], { ws : Array<WireEnd> => gate(ws[0], ws[1]) })
}


public func ForEachBitOpOneToOne(label: Label, a : WireEnd) : WireEnd {
    ForEachBitOneToOne(a, {w : WireEnd => OpOneToOne(label, w)})
}
public func ForEachBitOpTwoToOne(label: Label, a : WireEnd, b : WireEnd) : WireEnd {
    ForEachBitTwoToOne(a, b, {w : WireEnd, v : WireEnd => OpTwoToOne(label, w, v)})
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
public func Mux(sel!: WireEnd, high!: WireEnd, low!: WireEnd) : WireEnd {
    OpThreeToOne(MUX(high.GetWidth()), sel, low, high, high.GetWidth())
}