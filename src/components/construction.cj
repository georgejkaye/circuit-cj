package components

import graphs.*

public func MakeSubcircuit(internalInputs : Array<Wire>, internalOutputs : Array<Wire>, name!: String = "") : InterfacedHypergraph {
    let interfaceVertices = ArrayList<Wire>(internalInputs)
    interfaceVertices.addAll(internalOutputs)
    let graph = CombineGraphs(interfaceVertices.toArray())

    let (newF, newInputs, newOutputs) = CloneWithInterfaces(graph, map({ w : Wire => w.GetVertex() }, internalInputs), map({ w : Wire => w.GetVertex() }, internalOutputs))
    InterfacedHypergraph(newF, newInputs, newOutputs, name)
}

public func UseSubcircuit(circuit : InterfacedHypergraph, inputs : Array<Wire>) : Array<Wire> {
    AssertWiresTypecheck(inputs, circuit.GetInputType())
    let newGraph = circuit.CloneGraph()
    MakeEdge(
        circuit.GetLabel(),
        inputs,
        circuit.GetOutputType(),
        newGraph
    )
}

public func UseSubcircuit_1(circuit : InterfacedHypergraph, inputs : Array<Wire>) : Wire {
    UseSubcircuit(circuit, inputs)[0]
}

public func UseSubcircuit_2(circuit : InterfacedHypergraph, inputs : Array<Wire>) : (Wire, Wire) {
    let outputs = UseSubcircuit(circuit, inputs)
    (outputs[0], outputs[1]) 
}

public func UseSubcircuit_3(circuit : InterfacedHypergraph, inputs : Array<Wire>) : (Wire, Wire, Wire) {
    let outputs = UseSubcircuit(circuit, inputs)
    (outputs[0], outputs[1], outputs[2]) 
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