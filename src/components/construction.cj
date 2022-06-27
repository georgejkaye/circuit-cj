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
        COMPOSITE(
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

public func MakeSubcircuit(internalInputs : Array<Wire>, internalOutputs : Array<Wire>, inputs!: Array<Wire>, name!: String = "") : (InterfacedHypergraph, Array<Wire>) {
    MakeSubcircuit(internalInputs, internalOutputs, inputs: Some(inputs), name: name)
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

/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them. 
 * The operations will be applied from least significant bit to most significant bit: an auxiliary 
 * value can be threaded between the operations if desired (e.g. a carry)
 *
 * @param ws      The array of wires to input
 * @param f       The function to perform for the ith bit of each wire. Takes an axiliary value.
 * @param initial The initial auxiliary value
 * @return The output wire and the final aux value
 */
public func Bitwise<T>(ws : Array<Wire>, f : (Array<Wire>, T) -> (Wire, T), initial : T) : (Wire, T) {
    let (size, width) = AssertWiresSameWidth(ws)
    let splitWires = Array<Array<Wire>>(size) {
        i : Int64 => Split(ws[i], Array<Int64>(width){ j : Int64 => 1})
    }
    var aux = initial
    let outputs = ArrayList<Wire>(width)
    for (i in 0..width) {
        let inputs = Array<Wire>(size){ j : Int64 => splitWires[j][i] }
        let (gate1, gate2) = f(inputs, aux)
        outputs.append(gate1)
        aux = gate2
    }
    let outputWire = Combine(outputs.toArray())
    (outputWire, aux)
}
public func Bitwise(ws : Array<Wire>, f : (Array<Wire>) -> Wire) : Wire {
    Bitwise(ws, {ws : Array<Wire> , v : Unit => (f(ws), ()) }, ())[0]
}

public func Ripple(ws : Array<Wire>, f : (Wire, Wire) -> (Wire)) : Wire {
    let (size, width) = AssertWiresSameWidth(ws)
    AssertMinNumberOfWires(ws, 2)
    var prev = ws[0]
    for (i in 1..size) {
        let cur = ws[i]
        prev = f(prev, cur)   
    }
    prev
}

public func InternalRipple(w : Wire, f : (Wire, Wire) -> (Wire)) : Wire {
    let width = w.GetWidth()
    let splitWires = Split(w, Array<Int64>(width){ i : Int64 => 1 })
    Ripple(splitWires, f)
}