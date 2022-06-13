package components

import graphs.*

func OpMToN(label : Label, inputs: Array<Vertex>, outputs : Int64) : Array<Vertex> {
    if (label.GetInputs() != inputs.size() || label.GetOutputs() != outputs) {
        throw IncompatibleLabelInterfaceException("OpMToN - ${label}", label, inputs.size(), outputs)
    }
    let baseGraph = CombineGraphs(inputs)
    let outputVertices = Array<Vertex>(label.GetOutputs(), { i : Int64 => Vertex() })
    let edge = Edge(label, inputs, outputVertices)
    baseGraph.AddEdge(edge)
    outputVertices
}

public func OpZeroToOne(label : Label) : Vertex {
    OpMToN(label, [], 1)[0]
}

public func OpTwoToOne(label : Label, a : Vertex, b : Vertex) : Vertex {
    OpMToN(label, [a,b], 1)[0]
}

public func AndGate(a : Vertex, b : Vertex) : Vertex {
    OpTwoToOne(AND, a, b)
}

public func TrueSignal() : Vertex {
    OpZeroToOne(TRUE)
}

public func FalseSignal() : Vertex {
    OpZeroToOne(FALSE)
}