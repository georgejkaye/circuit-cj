package components

import graphs.*

public func MakeCircuit(inputs : Array<Vertex>, outputs : Array<Vertex>) : InterfacedHypergraph {
    let interfaceVertices = ArrayList<Vertex>(inputs)
    interfaceVertices.addAll(outputs)
    let graph = CombineGraphs(interfaceVertices.toArray())
    InterfacedHypergraph(graph, inputs, outputs)
}