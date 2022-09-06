/**
 * components/arithmetic.cj
 *
 * Functions for creating subcircuits
 *
 * @author George Kaye
 * @since 0.2
 */

package components

import prelude.*
import syntax.*
import graphs.*

/**
 * Make a subcircuit with some (optionally named) input and
 * output wires. This circuit can then be used in other subcircuits,
 * where it will be initially displayed as a single edge, but can
 * be expanded to show the components if desired.
 * @param inputs The inputs of the subcircuit
 * @param outputs The outputs of the subcircuit
 * @param label The label to give the subcircuit, which will be displayed
 *              on its edge
 * @return The new interfaced hypergraph representing the subcircuit
 */
public func MakeSubcircuit(
    inputs : Array<InterfaceWire>,
    outputs : Array<InterfaceWire>,
    label : Label
) : InterfacedHypergraph {
    let (first, inputsStart, outputsStart) = if(inputs.size() > 0) {
        (inputs[0], 1, 0)
    } else {
        (outputs[0], 0, 1)
    }
    let owner = first.GetVertex().GetOwner()
    for(i in inputsStart..inputs.size()) {
        let v = inputs[i].GetVertex()
        owner.IncludeHypergraph(v.GetOwner())
    }
    for(i in outputsStart..outputs.size()) {
        let v = outputs[i].GetVertex()
        owner.IncludeHypergraph(v.GetOwner())
    }
    let (newF, vertexMap, _) = owner.Clone()
    let newInputs = map({iv : InterfaceWire =>
        InterfaceVertex(vertexMap.get(iv.GetVertex()).getOrThrow(), iv.GetName())}, inputs)
    let newOutputs = map({iv : InterfaceWire =>
        InterfaceVertex(vertexMap.get(iv.GetVertex()).getOrThrow(), iv.GetName())}, outputs)
    InterfacedHypergraph(
        newF,
        newInputs,
        newOutputs,
        label
    )
}
/**
 * Make a subcircuit with some (optionally named) input and
 * output wires. This circuit can then be used in other subcircuits,
 * where it will be initially displayed as a single edge, but can
 * be expanded to show the components if desired.
 * @param inputs The inputs of the subcircuit
 * @param outputs The outputs of the subcircuit
 * @param label The name of the subcircuit, which will be given a
                'composite' label on its parent edge
 * @return The new interfaced hypergraph representing the subcircuit
 */
public func MakeSubcircuit(
    inputs : Array<InterfaceWire>,
    outputs : Array<InterfaceWire>,
    name : String
) : InterfacedHypergraph {
    MakeSubcircuit(
        inputs,
        outputs,
        COMPOSITE(
            Specification(
                name,
                map({ iv : InterfaceWire => Port(iv.GetWidth(), name: iv.GetName() )}, inputs),
                map({ iv : InterfaceWire => Port(iv.GetWidth(), name: iv.GetName() )}, outputs)
            )
        )
    )
}

/**
 * Make a circuit that applies a given primitive bitwise, i.e. the primitive
 * will be applied to each bit of the input wires independently
 *
 * @param prim The primitive to apply
 * @param w The width of the input wires
 * @return The bitwise gate circuit
 */
public func MakeBitwiseGate(
    prim : Primitive,
    w : Int64
) : InterfacedHypergraph {
    let inputs = Array<InterfaceWire>(prim.GetNoInputs()) {
        i : Int64 => InterfaceWire(w, numToUppercaseLetter(i))
    }
    let output = InterfaceWire(
            Bitwise<InterfaceWire>(
            inputs,
            { ws : Array<Wire> => [prim.UseGate()(ws)] }
        )[0], "Z"
    )
    MakeSubcircuit(
        inputs,
        [output],
        prim.GetEnhancedName(prim.GetNoInputs(), w)
    )
}
/**
 * Make a circuit that ripples a given primitive over some inputs, i.e. the primitive
 * will be applied to each input wire one at a time in succession
 *
 * @param prim The primitive to apply
 * @param n The number of input wires
 * @param w The width of the input wires
 * @return The ripple gate circuit
 */
