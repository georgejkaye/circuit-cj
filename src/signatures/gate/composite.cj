package signatures.gate

import graphs.*
import components.*

/**
 * Bitwise gate
 */

public func Buf(
    a : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(BUF, [a])
}
public func Not(
    a : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(NOT, [a])
}
public func And(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(AND, [a, b])
}
public func Or(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(OR, [a, b])
}
public func Nand(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(NAND, [a, b])
}
public func Nor(
    a : BelnapWire,
    b : BelnapWire) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(NOR, [a, b])
}
public func Xor(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(XOR, [a, b])
}
public func Xnor(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseMapGate(XNOR, [a, b])
}

public func And(
    ws : Array<BelnapWire>
) : BelnapWire {
    belnapSignature.UseRippleGate(AND, ws)
}
public func Or(
    ws : Array<BelnapWire>
) : BelnapWire {
    belnapSignature.UseRippleGate(OR, ws)
}
public func Nand(
    ws : Array<BelnapWire>
) : BelnapWire {
    belnapSignature.UseRippleGate(NAND, ws)
}
public func Nor(
    ws : Array<BelnapWire>
) : BelnapWire {
    belnapSignature.UseRippleGate(NOR, ws)
}
public func Xor(
    ws : Array<BelnapWire>
) : BelnapWire {
    belnapSignature.UseRippleGate(XOR, ws)
}
public func Xnor(
    ws : Array<BelnapWire>
) : BelnapWire {
    belnapSignature.UseRippleGate(XNOR, ws)
}

public func And(
    w : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseRippleGate(AND, [w])
}
public func Or(
    w : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseRippleGate(OR, [w])
}
public func Nand(
    w : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseRippleGate(NAND, [w])
}
public func Nor(
    w : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseRippleGate(NOR, [w])
}
public func Xor(
    w : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseRippleGate(XOR, [w])
}
public func Xnor(
    w : BelnapWire
) : BelnapWire {
    belnapSignature.UseBitwiseRippleGate(XNOR, [w])
}
/**
 * Create a half adder subcircuit.
 * A half adder takes in two input wires and outputs
 * a sum and carry.
 * @return A half adder subcircuit
 */
public func MakeHalfAdder() : BelnapCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let s = XorGate(a, b)
    let c = AndGate(a, b)
    belnapSignature.MakeSubcircuit(
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
    AssertWireWidth(a, 1)
    AssertWireWidth(b, 1)
    belnapSignature.UseSubcircuit_2(MakeHalfAdder(), [a, b])
}
/**
 * Create a full adder subcircuit.
 * A full adder takes in two input wires and a carry,
 * and outputs a sum and a new carry.
 * @return A full adder subcircuit
 */
public func MakeFullAdder() : BelnapCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let cin = belnapSignature.UseWire(1)
    let inputXor = XorGate(a, b)
    let carryXor = XorGate(inputXor, cin)
    let carryAnd = AndGate(inputXor, cin)
    let inputAnd = AndGate(a, b)
    let carryOr = OrGate(carryAnd, inputAnd)
    belnapSignature.MakeSubcircuit(
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
    AssertWireWidth(a, 1)
    AssertWireWidth(b, 1)
    AssertWireWidth(c, 1)
    belnapSignature.UseSubcircuit_2(MakeFullAdder(), [a, b, c])
}
/**
 * Create a ripple adder subcircuit for a given width: a circuit that
 * threads a carry through multiple full adders for each bit
 * of the input
 * @param width The width of the input bits
 * @return A ripple adder subcircuit
 */
public func MakeRippleAdder(width : Int64) : BelnapCircuit {
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
    belnapSignature.MakeSubcircuit(
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
    AssertWiresSameWidth(a, b)
    let width = a.GetWidth()
    AssertWireWidth(c, 1)
    belnapSignature.UseSubcircuit_2(MakeRippleAdder(width), [a, b, c])
}
/**
 * Create a 2-multiplexer subcircuit for inputs of one bit: a circuit
 * that produces one of two outputs depending on a control signal.
 */
func Mux2_1_1() : BelnapCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let c = belnapSignature.UseWire(1)
    let z = OrGate(
        AndGate(a, NotGate(c)),
        AndGate(c, b)
    )
    belnapSignature.MakeSubcircuit([
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
public func Mux2_1_W(width : Int64) : BelnapCircuit {
    let sel = belnapSignature.UseWire(1)
    let a = belnapSignature.UseWire(width)
    let b = belnapSignature.UseWire(width)
    let ctls = Replicate(sel, width)
    let output = BitwiseMap(
        { ws : Array<BelnapWire> => belnapSignature.UseSubcircuit(
            Mux2_1_1(),
            ws
        )},
        [ctls, a, b]
    )[0]
    belnapSignature.MakeSubcircuit(
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
    AssertWireWidth(s0, 1)
    AssertWiresSameWidth(a, b)
    let width = a.GetWidth()
    belnapSignature.UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, a, b]
    )
}
/**
 * Create a 4-multiplexer subcircuit for inputs of arbitrary width:
 * a circuit that produces one of four outputs depending on two control signals.
 */
func Mux4_1_W(width: Int64) : BelnapCircuit {
    let a  = belnapSignature.UseWire(width)
    let b  = belnapSignature.UseWire(width)
    let c  = belnapSignature.UseWire(width)
    let d  = belnapSignature.UseWire(width)
    let s0 = belnapSignature.UseWire(1)
    let s1 = belnapSignature.UseWire(1)
    let m1 = belnapSignature.UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, a, b]
    )
    let m2 = belnapSignature.UseSubcircuit_1(
        Mux2_1_W(width),
        [s0, c, d]
    )
    let m3 = belnapSignature.UseSubcircuit_1(
        Mux2_1_W(width),
        [s1, m1, m2]
    )
    belnapSignature.MakeSubcircuit(
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
    AssertWireWidth(s0, 1)
    AssertWireWidth(s1, 1)
    AssertWiresSameWidth(a, b)
    AssertWiresSameWidth(b, c)
    AssertWiresSameWidth(c, d)
    let width = a.GetWidth()
    belnapSignature.UseSubcircuit_1(
        Mux4_1_W(width),
        [s0, s1, a, b, c, d]
    )
}