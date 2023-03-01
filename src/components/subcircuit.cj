/**
 * components/arithmetic.cj
 *
 * Functions for creating subcircuits
 *
 * @author George Kaye
 * @since 0.2
 */

package components

import utils.*

/**
 * Make a subcircuit with some (optionally named) input and
 * output wires. This circuit can then be used in other subcircuits,
 * where it will be initially displayed as a single edge, but can
 * be expanded to show the components if desired.
 *
 * @param inputs The inputs of the subcircuit
 * @param outputs The outputs of the subcircuit
 * @param label The label to give the subcircuit, which will be displayed
 *              on its edge
 * @return The new interfaced hypergraph representing the subcircuit
 */
func MakeSubcircuit<V, G>(
    inputs: Array<InterfaceWire<V, G>>,
    outputs : Array<InterfaceWire<V, G>>,
    label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    for(iv in inputs) {
        AssertWireHasNoInEdge(iv.GetWire())
    }
    let (first, inputsStart, outputsStart) = if(inputs.size > 0) {
        (inputs[0], 1, 0)
    } else {
        (outputs[0], 0, 1)
    }
    // We need all of the elements captured in this subcircuit to
    // be part of the same hypergraphs
    let owner = first.GetVertex().GetOwner()
    for(i in inputsStart..inputs.size) {
        let v = inputs[i].GetVertex()
        owner.IncludeHypergraph(v.GetOwner())
    }
    for(i in outputsStart..outputs.size) {
        let v = outputs[i].GetVertex()
        owner.IncludeHypergraph(v.GetOwner())
    }
    // Clone the combined hypergraph so that this subcircuit isn't affected
    // later if we attach more things to the original graph
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
public interface SubcircuitBuilder<V, G>
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    func MakeSubcircuit(
        inputs: Array<InterfaceWire<V, G>>,
        outputs : Array<InterfaceWire<V, G>>,
        name : String
    ) : InterfacedHypergraph<V, G>
    func MakeSubcircuit(
        outputs : Array<InterfaceWire<V, G>>,
        name : String
    ) : InterfacedHypergraph<V, G>
    func MakeBitwiseMapGate(
        prim : G,
        width : Int64
    ) : InterfacedHypergraph<V, G>
    func MakeRippleGate(
        prim : G,
        inputs : Int64,
        width : Int64
    ) : InterfacedHypergraph<V, G>
    func MakeBitwiseRippleGate(
        prim : G,
        width : Int64
    ) : InterfacedHypergraph<V, G>
    func UseSubcircuit(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : Array<Wire<V, G>>
    func UseSubcircuit(
        circuit : InterfacedHypergraph<V, G>
    ) : Array<Wire<V, G>>
    func UseSubcircuit_1(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : Wire<V,G>
    func UseSubcircuit_1(
        circuit : InterfacedHypergraph<V, G>
    ) : Wire<V, G>
    func UseSubcircuit_2(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : (Wire<V, G>, Wire<V, G>)
    func UseSubcircuit_2(
        circuit : InterfacedHypergraph<V, G>
    ) : (Wire<V, G>, Wire<V, G>)
    func UseSubcircuit_3(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : (Wire<V, G>, Wire<V, G>, Wire<V, G>)
    func UseSubcircuit_3(
        circuit : InterfacedHypergraph<V, G>
    ) : (Wire<V, G>, Wire<V, G>, Wire<V, G>)
    func UseBitwiseMapGate(
        prim: G,
        inputs : Array<Wire<V, G>>
    ) : Wire<V, G>
    func UseRippleGate(
        prim : G,
        inputs : Array<Wire<V, G>>
    ) : Wire<V, G>
    func UseBitwiseRippleGate(
        prim : G,
        input : Array<Wire<V, G>>
    ) : Wire<V, G>
    func Apply(
        circuit : InterfacedHypergraph<V, G>,
        args : Array<InterfacedHypergraph<V, G>>
    ) : InterfacedHypergraph<V, G>
}

extend Signature<V, G> <: SubcircuitBuilder<V, G> {
    func MakeSubcircuit(
        inputs: Array<InterfaceWire<V, G>>,
        outputs : Array<InterfaceWire<V, G>>,
        label : Label<V, G>
    ) : InterfacedHypergraph<V, G> {
        MakeSubcircuit<V, G>(inputs, outputs, label)
    }
    /**
     * Make a subcircuit with some (optionally named) input and output wires.
     * This circuit can then be used in other subcircuits, where it will be initially displayed
     * as a single edge, but can be expanded to show the components if desired.
     *
     * @param inputs The inputs of the subcircuit
     * @param outputs The outputs of the subcircuit
     * @param label The name of the subcircuit, which will be given a
                    'composite' label on its parent edge
     * @return The new interfaced hypergraph representing the subcircuit
     */
    public func MakeSubcircuit(
        inputs : Array<InterfaceWire<V, G>>,
        outputs : Array<InterfaceWire<V, G>>,
        name : String
    ) : InterfacedHypergraph<V, G> {
        MakeSubcircuit<V, G>(
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
    * Make a subcircuit with some (optionally named) output wires. This circuit
    * can then be used in other subcircuits, where it will be initially displayed
    * as a single edge, but can be expanded to show the components if desired.
    *
    * @param outputs The outputs of the subcircuit
    * @param label The label of the subcircuit
    * @return The new interfaced hypergraph representing the subcircuit
    */
    public func MakeSubcircuit(
        outputs : Array<InterfaceWire<V, G>>,
        label : Label<V, G>
    ) : InterfacedHypergraph<V, G> {
        MakeSubcircuit<V, G>(
            Array<InterfaceWire<V, G>>(),
            outputs,
            label
        )
    }
    /**
    * Make a subcircuit with some (optionally named) output wires. This circuit
    * can then be used in other subcircuits, where it will be initially displayed
    * as a single edge, but can be expanded to show the components if desired.
    *
    * @param outputs The outputs of the subcircuit
    * @param label The name of the subcircuit, which will be given a
                    'composite' label on its parent edge
    * @return The new interfaced hypergraph representing the subcircuit
    */
    public func MakeSubcircuit(
        outputs : Array<InterfaceWire<V, G>>,
        name : String
    ) : InterfacedHypergraph<V, G> {
        this.MakeSubcircuit(
            Array<InterfaceWire<V, G>>(),
            outputs,
            name
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
    public func MakeBitwiseMapGate(
        prim : G,
        w : Int64
    ) : InterfacedHypergraph<V, G> {
        let inputs = Array<Wire<V, G>>(prim.GetArity()) {i : Int64 => this.UseWire(w) }
        let output = BitwiseMap(
            { ws : Array<Wire<V, G>> => [UseGate(prim, ws)] },
            inputs
        )[0]
        MakeSubcircuit(
            mapi({ w : Wire<V, G>, i : Int64 => InterfaceWire(w, numToUppercaseLetter(i)) }, inputs),
            [InterfaceWire(output, "Z")],
            ENHANCED_PRIMITIVE(
                EnhancedPrimitive(
                    prim,
                    BITWISE_MAP(w)
                )
            )
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
    public func MakeRippleGate(
        prim : G,
        n : Int64,
        w : Int64
    ) : InterfacedHypergraph<V, G> {
        let inputs = Array<Array<Wire<V, G>>>(n) {i : Int64 => [this.UseWire(w)] }
        let output = Ripple(
            { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> => [UseGate(prim, [acc[0], cur[0]])]},
            inputs
        )[0]
        MakeSubcircuit(
            mapi({ws : Array<Wire<V, G>>, i : Int64 => InterfaceWire(ws[0], numToUppercaseLetter(i)) }, inputs),
            [InterfaceWire(output, "Z")],
            ENHANCED_PRIMITIVE(
                EnhancedPrimitive(
                    prim,
                    RIPPLE(n-1)
                )
            )
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
    public func MakeBitwiseRippleGate(
        prim : G,
        w : Int64
    ) : InterfacedHypergraph<V, G> {
        let input = this.UseWire(w)
        let output = BitwiseRipple(
            { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> => [UseGate(prim, [acc[0], cur[0]])] },
            [input]
        )[0]
        MakeSubcircuit(
            [InterfaceWire(input, "A")],
            [InterfaceWire(output, "Z")],
            ENHANCED_PRIMITIVE(
                EnhancedPrimitive(
                    prim,
                    BITWISE_RIPPLE(w-1)
                )
            )
        )
    }
    /**
     * Connect a subcircuit to some inputs and get its outputs
     *
     * @param circuit The circuit to connect
     * @param inputs The inputs to hook up to the circuit
     * @return The array of output wires from the subcircuit
     */
    public func UseSubcircuit(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : Array<Wire<V, G>> {
        AssertWiresHaveWidths(inputs, circuit.GetInputPorts())
        let newGraph = circuit.Clone()
        UseEdgeWithNewOutputs(
            circuit.GetLabel(),
            inputs,
            newGraph
        )
    }
    /**
     * Get the output wires of a circuit with no inputs
     *
     * @param circuit The circuit to connect
     * @return The array of output wires from the subcircuit
     */
    public func UseSubcircuit(
        circuit : InterfacedHypergraph<V, G>
    ) : Array<Wire<V, G>> {
        AssertCircuitInputs(circuit, 0)
        this.UseSubcircuit(
            circuit,
            Array<Wire<V, G>>()
        )
    }
    /**
     * Connect a subcircuit to some inputs and get its outputs
     *
     * @param circuit The circuit to connect
     * @param inputs The inputs to hook up to the circuit
     * @return The output wire of the circuit
     */
    public func UseSubcircuit_1(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : Wire<V, G> {
        AssertCircuitOutputs(circuit, 1)
        this.UseSubcircuit(circuit, inputs)[0]
    }
    /**
     * Get the output wire of a circuit with no inputs
     *
     * @param circuit The circuit to connect
     * @return The output wire of the subcircuit
     */
    public func UseSubcircuit_1(
        circuit : InterfacedHypergraph<V, G>
    ) : Wire<V, G> {
        AssertCircuitInputs(circuit, 0)
        this.UseSubcircuit_1(circuit, Array<Wire<V, G>>())
    }
    /**
     * Connect a subcircuit to some inputs and get its outputs
     *
     * @param circuit The circuit to connect
     * @param inputs The inputs to hook up to the circuit
     * @return The pair of output wires from the subcircuit
     */
    public func UseSubcircuit_2(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : (Wire<V, G>, Wire<V, G>) {
        AssertCircuitOutputs(circuit, 2)
        let outputs = this.UseSubcircuit(circuit, inputs)
        (outputs[0], outputs[1])
    }
    /**
     * Get the output wires of a circuit with no inputs
     *
     * @param circuit The circuit to connect
     * @return The pair of output wire from the subcircuit
     */
    public func UseSubcircuit_2(
        circuit : InterfacedHypergraph<V, G>
    ) : (Wire<V, G>, Wire<V, G>) {
        AssertCircuitInputs(circuit, 0)
        this.UseSubcircuit_2(circuit, Array<Wire<V, G>>())
    }
    /**
     * Connect a subcircuit to some inputs and get its outputs
     *
     * @param circuit The circuit to connect
     * @param inputs The inputs to hook up to the circuit
     * @return The 3-tuple of output wires from the subcircuit
     */
    public func UseSubcircuit_3(
        circuit : InterfacedHypergraph<V, G>,
        inputs : Array<Wire<V, G>>
    ) : (Wire<V, G>, Wire<V, G>, Wire<V, G>) {
        AssertCircuitOutputs(circuit, 3)
        let outputs = this.UseSubcircuit(circuit, inputs)
        (outputs[0], outputs[1], outputs[2])
    }
    /**
     * Get the output wires of a circuit with no inputs
     *
     * @param circuit The circuit to connect
     * @return The 3-tuple of output wires from the subcircuit
     */
    public func UseSubcircuit_3(
        circuit : InterfacedHypergraph<V, G>
    ) : (Wire<V, G>, Wire<V, G>, Wire<V, G>) {
        AssertCircuitInputs(circuit, 0)
        this.UseSubcircuit_3(circuit, Array<Wire<V, G>>())
    }
    /**
     * Connect some inputs to a bitwise primitive
     *
     * @param prim The primitive to bitwise
     * @param ws The input wires
     * @return The output wire from the bitwise gate
     */
    public func UseBitwiseMapGate(prim : G, ws : Array<Wire<V, G>>) : Wire<V, G> {
        AssertWiresSameWidth(ws)
        AssertNumberOfWires(ws, prim.GetArity())
        if(ws[0].GetWidth() == 1) {
            UseGate(prim, ws)
        } else {
            UseSubcircuit_1(
                MakeBitwiseMapGate(
                    prim,
                    ws[0].GetWidth()
                ),
                ws
            )
        }
    }

    /**
    * Connect some inputs to a rippled primitive
    *
    * @param prim The primitive to ripple
    * @param ws The input wires
    * @return The output wire from the rippled gate
    */
    public func UseRippleGate(prim : G, ws : Array<Wire<V, G>>) : Wire<V, G> {
        AssertNonEmpty(ws)
        AssertMinNumberOfWires(ws, prim.GetArity())
        let width = AssertWiresSameWidth(ws)
        UseSubcircuit_1(
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
    *
    * @param prim The primitive to ripple
    * @param w The input wire
    * @return The output wire from the internally rippled gate
    */
    public func UseBitwiseRippleGate(prim : G, ws : Array<Wire<V, G>>) : Wire<V, G> {
        let width = AssertWiresSameWidth(ws)
        UseSubcircuit_1(
            MakeBitwiseRippleGate(
                prim,
                width
            ),
            ws
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
    public func Apply(
        circuit : InterfacedHypergraph<V, G>,
        args : Array<InterfacedHypergraph<V, G>>
    ) : InterfacedHypergraph<V, G> {
        AssertArgumentsCompatible(circuit, args)
        let wires = map(
            {ih : InterfacedHypergraph<V, G> =>
                let inputs = map({ iv : InterfaceVertex<V, G> => this.UseWire(iv.GetWidth())}, ih.GetInputs())
                InterfaceWire(
                    UseSubcircuit_1(ih, inputs),
                    ih.GetOutput(0).GetName()
                )
            }, args)
        let argString = printArray(
            args, { ih : InterfacedHypergraph<V, G> => ih.GetName() },
            openingBracket: "(", closingBracket: ")", delimiter: ","
        )
        let outputWires = this.UseSubcircuit(
            circuit,
            map({iw : InterfaceWire<V, G> => iw.wire}, wires)
        )
        this.MakeSubcircuit(
            Array<InterfaceWire<V, G>>(),
            mapi({w : Wire<V, G>, i : Int64 => InterfaceWire(w, circuit.GetOutput(i).GetName())}, outputWires),
            "${circuit.GetName()}${argString}"
        )
    }
}