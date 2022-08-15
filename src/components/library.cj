/**
 * components/library.cj
 *
 * Common circuit components
 *
 * @author George Kaye
 * @since 0.2
 */

package components

/**
 * Use a blackbox, a component that we can't look inside
 *
 * @param name The name of the blackbox
 * @param domain The ports of the inputs
 * @param codomain The ports of the outputs
 * @param inputs The input wires
 * @return The array of outputs of this blackbox
 */
public func BlackBox(
    name : String,
    domain : Array<Port>,
    codomain : Array<Port>,
    inputs: Array<Wire>
) : Array<Wire> {
    MakeEdgeWithNewOutputs<Wire, Port>(
        BLACKBOX(
            Specification(
                name,
                domain,
                codomain
            )
        ),
        inputs,
        codomain,
        None<InterfacedHypergraph>
    )
}

/**
 * Bitwise gates
 */

public func Buf(a : Wire) : Wire {
    UseBitwiseGate(BUF, [a])
}
public func Not(a : Wire) : Wire {
    UseBitwiseGate(NOT, [a])
}
public func And(a : Wire, b : Wire) : Wire {
    UseBitwiseGate(AND, [a, b])
}
public func Or(a : Wire, b : Wire) : Wire {
    UseBitwiseGate(OR, [a, b])
}
public func Nand(a : Wire, b : Wire) : Wire {
    UseBitwiseGate(NAND, [a, b])
}
public func Nor(a : Wire, b : Wire) : Wire {
    UseBitwiseGate(NOR, [a, b])
}
public func Xor(a : Wire, b : Wire) : Wire {
    UseBitwiseGate(XOR, [a, b])
}
public func Xnor(a : Wire, b : Wire) : Wire {
    UseBitwiseGate(XNOR, [a, b])
}

/**
 * Ripple gates
 */

public func And(ws : Array<Wire>) : Wire {
    UseRippleGate(AND, ws)
}
public func Or(ws : Array<Wire>) : Wire {
    UseRippleGate(OR, ws)
}
public func Nand(ws : Array<Wire>) : Wire {
    UseRippleGate(NAND, ws)
}
public func Nor(ws : Array<Wire>) : Wire {
    UseRippleGate(NOR, ws)
}
public func Xor(ws : Array<Wire>) : Wire {
    UseRippleGate(XOR, ws)
}
public func Xnor(ws : Array<Wire>) : Wire {
    UseRippleGate(XNOR, ws)
}

/**
 * Internal ripple gates
 */

public func And(w : Wire) : Wire {
    UseInternalRippleGate(AND, w)
}
public func Or(w : Wire) : Wire {
    UseInternalRippleGate(OR, w)
}
public func Nand(w : Wire) : Wire {
    UseInternalRippleGate(NAND, w)
}
public func Nor(w : Wire) : Wire {
    UseInternalRippleGate(NOR, w)
}
public func Xor(w : Wire) : Wire {
    UseInternalRippleGate(XOR, w)
}
public func Xnor(w : Wire) : Wire {
    UseInternalRippleGate(XNOR, w)
}

/**
 * Create a half adder subcircuit.
 * A half adder takes in two input wires and outputs
 * a sum and carry.
 * @return A half adder subcircuit
 */
public func MakeHalfAdder() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let s = XorGate(a, b)
    let c = AndGate(a, b)
    MakeSubcircuit(
        [
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B")
        ],
        [
            InterfaceWire(s, "S"),
            InterfaceWire(c, "C")
        ],
        "half_adder"
    )
}
/**
 * Apply a half adder.
 * @param a Input A (1)
 * @param b Input B (1)
 * @return (Output S (1), Output C (1))
 */
public func HalfAdder(a : Wire, b : Wire) : (Wire, Wire) {
    AssertWireWidth(a, 1)
    AssertWireWidth(b, 1)
    UseSubcircuit_2(MakeHalfAdder(), [a, b])
}
/**
 * Create a full adder subcircuit.
 * A full adder takes in two input wires and a carry,
 * and outputs a sum and a new carry.
 * @return A full adder subcircuit
 */
public func MakeFullAdder() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let cin = MakeWire(1)
    let inputXor = XorGate(a, b)
    let carryXor = XorGate(inputXor, cin)
    let carryAnd = AndGate(inputXor, cin)
    let inputAnd = AndGate(a, b)
    let carryOr = OrGate(carryAnd, inputAnd)
    MakeSubcircuit(
        [
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B"),
            InterfaceWire(cin, "Cin")
        ],
        [
            InterfaceWire(carryXor, "S"),
            InterfaceWire(carryOr, "Cout")
        ],
        "full_adder"
    )
}
/**
 * Apply a full adder.
 * @param a Input A (1)
 * @param b Input B (1)
 * @param c Input Cin (1)
 * @return (Output S (1), Output Cout (1))
 */
public func FullAdder(a : Wire, b : Wire, c : Wire) : (Wire, Wire) {
    AssertWireWidth(a, 1)
    AssertWireWidth(b, 1)
    AssertWireWidth(c, 1)
    UseSubcircuit_2(MakeFullAdder(), [a, b])
}
/**
 * Create a ripple adder subcircuit for a given width: a circuit that
 * threads a carry through multiple full adders for each bit
 * of the input
 * @param width The width of the input bits
 * @return A ripple adder subcircuit
 */
