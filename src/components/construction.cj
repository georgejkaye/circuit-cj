package components

import graphs.*

public func MakeCircuit(inputs : Array<Wire>, outputs : Array<Wire>) : InterfacedHypergraph {
    let interfaceVertices = ArrayList<Wire>(inputs)
    interfaceVertices.addAll(outputs)
    let graph = CombineGraphs(interfaceVertices.toArray())
    InterfacedHypergraph(graph, inputs, outputs)
}