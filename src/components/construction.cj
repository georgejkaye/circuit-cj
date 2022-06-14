package components

import graphs.*

func CombineGraphs(vs : Array<Vertex>) : Hypergraph {
    let owners = ArrayList<Hypergraph>()
    for (v in vs) {
        let owner = v.GetOwner()
        match(owner) {
            case None => throw NotOwnedException("CombineGraphs", v)
            case Some(o) => 
                if (!owners.contains(o)) {
                    owners.add(o)
                }
        }
    }

    let vertices = HashSet<Vertex>()
    let edges = HashSet<Edge>()

    for (owner in owners) {
        let currentVertices = owner.GetVertices()
        let currentEdges = owner.GetEdges()
        for(v in currentVertices) {
            v.RemoveOwner()
        }
        vertices.putAll(currentVertices)
        for(e in currentEdges){
            e.RemoveOwner()
        }
        edges.putAll(currentEdges)
    }
    Hypergraph(vertices, edges)
}

public func MakeCircuit(inputs : Array<Vertex>, outputs : Array<Vertex>) : InterfacedHypergraph {
    let interfaceVertices = ArrayList<Vertex>(inputs)
    interfaceVertices.addAll(outputs)
    let graph = CombineGraphs(interfaceVertices.toArray())
    InterfacedHypergraph(graph, inputs, outputs)
}