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
    OpOneToOne(NOT(a.GetWidth()), a)
}
public func AndGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(AND(a.GetWidth()), a, b)
}
public func OrGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(OR(a.GetWidth()), a, b)
}
public func NandGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(NAND(a.GetWidth()), a, b)
}
public func NorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(NOR(a.GetWidth()), a, b)
}
public func XorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(XOR(a.GetWidth()), a, b)
}
public func XnorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(XNOR(a.GetWidth()), a, b)
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