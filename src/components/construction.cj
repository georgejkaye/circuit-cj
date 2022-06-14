package components

import graphs.*

public func MakeCircuit(inputs : Array<WireEnd>, outputs : Array<WireEnd>) : InterfacedHypergraph {
    let interfaceVertices = ArrayList<WireEnd>(inputs)
    interfaceVertices.addAll(outputs)
    let graph = CombineGraphs(interfaceVertices.toArray())
    InterfacedHypergraph(graph, WiresToVertices(inputs), WiresToVertices(outputs))
}