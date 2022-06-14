package components

import graphs.*

func OpMToN(label : Label, inputs: Array<Vertex>, outputs : Array<Int64>) : Array<Vertex> {
    CheckLabelCompatibility(label, map({ v : Vertex => v.GetWidth() }, inputs), outputs)
    let edge = Edge(label, inputs, outputs)
    edge.GetTargets()
}

func OpZeroToOne(label : Label) : Vertex {
    OpMToN(label, [], [1])[0]
}
func OpOneToOne(label : Label, a : Vertex) : Vertex {
    OpMToN(label, [a], [1])[0]
}
func OpTwoToOne(label : Label, a : Vertex, b : Vertex) : Vertex {
    OpMToN(label, [a,b], [1])[0]
}

public func NotGate(a : Vertex) : Vertex {
    OpOneToOne(NOT, a)
}
public func AndGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(AND, a, b)
}
public func OrGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(OR, a, b)
}
public func NandGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(NAND, a, b)
}
public func NorGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(NOR, a, b)
}
public func XorGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(XOR, a, b)
}
public func XnorGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(XNOR, a, b)
}


public func TrueSignal() : Vertex {
    OpZeroToOne(TRUE)
}

public func FalseSignal() : Vertex {
    OpZeroToOne(FALSE)
}

public func BlackBox(spec : Specification, inputs: Array<Vertex>) : Array<Vertex> {
    OpMToN(BLACKBOX(spec), inputs, spec.GetOutputPorts())
}