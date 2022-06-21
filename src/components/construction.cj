package components

import graphs.*

public func MakeCircuit(inputs : Array<WireEnd>, outputs : Array<WireEnd>) : InterfacedHypergraph {
    let interfaceVertices = ArrayList<WireEnd>(inputs)
    interfaceVertices.addAll(outputs)
    let graph = CombineGraphs(interfaceVertices.toArray())

    let (newF, newInputs, newOutputs) = CloneWithInterfaces(graph, map({ w : WireEnd => w.GetVertex() }, inputs), map({ w : WireEnd => w.GetVertex() }, outputs))
    InterfacedHypergraph(newF, newInputs, newOutputs)
}

public func Subcircuit(circuit : InterfacedHypergraph, inputs : Array<WireEnd>) : ArrayList<WireEnd> {
    let inputType = map({w : WireEnd => w.GetWidth() }, inputs)

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

    ArrayList<WireEnd>(newOutputs.size(), { i : Int64 => WireEnd(newOutputs[i])})

}

public func ForEachBit(ws : Array<WireEnd>, f : (Array<WireEnd>, WireEnd) -> (WireEnd, WireEnd), initial : WireEnd) : (WireEnd, WireEnd) {
    let inputs = ws.size()
    if (inputs == 0) {
        throw NoWiresException()
    }
    let width = ws[0].GetWidth()
    let splitWires = Array<Array<WireEnd>>(inputs) {
        i : Int64 => Split(ws[i], Array<Int64>(width){ j : Int64 => 1})
    }
    var aux = initial
    let outputs = ArrayList<WireEnd>(width)
    for (i in 0..width) {
        let inputs = Array<WireEnd>(inputs){ j : Int64 => splitWires[j][i] }
        let (gate1, gate2) = f(inputs, aux)
        outputs.append(gate1)
        aux = gate2
    }
    let outputWire = Combine(outputs.toArray())
    (outputWire, aux)
}