package signatures.gate

import graphs.*
import components.*

/**
 * Shortcut for the signature
 */
let sig = gateLevelSignature

/**
 * Bitwise gate
 */

public func Buf(
    a : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(BUF, [a])
}
public func Not(
    a : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(NOT, [a])
}
public func And(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(AND, [a, b])
}
public func Or(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(OR, [a, b])
}
public func Nand(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(NAND, [a, b])
}
public func Nor(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(NOR, [a, b])
}
public func Xor(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(XOR, [a, b])
}
public func Xnor(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseBitwiseGate(XNOR, [a, b])
}

public func And(
    ws : Array<Wire<GateLevelValue, GateLevelPrimitive>>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseRippleGate(AND, ws)
}
public func Or(
    ws : Array<Wire<GateLevelValue, GateLevelPrimitive>>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseRippleGate(OR, ws)
}
public func Nand(
    ws : Array<Wire<GateLevelValue, GateLevelPrimitive>>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseRippleGate(NAND, ws)
}
public func Nor(
    ws : Array<Wire<GateLevelValue, GateLevelPrimitive>>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseRippleGate(NOR, ws)
}
public func Xor(
    ws : Array<Wire<GateLevelValue, GateLevelPrimitive>>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseRippleGate(XOR, ws)
}
public func Xnor(
    ws : Array<Wire<GateLevelValue, GateLevelPrimitive>>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseRippleGate(XNOR, ws)
}

public func And(
    w : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseInternalRippleGate(AND, w)
}
public func Or(
    w : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseInternalRippleGate(OR, w)
}
public func Nand(
    w : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseInternalRippleGate(NAND, w)
}
public func Nor(
    w : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseInternalRippleGate(NOR, w)
}
public func Xor(
    w : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseInternalRippleGate(XOR, w)
}
public func Xnor(
    w : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    UseInternalRippleGate(XNOR, w)
}
/**
 * Create a half adder subcircuit.
 * A half adder takes in two input wires and outputs
 * a sum and carry.
 * @return A half adder subcircuit
 */
public func MakeHalfAdder() : InterfacedHypergraph<GateLevelValue, GateLevelPrimitive> {
    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
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
public func HalfAdder(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>
) : (Wire<GateLevelValue, GateLevelPrimitive>, Wire<GateLevelValue, GateLevelPrimitive>) {
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
public func MakeFullAdder() : InterfacedHypergraph<GateLevelValue, GateLevelPrimitive> {
    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let cin = sig.UseWire(1)
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
public func FullAdder(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>,
    c : Wire<GateLevelValue, GateLevelPrimitive>
) : (Wire<GateLevelValue, GateLevelPrimitive>, Wire<GateLevelValue, GateLevelPrimitive>) {
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
public func MakeRippleAdder(width : Int64) : InterfacedHypergraph<GateLevelValue, GateLevelPrimitive> {
    let a = sig.UseWire(width)
    let b = sig.UseWire(width)
    let c = sig.UseWire(1)
    let (sum, carry) = BitwiseRipple(
        { acc : Array<Wire<GateLevelValue, GateLevelPrimitive>>, cur : Array<Wire<GateLevelValue, GateLevelPrimitive>> =>
            let (sum, carry) = FullAdder(acc[0], cur[0], cur[1])
            ([sum], [carry])
        },
        [c],
        [[a], [b]],
        TOP_TO_BOTTOM
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
public func RippleAdder(
    a : Wire<GateLevelValue, GateLevelPrimitive>,
    b : Wire<GateLevelValue, GateLevelPrimitive>,
    c : Wire<GateLevelValue, GateLevelPrimitive>
) : (Wire<GateLevelValue, GateLevelPrimitive>, Wire<GateLevelValue, GateLevelPrimitive>) {
    AssertWiresSameWidth(a, b)
    let width = a.GetWidth()
    AssertWireWidth(c, 1)
    UseSubcircuit_2(MakeRippleAdder(width), [a, b, c])
}
/**
 * Create a 2-multiplexer subcircuit for inputs of one bit: a circuit
 * that produces one of two outputs depending on a control signal.
 */
func Mux2_1_1() : InterfacedHypergraph<GateLevelValue, GateLevelPrimitive> {
    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let c = sig.UseWire(1)
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
public func Mux2_1_W(width : Int64) : InterfacedHypergraph<GateLevelValue, GateLevelPrimitive> {
    let sel = sig.UseWire(1)
    let a = sig.UseWire(width)
    let b = sig.UseWire(width)
    let ctls = Replicate(sel, width)
    let output = Bitwise(
        { ws : Array<Wire<GateLevelValue, GateLevelPrimitive>> => UseSubcircuit(
            Mux2_1_1(),
            ws
        )},
        [ctls, a, b]
    )[0]
    MakeSubcircuit(
        [
            InterfaceWire(sel, "SEL"),
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B")
        ],
        [
            InterfaceWire(output, "Z")
        ],
        "MUX2_1_${width}"
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
public func Mux2(
    s0: Wire<GateLevelValue, GateLevelPrimitive>,
    a: Wire<GateLevelValue, GateLevelPrimitive>,
    b: Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
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
func Mux4_1_W(width: Int64) : InterfacedHypergraph<GateLevelValue, GateLevelPrimitive> {
    let a  = sig.UseWire(width)
    let b  = sig.UseWire(width)
    let c  = sig.UseWire(width)
    let d  = sig.UseWire(width)
    let s0 = sig.UseWire(1)
    let s1 = sig.UseWire(1)
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
    s0: Wire<GateLevelValue, GateLevelPrimitive>,
    s1: Wire<GateLevelValue, GateLevelPrimitive>,
    a: Wire<GateLevelValue, GateLevelPrimitive>,
    b: Wire<GateLevelValue, GateLevelPrimitive>,
    c: Wire<GateLevelValue, GateLevelPrimitive>,
    d: Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
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

/**
 * Use a simple register: a join of some value and a delay
 *
 * @param initial The initial value of the register
 * @param signed Whether the initial value is signed
 * @param input The input to the register
 * @return The output wire of the register
 */
public func SimpleRegister(
    initial! : Int64,
    signed! : Bool,
    input! : Wire<GateLevelValue, GateLevelPrimitive>
) : Wire<GateLevelValue, GateLevelPrimitive> {
    let value = UseSignalFromInt(initial, signed, width: input.GetWidth())
    SimpleRegister(value, input)
}

/**
 * Create a feedback loop guarded by a delay: join a wire to a wire that is
 * not connected to anything on the left, and insert a register with some initial
 * value on the loop
 *
 * @param outgoing The wire to bend back
 * @param incoming The wire to feed back into, must not have an incoming edge
 */
public func RegisterGuardedFeedback<V, G>(
    incoming : Wire<V, G>,
    initial!: Int64,
    signed!: Bool,
    input!: Wire<V, G>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{

}