package components

import graphs.*

func OpMToN(label : Label, inputs: Array<WireEnd>, outputs : Array<Int64>) : Array<WireEnd> {
    CheckLabelCompatibility(label, map({ w : WireEnd => w.GetVertex().GetWidth() }, inputs), outputs)
    let edge = Edge(label, WiresToVertices(inputs), outputs)
    map({ v : Vertex => WireEnd(v) }, edge.GetTargets())
}

func OpZeroToOne(label : Label) : WireEnd {
    OpMToN(label, [], [1])[0]
}
func OpOneToOne(label : Label, a : WireEnd) : WireEnd {
    OpMToN(label, [a], [1])[0]
}
func OpTwoToOne(label : Label, a : WireEnd, b : WireEnd) : WireEnd {
    OpMToN(label, [a,b], [1])[0]
}

public func NotGate(a : WireEnd) : WireEnd {
    OpOneToOne(NOT, a)
}
public func AndGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(AND, a, b)
}
public func OrGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(OR, a, b)
}
public func NandGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(NAND, a, b)
}
public func NorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(NOR, a, b)
}
public func XorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(XOR, a, b)
}
public func XnorGate(a : WireEnd, b : WireEnd) : WireEnd {
    OpTwoToOne(XNOR, a, b)
}


public func TrueSignal() : WireEnd {
    OpZeroToOne(TRUE)
}

public func FalseSignal() : WireEnd {
    OpZeroToOne(FALSE)
}

public func BlackBox(spec : Specification, inputs: Array<WireEnd>) : Array<WireEnd> {
    OpMToN(BLACKBOX(spec), inputs, spec.GetOutputPorts())
}