public func MakeRippleAdder(width : Int64) : InterfacedHypergraph {
    let a = MakeWire(width)
    let b = MakeWire(width)
    let c = MakeWire(1)
    let (sum, carry) = Bitwise<Wire, Wire>(
        [a, b],
        Array<Wire>(),
        [c],
        {
            ws : Array<Wire>, ctl : Array<Wire>, aux : Array<Wire> =>
                let (s, cout) = UseSubcircuit_2(
                    MakeFullAdder(),
                    [ws[0], ws[1], aux[0]]
                )
                ([s], [cout])
        }
    )
    MakeSubcircuit(
        [
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B"),
            InterfaceWire(c, "Cin")
        ],
        [
            InterfaceWire(sum[0], "S"),
            InterfaceWire(carry[0], "Cout")
        ],
        "ripple_adder"
    )
}
/**
 * Apply a ripple adder. The width is determined from
 * the first two input wires.
 * @param a Input A (w)
 * @param b Input B (w)
 * @param c Input Cin (1)
 * @return (Output S (w), Output Cout (1))
 */
public func RippleAdder(a : Wire, b : Wire, c : Wire) : (Wire, Wire) {
    AssertWiresSameWidth(a, b)
    let width = a.GetWidth()
    AssertWireWidth(c, 1)
    UseSubcircuit_2(MakeRippleAdder(width), [a, b, c])
}
/**
 * Create a 2-multiplexer subcircuit for inputs of one bit: a circuit
 * that produces one of two outputs depending on a control signal.
 */
func Mux2_1_1() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let c = MakeWire(1)
    let z = OrGate(
        AndGate(a, NotGate(c)),
        AndGate(c, b)
    )
    MakeSubcircuit([
            InterfaceWire(c, "SEL"),
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B")
        ],
        [
            InterfaceWire(z, "Z")
        ],
        "mux2_1_1"
    )
}
/**
 * Create a 2-multiplexer subcircuit for inputs of arbitrary width:
 * a circuit that produces one of two outputs depending on a control signal.
 */
public func Mux2_1_W(width : Int64) : InterfacedHypergraph {
    let sel = InterfaceWire(1, "SEL")
    let a = InterfaceWire(width, "A")
    let b = InterfaceWire(width, "B")
    let output = Bitwise(
        [a, b],
        [sel],
        Array<Wire>(),
        { ws : Array<Wire>, ctl : Array<InterfaceWire>, aux : Array<Wire> =>
            (
                UseSubcircuit<Wire>(
                    Mux2_1_1(),
                    [ctl[0].GetWire(), ws[0], ws[1]]
                ),
                aux
            )
        }
    )[0][0]
    MakeSubcircuit(
        [sel, a, b],
        [InterfaceWire(output, "Z")],
        GetMuxName(2, 1, width)
    )
}
/**
 * Apply a 2-multiplexer. The width is determined from the
 * input wires.
 * @param s0 Input SEL0 (1)
 * @param a Input A (w)
 * @param b Input B (w)
 * @return Output Z (w)
 */
public func Mux2(s0: Wire, a: Wire, b: Wire) : Wire {
    AssertWireWidth(s0, 1)
    AssertWiresSameWidth(a, b)
    let width = a.GetWidth()
    UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, a, b]
    )
}
/**
 * Create a 4-multiplexer subcircuit for inputs of arbitrary width:
 * a circuit that produces one of four outputs depending on two control signals.
 */
func Mux4_1_W(width: Int64) : InterfacedHypergraph {
    let a  = Wire(width)
    let b  = Wire(width)
    let c  = Wire(width)
    let d  = Wire(width)
    let s0 = Wire(1)
    let s1 = Wire(1)
    let m1 = UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, a, b]
    )
    let m2 = UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, c, d]
    )
    let m3 = UseSubcircuit_1(
        Mux2_1_W(width),
        [s1, m1, m2]
    )
    MakeSubcircuit(
        [
            InterfaceWire(s0, "SEL0"),
            InterfaceWire(s1, "SEL1"),
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B"),
            InterfaceWire(c, "C"),
            InterfaceWire(d, "D")
        ],
        [
            InterfaceWire(m3, "Z")
        ],
        "mux4_1_${width}"
    )
}
/**
 * Apply a 4-multiplexer. The width is determined from the
 * input wires.
 * @param s0 Input SEL0 (1)
 * @param s1 Input SEL1 (1)
 * @param a Input A (w)
 * @param b Input B (w)
 * @param c Input C (w)
 * @param d Input D (w)
 * @return Output Z (w)
 */
public func Mux4(
    s0: Wire,
    s1: Wire,
    a: Wire,
    b: Wire,
    c: Wire,
    d: Wire
) : Wire {
    AssertWireWidth(s0, 1)
    AssertWireWidth(s1, 1)
    AssertWiresSameWidth(a, b)
    AssertWiresSameWidth(b, c)
    AssertWiresSameWidth(c, d)
    let width = a.GetWidth()
    UseSubcircuit_1(
        Mux4_1_W(width),
        [s0, s1, a, b, c, d]
    )
}