func MakeRippleGate(
    prim : Primitive,
    n : Int64,
    w : Int64
) : InterfacedHypergraph {
    let inputs = Array<InterfaceWire>(n) {
        i : Int64 => InterfaceWire(w, numToUppercaseLetter(i))
    }
    let output = InterfaceWire(
        Ripple<InterfaceWire>(
            inputs,
            { w : Wire, v : Wire => prim.UseGate()([w, v]) }
        ),
        "Z"
    )
    MakeSubcircuit(
        inputs,
        [output],
        prim.GetEnhancedName(n, w)
    )
}
/**
 * Make a circuit that ripples a given primitive over the bits in a single wire,
 * i.e. the primitive will be applied to each bit wire one at a time in succession
 *
 * @param prim The primitive to apply
 * @param w The width of the input wire
 * @return The internal ripple gate circuit
 */
func MakeInternalRippleGate(
    prim : Primitive,
    w : Int64
) : InterfacedHypergraph {
    let input = InterfaceWire(w, "A")
    let output = InterfaceWire(
        InternalRipple<InterfaceWire>(
            input,
            { w : Wire, v : Wire => (prim.UseGate()([w, v])) }
        ),
        "Z"
    )
    MakeSubcircuit(
        [input],
        [output],
        prim.GetEnhancedName(1, w)
    )
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The array of output wires from the subcircuit
 */
public func UseSubcircuit<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : Array<Wire> where T <: ToString, T <: ContainsWire {
    AssertWiresHaveWidths<T, Port>(inputs, circuit.GetInputPorts())
    let (newGraph, _, _) = circuit.CloneGraph()
    MakeEdgeWithNewOutputs<T>(
        circuit.GetLabel(),
        inputs,
        newGraph
    )
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The output wire of the circuit
 */
public func UseSubcircuit_1<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : Wire where T <: ToString, T <: ContainsWire {
    AssertCircuitOutputs(circuit, 1)
    UseSubcircuit<T>(circuit, inputs)[0]
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The pair of output wires from the subcircuit
 */
public func UseSubcircuit_2<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : (Wire, Wire) where T <: ToString, T <: ContainsWire {
    AssertCircuitOutputs(circuit, 2)
    let outputs = UseSubcircuit<T>(circuit, inputs)
    (outputs[0], outputs[1])
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The 3-tuple of output wires from the subcircuit
 */
public func UseSubcircuit_3<T>(
    circuit : InterfacedHypergraph,
    inputs : Array<T>
) : (Wire, Wire, Wire) where T <: ToString, T <: ContainsWire {
    AssertCircuitOutputs(circuit, 3)
    let outputs = UseSubcircuit<T>(circuit, inputs)
    (outputs[0], outputs[1], outputs[2])
}

/**
 * Connect some inputs to a bitwise primitive
 * @param prim The primitive to bitwise
 * @param ws The input wires
 * @return The output wire from the bitwise gate
 */
public func UseBitwiseGate(prim : Primitive, ws : Array<Wire>) : Wire {
    AssertWiresSameWidth(ws)
    AssertNumberOfWires(ws, prim.GetNoInputs())
    if(ws[0].GetWidth() == 1) {
        prim.UseGate()(ws)
    } else {
        UseSubcircuit_1(
            MakeBitwiseGate(
                prim,
                ws[0].GetWidth()
            ),
            ws
        )
    }
}

/**
 * Connect some inputs to a rippled primitive
 * @param prim The primitive to ripple
 * @param ws The input wires
 * @return The output wire from the rippled gate
 */
public func UseRippleGate(prim : Primitive, ws : Array<Wire>) : Wire {
    AssertWireArrayNonEmpty(ws)
    AssertMinNumberOfWires(ws, prim.GetNoInputs())
    let width = AssertWiresSameWidth(ws)
    UseSubcircuit_1<Wire>(
        MakeRippleGate(
            prim,
            ws.size(),
            width
        ),
        ws
    )
}
/**
 * Connect an input to an internally rippled primitive
 * @param prim The primitive to ripple
 * @param w The input wire
 * @return The output wire from the internally rippled gate
 */
public func UseInternalRippleGate(prim : Primitive, w : Wire) : Wire {
    UseSubcircuit_1(
        MakeInternalRippleGate(
            prim,
            w.GetWidth()
        ),
        [w]
    )
}