package components

import graphs.*

public func MakeSubcircuit(internalInputs : Array<Wire>, internalOutputs : Array<Wire>, inputs!: Option<Array<Wire>> = None, name!: String = "") : (InterfacedHypergraph, Array<Wire>) {
    let interfaceVertices = ArrayList<Wire>(internalInputs)
    interfaceVertices.addAll(internalOutputs)
    let graph = CombineGraphs(interfaceVertices.toArray())

    let (newF, newInputs, newOutputs) = CloneWithInterfaces(graph, map({ w : Wire => w.GetVertex() }, internalInputs), map({ w : Wire => w.GetVertex() }, internalOutputs))
    let circuit = InterfacedHypergraph(newF, newInputs, newOutputs)

    let sources = match(inputs) {
        case None     => map({ w : Wire => Vertex(w.GetWidth()) }, internalInputs)
        case Some(ws) => 
                AssertWireArraysCompatible(internalInputs, ws)
                WiresToVertices(ws)
    }

    let edge = Edge(
        BLACKBOX(
            Specification(
                name,
                WiresToWidths(internalInputs),
                WiresToWidths(internalOutputs)
            )
        ),
        sources,
        WiresToWidths(internalOutputs),
        circuit
    )
    (circuit, VerticesToWires(edge.GetTargets()))
}

public func Subcircuit(circuit : InterfacedHypergraph, inputs : Array<Wire>) : ArrayList<Wire> {
    let inputType = map({w : Wire => w.GetWidth() }, inputs)

    if (inputType != circuit.GetInputType()){
        throw IncompatibleInputsException("Subcircuit", inputType, circuit)
    }

    let (newGraph, newInputs, newOutputs) = circuit.Clone()

    let vertices = Array<Vertex>(inputs.size() + 1) {
            i : Int64 => if (i < inputs.size()) {
                inputs[i].GetVertex()
            } else {
                newInputs[0]
            }  
    }

    let graph = CombineGraphs(vertices)

    for(i in 0..inputs.size()) {
        MergeVertices(inputs[i].GetVertex(), newInputs[i])
    }

    ArrayList<Wire>(newOutputs.size(), { i : Int64 => Wire(newOutputs[i])})

}

public func ForEachBit<T>(ws : Array<Wire>, f : (Array<Wire>, T) -> (Wire, T), initial : T) : (Wire, T) {
    let inputs = ws.size()
    if (inputs == 0) {
        throw NoWiresException()
    }
    let width = ws[0].GetWidth()
    let splitWires = Array<Array<Wire>>(inputs) {
        i : Int64 => Split(ws[i], Array<Int64>(width){ j : Int64 => 1})
    }
    var aux = initial
    let outputs = ArrayList<Wire>(width)
    for (i in 0..width) {
        let inputs = Array<Wire>(inputs){ j : Int64 => splitWires[j][i] }
        let (gate1, gate2) = f(inputs, aux)
        outputs.append(gate1)
        aux = gate2
    }
    let outputWire = Combine(outputs.toArray())
    (outputWire, aux)
}
public func ForEachBit(ws : Array<Wire>, f : (Array<Wire>) -> Wire) : Wire {
    ForEachBit(
        ws,
        {ws : Array<Wire> , v : Unit => (f(ws), ()) },
        ()
    )[0]
}