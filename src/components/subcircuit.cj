/**
 * components/subcircuit.cj
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
public func MakeSubcircuit<V, G>(
    inputs: Array<InterfaceWire<V, G>>,
    outputs : Array<InterfaceWire<V, G>>,
    label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    for(iv in inputs) {
        AssertHasNoInEdge(iv.GetVertex())
    }
    let inputOwner = MergeHypergraphs(inputs)
    let outputOwner = MergeHypergraphs(outputs)
    let owner = match(outputOwner) {
        case None => Hypergraph<V, G>()
        case Some(f) => f
    }
    // Clone the combined hypergraph so that this subcircuit isn't affected
    // later if we attach more things to the original graph
    let (newF, vertexMap, _) = owner.Clone()
    let newInputs = map({ iw : InterfaceWire<V, G> =>
        let newVertex = vertexMap.get(iw.GetVertex()).getOrThrow()
        InterfaceVertex(newVertex, name: iw.GetName())
    }, inputs)
    let newOutputs = map({ iw : InterfaceWire<V, G> =>
        let newVertex = vertexMap.get(iw.GetVertex()).getOrThrow()
        InterfaceVertex(newVertex, name: iw.GetName())
    }, outputs)
    InterfacedHypergraph(
        newF,
        newInputs,
        newOutputs,
        label
    )
}
/**
 * Make a subcircuit with some (optionally named) input and output wires.
 * This circuit can then be used in other subcircuits, where it will be
 * initially displayed as a single edge, but can be expanded to show the
 * components if desired.
 *
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
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    MakeSubcircuit(
        inputs,
        outputs,
        COMPOSITE(
            Specification(
                name,
                map({ iw : InterfaceWire<V, G> =>
                    Port(iw.GetWidth(), name: iw.GetName())
                }, inputs),
                map({ iw : InterfaceWire<V, G> =>
                    Port(iw.GetWidth(), name: iw.GetName())
                }, outputs)
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
public func MakeSubcircuit<V, G>(
    outputs : Array<InterfaceWire<V, G>>,
    label : Label<V, G>
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    MakeSubcircuit(
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
public func MakeSubcircuit<V, G>(
    outputs : Array<InterfaceWire<V, G>>,
    name : String
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    MakeSubcircuit(
        Array<InterfaceWire<V, G>>(),
        outputs,
        name
    )
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 *
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The array of output wires from the subcircuit
 */
public func UseSubcircuit<V, G>(
    childCircuit : InterfacedHypergraph<V, G>,
    inputs : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertArraysSameWidths(inputs, childCircuit.GetInputPorts())
    let potentialOwner = MergeHypergraphs(inputs)
    let actualOwner = match(potentialOwner) {
        case None    => Hypergraph<V, G>()
        case Some(f) => f
    }
    let newGraph = childCircuit.Clone()
    let subcircuitWires = UseEdgeWithNewOutputs(
        childCircuit.GetLabel(),
        inputs,
        newGraph,
        actualOwner
    )
    if(delay > 0) {
        UseDelays(subcircuitWires, duration: delay)
    } else {
        subcircuitWires
    }
}
/**
 * Get the output wires of a circuit with no inputs
 *
 * @param circuit The circuit to connect
 * @return The array of output wires from the subcircuit
 */
public func UseSubcircuit<V, G>(
    childCircuit : InterfacedHypergraph<V, G>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasArity(childCircuit, 0)
    UseSubcircuit(childCircuit, Array<Wire<V, G>>(), delay: delay)
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 *
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The output wire of the circuit
 */
public func UseSubcircuit_1<V, G>(
    childCircuit : InterfacedHypergraph<V, G>,
    inputs : Array<Wire<V, G>>, delay!: Int64 = 0
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasCoarity(childCircuit, 1)
    UseSubcircuit(childCircuit, inputs, delay: delay)[0]
}
/**
 * Get the output wire of a circuit with no inputs
 *
 * @param circuit The circuit to connect
 * @return The output wire of the subcircuit
 */
public func UseSubcircuit_1<V, G>(
    childCircuit : InterfacedHypergraph<V, G>, delay!: Int64 = 0
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasArity(childCircuit, 0)
    UseSubcircuit_1(childCircuit, Array<Wire<V, G>>(), delay: delay)
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 *
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The pair of output wires from the subcircuit
 */
public func UseSubcircuit_2<V, G>(
    childCircuit : InterfacedHypergraph<V, G>,
    inputs : Array<Wire<V, G>>,
    delay!: Int64 = 0
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasCoarity(childCircuit, 2)
    let outputs = UseSubcircuit(childCircuit, inputs, delay: delay)
    (outputs[0], outputs[1])
}
/**
 * Get the output wires of a circuit with no inputs
 *
 * @param circuit The circuit to connect
 * @return The pair of output wire from the subcircuit
 */
public func UseSubcircuit_2<V, G>(
    childCircuit : InterfacedHypergraph<V, G>, delay!: Int64 = 0
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasArity(childCircuit, 0)
    UseSubcircuit_2(childCircuit, Array<Wire<V, G>>(), delay: delay)
}
/**
 * Connect a subcircuit to some inputs and get its outputs
 *
 * @param circuit The circuit to connect
 * @param inputs The inputs to hook up to the circuit
 * @return The 3-tuple of output wires from the subcircuit
 */
public func UseSubcircuit_3<V, G>(
    childCircuit : InterfacedHypergraph<V, G>,
    inputs : Array<Wire<V, G>>, delay!: Int64 = 0
) : (Wire<V, G>, Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasCoarity(childCircuit, 3)
    let outputs = UseSubcircuit(childCircuit, inputs, delay: delay)
    (outputs[0], outputs[1], outputs[2])
}
/**
 * Get the output wires of a circuit with no inputs
 *
 * @param circuit The circuit to connect
 * @return The 3-tuple of output wires from the subcircuit
 */
public func UseSubcircuit_3<V, G>(
    childCircuit : InterfacedHypergraph<V, G>, delay!: Int64 = 0
) : (Wire<V, G>, Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertHasArity(childCircuit, 0)
    UseSubcircuit_3(childCircuit, Array<Wire<V, G>>(), delay: delay)
}
/**
 * Connect some inputs to a bitwise primitive
 *
 * @param prim The primitive to bitwise
 * @param ws The input wires
 * @return The output wire from the bitwise gate
 */
public func UseBitwiseMapGate<V, G>(
    prim : G, ws : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertAllSameWidth(ws)
    AssertHasLength(ws, prim.GetArity())
    if(ws[0].GetWidth() == 1) {
        UseGate(prim, ws, delay: delay)
    } else {
        UseSubcircuit(
            MakeBitwiseMapGate(prim, ws[0].GetWidth(), delay: delay),
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
public func UseRippleGate<V, G>(
    prim : G, ws : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonEmpty(ws)
    AssertMinimumLength(ws, prim.GetArity())
    let width = AssertAllSameWidth(ws)
    UseSubcircuit(MakeRippleGate(prim, ws.size, width, delay: delay), ws)
}
/**
 * Connect an input to an internally rippled primitive
 *
 * @param prim The primitive to ripple
 * @param w The input wire
 * @return The output wire from the internally rippled gate
 */
public func UseBitwiseRippleGate<V, G>(
    prim : G, ws : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let width = AssertAllSameWidth(ws)
    UseSubcircuit(MakeBitwiseRippleGate(prim, width, delay: delay), ws)
}