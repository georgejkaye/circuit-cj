package components

import graphs.*

public func MakeSubcircuit(
    internalInputs : Array<NamedWire>,
    internalOutputs : Array<NamedWire>,
    name!: String = ""
) : InterfacedHypergraph {
    let interfaceVertices = Array<Wire>(internalInputs.size() + internalOutputs.size()){
        i : Int64 =>
        let namedWire = if (i < internalInputs.size()) {
            internalInputs[i]
        } else {
            internalOutputs[i - internalInputs.size()]
        }
        namedWire.wire
    }
    let graph = CombineGraphs(interfaceVertices)
    func MakeInternalPortArray(array : Array<NamedWire>) : Array<Port> {
        Array<Port>(array.size()){
            i : Int64 =>
            let namedWire = array[i]
            Port(namedWire.wire.GetWidth(), name: namedWire.name)
        }
    }
    let dom = MakeInternalPortArray(internalInputs)
    let cod = MakeInternalPortArray(internalOutputs)
    let (newF, newInputs, newOutputs) = CloneWithInterfaces(
        graph, 
        map({ w : NamedWire => w.wire.GetVertex() }, internalInputs), 
        map({ w : NamedWire => w.wire.GetVertex() }, internalOutputs)
    )
    InterfacedHypergraph(
        newF,
        Specification(
            name,
            dom,
            cod
        ),
        newInputs,
        newOutputs
    )
}

public func UseSubcircuit<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : Array<Wire> where T <: ToString, T <: HasWidth {
    AssertWiresHaveWidths<T, Port>(inputs, circuit.GetInputPorts())
    let newGraph = circuit.CloneGraph()
    MakeEdge(
        COMPOSITE(circuit.GetSpecification()),
        map({ t : T => t.GetWidth() }, inputs),
        circuit.GetOutputPorts(),
        newGraph
    )
}

public func UseSubcircuit_1<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : Wire where T <: ToString, T <: ContainsWire {
    AssertCircuitOutputs(circuit, 1)
    UseSubcircuit<T>(circuit, inputs)[0]
}

public func UseSubcircuit_2<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : (Wire, Wire) where T <: ToString, T <: ContainsWire {
    AssertCircuitOutputs(circuit, 2)
    let outputs = UseSubcircuit<T>(circuit, inputs)
    (outputs[0], outputs[1]) 
}

public func UseSubcircuit_3<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : (Wire, Wire, Wire) where T <: ToString, T <: ContainsWire {
    AssertCircuitOutputs(circuit, 3)
    let outputs = UseSubcircuit<T>(circuit, inputs)
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
public func Bitwise<T, U>(
    ws : Array<T>,
    f : (Array<Wire>, U) -> (Wire, U),
    initial : U
) : (Wire, U) where T <: ToString, T <: ContainsWire {
    let size = ws.size()
    let width = AssertWiresSameWidth<T>(ws)
    let splitWires = Array<Array<Wire>>(size) {
        i : Int64 => 
            let wire = ws[i].GetWire()
            Split(
                wire,
                Array<Int64>(width){ j : Int64 => 1}
            )
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
public func Bitwise<T>(
    ws : Array<T>,
    f : (Array<Wire>) -> Wire
) : Wire where T <: ToString, T <: ContainsWire {
    Bitwise<T, Unit>(
        ws,
        {ws : Array<Wire> , v : Unit => (f(ws), ()) },
        ()
    )[0]
}

public func Ripple<T>(
    ws : Array<T>,
    f : (Wire, Wire) -> (Wire)
) : Wire where T <: ToString, T <: ContainsWire {
    let width = AssertWiresSameWidth<T>(ws)
    let size = ws.size()
    AssertMinNumberOfWires<T>(ws, 2)
    var prev = ws[0].GetWire()
    for (i in 1..size) {
        let cur = ws[i].GetWire()
        prev = f(prev, cur)   
    }
    prev
}

public func InternalRipple(w : Wire, f : (Wire, Wire) -> (Wire)) : Wire {
    let width = w.GetWidth()
    let splitWires = Split(w, Array<Int64>(width){ i : Int64 => 1 })
    Ripple(splitWires, f)
}