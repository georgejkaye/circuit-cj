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
public func MakeSubcircuit<V, G>(
    inputs : Array<InterfaceWire<V, G>>,
    outputs : Array<InterfaceWire<V, G>>,
    label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (first, inputsStart, outputsStart) = if(inputs.size > 0) {
        (inputs[0], 1, 0)
    } else {
        (outputs[0], 0, 1)
    }
    let owner = first.GetVertex().GetOwner()
    for(i in inputsStart..inputs.size) {
        let v = inputs[i].GetVertex()
        owner.IncludeHypergraph(v.GetOwner())
    }
    for(i in outputsStart..outputs.size) {
        let v = outputs[i].GetVertex()
        owner.IncludeHypergraph(v.GetOwner())
    }
    let (newF, vertexMap, _) = owner.Clone()
    let newInputs = map({iv : InterfaceWire<V, G> =>
        InterfaceVertex(vertexMap.get(iv.GetVertex()).getOrThrow(), iv.GetName())}, inputs)
    let newOutputs = map({iv : InterfaceWire<V, G> =>
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
public func MakeSubcircuit<V, G>(
    inputs : Array<InterfaceWire<V, G>>,
    outputs : Array<InterfaceWire<V, G>>,
    name : String
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    MakeSubcircuit(
        inputs,
        outputs,
        COMPOSITE(
            Specification(
                name,
                map({ iv : InterfaceWire<V, G> => Port(iv.GetWidth(), name: iv.GetName() )}, inputs),
                map({ iv : InterfaceWire<V, G> => Port(iv.GetWidth(), name: iv.GetName() )}, outputs)
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
public func MakeBitwiseGate<V, G>(
    prim : G,
    w : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    println("the width is ${w}")
    let inputs = Array<Wire<V, G>>(prim.GetArity()) {i : Int64 => UseWire<V, G>(w) }
    println("The inputs to the gate are ${inputs}")
    let output = Bitwise({ ws : Array<Wire<V, G>> => [UseGate(prim, ws)] }, inputs)[0]
    println("The outputs to the gate are ${output} which has width ${output.GetWidth()}")
    MakeSubcircuit(
        mapi({ w : Wire<V, G>, i : Int64 => InterfaceWire(w, numToUppercaseLetter(i)) }, inputs),
        [InterfaceWire(output, "Z")],
        prim.GetEnhancedName(prim.GetArity(), w)
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
func MakeRippleGate<V, G>(
    prim : G,
    n : Int64,
    w : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputs = Array<Array<Wire<V, G>>>(n) {i : Int64 => [UseWire<V, G>(w)] }
    let output = Ripple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> => [UseGate(prim, [acc[0], cur[0]])]},
        inputs
    )[0]
    MakeSubcircuit(
        mapi({ws : Array<Wire<V, G>>, i : Int64 => InterfaceWire(ws[0], numToUppercaseLetter(i)) }, inputs),
        [InterfaceWire(output, "Z")],
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
func MakeInternalRippleGate<V, G>(
    prim : G,
    w : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let input = UseWire<V, G>(w)
    let output = InternalRipple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> => [UseGate(prim, [acc[0], cur[0]])] },
        [input]
    )[0]
    MakeSubcircuit(
        [InterfaceWire(input, "A")],
        [InterfaceWire(output, "Z")],
        prim.GetEnhancedName(1, w)
    )
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The array of output wires from the subcircuit
 */
public func UseSubcircuit<T, V, G>(
    circuit : InterfacedHypergraph<V, G>,
    inputs : Array<T>
) : Array<Wire<V, G>>
    where T <: ToString, T <: ContainsWire<V, G>,
        V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertWiresHaveWidths<T, Port<V>>(inputs, circuit.GetInputPorts())
    let (newGraph, _, _) = circuit.CloneGraph()
    UseEdgeWithNewOutputs<V, G, T>(
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
public func UseSubcircuit_1<T, V, G>(
    circuit : InterfacedHypergraph<V, G>,
    inputs : Array<T>
) : Wire<V, G>
    where T <: ToString, T <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertCircuitOutputs(circuit, 1)
    UseSubcircuit<T, V, G>(circuit, inputs)[0]
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The pair of output wires from the subcircuit
 */
public func UseSubcircuit_2<T, V, G>(
    circuit : InterfacedHypergraph<V, G>,
    inputs : Array<T>
) : (Wire<V, G>, Wire<V, G>)
    where T <: ToString, T <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertCircuitOutputs(circuit, 2)
    let outputs = UseSubcircuit<T, V, G>(circuit, inputs)
    (outputs[0], outputs[1])
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The 3-tuple of output wires from the subcircuit
 */
public func UseSubcircuit_3<T, V, G>(
    circuit : InterfacedHypergraph<V, G>,
    inputs : Array<T>
) : (Wire<V, G>, Wire<V, G>, Wire<V, G>)
    where T <: ToString, T <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertCircuitOutputs(circuit, 3)
    let outputs = UseSubcircuit<T, V, G>(circuit, inputs)
    (outputs[0], outputs[1], outputs[2])
}

/**
 * Connect some inputs to a bitwise primitive
 * @param prim The primitive to bitwise
 * @param ws The input wires
 * @return The output wire from the bitwise gate
 */
public func UseBitwiseGate<V, G>(prim : G, ws : Array<Wire<V, G>>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    println("the bitwise array is ${ws}")
    AssertWiresSameWidth(ws)
    AssertNumberOfWires(ws, prim.GetArity())
    if(ws[0].GetWidth() == 1) {
        UseGate(prim, ws)
    } else {
        println("the width is ${ws[0].GetWidth()}")
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
public func UseRippleGate<V, G>(prim : G, ws : Array<Wire<V, G>>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertWireArrayNonEmpty(ws)
    AssertMinNumberOfWires(ws, prim.GetArity())
    let width = AssertWiresSameWidth(ws)
    UseSubcircuit_1<Wire<V, G>, V, G>(
        MakeRippleGate(
            prim,
            ws.size,
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
public func UseInternalRippleGate<V, G>(prim : G, w : Wire<V, G>) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    UseSubcircuit_1<Wire<V,G>, V, G>(
        MakeInternalRippleGate(
            prim,
            w.GetWidth()
        ),
        [w]
    )
}
/**
 * 'Apply' several arguments, interfaced hypergraphs with exactly one output,
 * to another interfaced hypergraph
 *
 * @param circuit The circuit to apply to
 * @param args The array of arguments
 * @return The applied hypergraph
 */
public func Apply<V, G>(
    circuit : InterfacedHypergraph<V, G>,
    args : Array<InterfacedHypergraph<V, G>>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertArgumentsCompatible(circuit, args)
    let wires = map(
        {ih : InterfacedHypergraph<V, G> =>
            InterfaceWire(UseSubcircuit_1(ih, Array<Wire<V, G>>()), ih.GetOutput(0).GetName())
        }, args)
    let argString = printArray(args, "(", ")", ", ", { ih : InterfacedHypergraph<V, G> => ih.GetName() }, false)
    let outputWires = UseSubcircuit(circuit, wires)
    MakeSubcircuit<V, G>(
        Array<InterfaceWire<V, G>>(),
        mapi({w : Wire<V, G>, i : Int64 => InterfaceWire(w, circuit.GetOutput(i).GetName())}, outputWires),
        "${circuit.GetName()}${argString}"
    )
}