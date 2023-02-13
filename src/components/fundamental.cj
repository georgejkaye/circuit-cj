/**
 * components/fundamental.cj
 *
 * Functions for creating values and primitives, the fundamental
 * components of circuits
 *
 * @author George Kaye
 * @since 0.3
 */

package components

public interface FundamentalBuilder<V, G>
    where V <: ValueSymbol & Equatable<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    func UseValue(v : V) : Wire<V, G>
    func MakeSignal(signal : Signal<V>) : InterfacedHypergraph<V, G>
    func MakeSignal(v : V, width : Int64) : InterfacedHypergraph<V, G>
    func UseSignal(signal : Signal<V>) : Wire<V, G>
    func UseSignal(v : V, width: Int64) : Wire<V, G>
    func UseGate(prim : G, inputs : Array<Wire<V, G>>) : Wire<V, G>
    func UseUnaryGate(prim : G, input : Wire<V, G>) : Wire<V, G>
    func UseBinaryGate(prim : G, a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G>
    func UseJoin(a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G>
    func UseBlackbox(
        name : String,
        domain : Array<Port<V>>,
        codomain : Array<Port<V>>,
        inputs: Array<Wire<V, G>>
    ) : Array<Wire<V, G>>
}
extend Signature<V, G> <: FundamentalBuilder<V, G> {
    /**
    * Use a value
    *
    * @param v The value to use
    * @return The output of the value
    */
    public func UseValue(v : V) : Wire<V, G> {
        UseEdgeWithNewOutputs<V, G, Vertex<V, G>>(
            Label<V, G>.VALUE(v),
            Array<Vertex<V, G>>(),
            None<InterfacedHypergraph<V, G>>
        )[0]
    }
    /**
    * Make a subcircuit containing a signal
    *
    * @param spec The signal
    * @return The circuit containing the signal
    */
    public func MakeSignal(spec : Signal<V>) : InterfacedHypergraph<V, G> {
        let vs = spec.values
        let wires = map(
            { v : V =>
                UseEdgeWithNewOutputs(
                    Label<V, G>.VALUE(v),
                    Array<Vertex<V, G>>(),
                    None<InterfacedHypergraph<V, G>>
                )[0]
            },
            vs
        )
        MakeSubcircuit(
            Array<InterfaceWire<V, G>>(),
            [InterfaceWire(Combine(wires))],
            SIGNAL(spec)
        )
    }
    /**
    * Make a subcircuit containing a a signal defined as multiple copies of a single value
    *
    * @param v The value
    * @param width The width of the signal
    * @return The output wire
    */
    public func MakeSignal(v : V, width : Int64) : InterfacedHypergraph<V, G> {
        let signal = Signal(Array<V>(width){ i : Int64 => v })
        this.MakeSignal(signal)
    }
    /**
    * Use a signal
    *
    * @param spec The signal to use
    * @return The output of the signal circuit
    */
    public func UseSignal(spec : Signal<V>) : Wire<V, G> {
        if(spec.GetWidth() == 1) {
            UseValue(spec.values[0])
        } else {
            this.UseSubcircuit_1(
                this.MakeSignal(spec),
                Array<Wire<V, G>>()
            )
        }
    }
    /**
    * Use a signal cosntructed as multiple copies of a single value
    *
    * @param v The value to use
    * @param i The number of this value to use
    * @return The output of the signal circuit
    */
    public func UseSignal(v : V, i : Int64) : Wire<V, G> {
        let array : Array<V> = Array<V>(i, {i : Int64 => v})
        this.UseSignal(Signal(array))
    }
    /**
     * Use a primitive gate
     *
     * @param prim The primitive to apply
     * @param inputs The array of inputs
     * @return The output wire of the gate
     */
    func UseOperation(label : Label<V, G>, inputs: Array<Wire<V, G>>) : Wire<V, G> {
        AssertNumberOfWires(inputs, label.GetInputPorts().size)
        UseEdgeWithNewOutputs(
            label,
            inputs,
            None
        )[0]
    }
    /**
    * Use a primitive gate
    *
    * @param prim The primitive to apply
    * @param inputs The input wires
    */
    public func UseGate(prim : G, inputs : Array<Wire<V, G>>) : Wire<V, G> {
        AssertAllWiresWidth(inputs, 1)
        UseOperation(PRIMITIVE(prim), inputs)
    }
    /**
    * Use a unary primitive gate
    *
    * @param prim The primitive to apply
    * @param a The input wire
    * @return The output wire of the gate
    */
    public func UseUnaryGate(prim : G, a : Wire<V, G>) : Wire<V, G> {
        UseGate(prim, [a])
    }
    /**
    * Use a binary primitive gate
    *
    * @param prim The primitive to apply
    * @param a The first input wire
    * @param a The second input wire
    * @return The output wire of the gate
    */
    public func UseBinaryGate(prim : G, a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G> {
        UseGate(prim, [a,b])
    }
    /**
    * Use a join operation on two wires
    *
    * @param a The first wire
    * @param b The second wire
    * @return The output of the join
    */
    public func UseJoin(a : Wire<V, G>, b : Wire<V, G>) : Wire<V, G> {
        UseOperation(JOIN(a.GetWidth()), [a, b])
    }
    /**
     * Use a blackbox, a component that we can't look inside
     *
     * @param name The name of the blackbox
     * @param domain The ports of the inputs
     * @param codomain The ports of the outputs
     * @param inputs The input wires
     * @return The array of outputs of this blackbox
     */
    public func UseBlackbox(
        name : String,
        domain : Array<Port<V>>,
        codomain : Array<Port<V>>,
        inputs: Array<Wire<V, G>>
    ) : Array<Wire<V, G>> {
        UseEdgeWithNewOutputs<V, G, Wire<V, G>>(
            Label<V,G>.BLACKBOX(
                Specification<V>(
                    name,
                    domain,
                    codomain
                )
            ),
            inputs,
            None<InterfacedHypergraph<V, G>>
        )
    }
}