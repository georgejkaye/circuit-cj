package signatures.gate

import graphs.*
import components.*

/**
 * Bitwise gate
 */
public func Buf(
    a : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(BUF, [a])[0]
}
public func Not(
    a : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(NOT, [a])[0]
}
public func And(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(AND, [a, b])[0]
}
public func Or(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(OR, [a, b])[0]
}
public func Nand(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(NAND, [a, b])[0]
}
public func Nor(
    a : BelnapWire,
    b : BelnapWire) : BelnapWire {
    UseBitwiseMapGate(NOR, [a, b])[0]
}
public func Xor(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(XOR, [a, b])[0]
}
public func Xnor(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBitwiseMapGate(XNOR, [a, b])[0]
}
public func And(
    ws : Array<BelnapWire>
) : BelnapWire {
    UseRippleGate(AND, ws)[0]
}
public func Or(
    ws : Array<BelnapWire>
) : BelnapWire {
    UseRippleGate(OR, ws)[0]
}
public func Nand(
    ws : Array<BelnapWire>
) : BelnapWire {
    UseRippleGate(NAND, ws)[0]
}
public func Nor(
    ws : Array<BelnapWire>
) : BelnapWire {
    UseRippleGate(NOR, ws)[0]
}
public func Xor(
    ws : Array<BelnapWire>
) : BelnapWire {
    UseRippleGate(XOR, ws)[0]
}
public func Xnor(
    ws : Array<BelnapWire>
) : BelnapWire {
    UseRippleGate(XNOR, ws)[0]
}
public func And(
    w : BelnapWire
) : BelnapWire {
    UseBitwiseRippleGate(AND, [w])[0]
}
public func Or(
    w : BelnapWire
) : BelnapWire {
    UseBitwiseRippleGate(OR, [w])[0]
}
public func Nand(
    w : BelnapWire
) : BelnapWire {
    UseBitwiseRippleGate(NAND, [w])[0]
}
public func Nor(
    w : BelnapWire
) : BelnapWire {
    UseBitwiseRippleGate(NOR, [w])[0]
}
public func Xor(
    w : BelnapWire
) : BelnapWire {
    UseBitwiseRippleGate(XOR, [w])[0]
}
public func Xnor(
    w : BelnapWire
) : BelnapWire {
    UseBitwiseRippleGate(XNOR, [w])[0]
}
/**
 * Create a half adder subcircuit.
 * A half adder takes in two input wires and outputs
 * a sum and carry.
 * @return A half adder subcircuit
 */
public func MakeHalfAdder() : BelnapInterfacedCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
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
    a : BelnapWire,
    b : BelnapWire
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeHalfAdder(), [a, b])
}
/**
 * Create a full adder subcircuit.
 * A full adder takes in two input wires and a carry,
 * and outputs a sum and a new carry.
 * @return A full adder subcircuit
 */
public func MakeFullAdder() : BelnapInterfacedCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let cin = belnapSignature.UseWire(1)
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
    a : BelnapWire,
    b : BelnapWire,
    c : BelnapWire
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeFullAdder(), [a, b, c])
}
/**
 * Create a ripple adder subcircuit for a given width: a circuit that
 * threads a carry through multiple full adders for each bit
 * of the input
 * @param width The width of the input bits
 * @return A ripple adder subcircuit
 */
public func MakeRippleAdder(width : Int64) : BelnapInterfacedCircuit {
    let rippleAdder = belnapSignature.InitCircuit()
    let a = belnapSignature.UseWire(width)
    let b = belnapSignature.UseWire(width)
    let c = belnapSignature.UseWire(1)
    let (sum, carry) = BitwiseRippleMap(
        { acc : BelnapWire, cur : Array<BelnapWire> =>
            let (sum, carry) = FullAdder(cur[0], cur[1], acc)
            (sum, carry)
        },
        c,
        [a, b]
    )
    MakeSubcircuit(
        [
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B"),
            InterfaceWire(c, "Cin")
        ],
        [
            InterfaceWire(sum, "S"),
            InterfaceWire(carry, "Cout")
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
public func UseRippleAdder(
    a : BelnapWire,
    b : BelnapWire,
    c : BelnapWire
) : (BelnapWire, BelnapWire) {
    let width = AssertWiresSameWidth(a, b)
    UseSubcircuit_2(MakeRippleAdder(width), [a, b, c])
}
/**
 * Create a 2-multiplexer subcircuit for inputs of one bit: a circuit
 * that produces one of two outputs depending on a control signal.
 */
func Mux2_1_1() : BelnapInterfacedCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let c = belnapSignature.UseWire(1)
    let z = OrGate(
        AndGate(a, NotGate(c)),
        AndGate(c, b)
    )
    MakeSubcircuit(
        [
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
public func Mux2_1_W(width : Int64) : BelnapInterfacedCircuit {
    let sel = belnapSignature.UseWire(1)
    let a = belnapSignature.UseWire(width)
    let b = belnapSignature.UseWire(width)
    let ctls = Replicate(sel, width)
    let output = BitwiseMap(
        { ws : Array<BelnapWire> => UseSubcircuit(Mux2_1_1(), ws) },
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
    s0: BelnapWire,
    a: BelnapWire,
    b: BelnapWire
) : BelnapWire {
    let width = AssertWiresSameWidth(a, b)
    UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, a, b]
    )
}
/**
 * Create a 4-multiplexer subcircuit for inputs of arbitrary width:
 * a circuit that produces one of four outputs depending on two control signals.
 */
func Mux4_1_W(width: Int64) : BelnapInterfacedCircuit {
    let mux = belnapSignature.InitCircuit()
    let a  = belnapSignature.UseWire(width)
    let b  = belnapSignature.UseWire(width)
    let c  = belnapSignature.UseWire(width)
    let d  = belnapSignature.UseWire(width)
    let s0 = belnapSignature.UseWire(1)
    let s1 = belnapSignature.UseWire(1)
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
    s0: BelnapWire,
    s1: BelnapWire,
    a: BelnapWire,
    b: BelnapWire,
    c: BelnapWire,
    d: BelnapWire
) : BelnapWire {
    let width = AssertWiresSameWidth(a, b)
    AssertWiresSameWidth(b, c)
    AssertWiresSameWidth(c, d)
    UseSubcircuit_1(
        Mux4_1_W(width),
        [s0, s1, a, b, c, d]
    )
}