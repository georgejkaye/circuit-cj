package components

import graphs.*

func OpMToN(label : Label, inputs: Array<Wire>, outputs : Array<Int64>) : Array<Wire> {
    CheckLabelCompatibility(label, map({ w : Wire => w.GetVertex().GetWidth() }, inputs), outputs)
    let edge = Edge(label, inputs, outputs)
    map({ v : Vertex => Wire(v) }, edge.GetTargets())
}

func OpZeroToOne(label : Label) : Wire {
    OpMToN(label, [], [1])[0]
}
func OpOneToOne(label : Label, a : Wire) : Wire {
    OpMToN(label, [a], [1])[0]
}
func OpTwoToOne(label : Label, a : Wire, b : Wire) : Wire {
    OpMToN(label, [a,b], [1])[0]
}

public func NotGate(a : Wire) : Wire {
    OpOneToOne(NOT, a)
}
public func AndGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(AND, a, b)
}
public func OrGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(OR, a, b)
}
public func NandGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(NAND, a, b)
}
public func NorGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(NOR, a, b)
}
public func XorGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(XOR, a, b)
}
public func XnorGate(a : Wire, b : Wire) : Wire {
    OpTwoToOne(XNOR, a, b)
}


public func TrueSignal() : Wire {
    OpZeroToOne(TRUE)
}

public func FalseSignal() : Wire {
    OpZeroToOne(FALSE)
}

public func BlackBox(spec : Specification, inputs: Array<Wire>) : Array<Wire> {
    OpMToN(BLACKBOX(spec), inputs, spec.GetOutputPorts())
}