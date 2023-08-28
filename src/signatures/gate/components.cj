/**
 * signatures/gate/components
 *
 * Primitives and composites for the belnap signature
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
import graphs.*
import components.*
import components.constructions.*
public func UseBufGate(
    a : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseUnaryPrimitive(BUF, a, delay: delay)[0]
}
public func UseNotGate(
    a : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseUnaryPrimitive(NOT, a, delay: delay)[0]
}
public func UseAndGate(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBinaryPrimitive(AND, a, b, delay: delay)[0]
}
public func UseOrGate(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBinaryPrimitive(OR, a, b, delay: delay)[0]
}
public func UseNandGate(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBinaryPrimitive(NAND, a, b, delay: delay)[0]
}
public func UseNorGate(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBinaryPrimitive(NOR, a, b, delay: delay)[0]
}
public func UseXorGate(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBinaryPrimitive(XOR, a, b, delay: delay)[0]
}
public func UseXnorGate(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBinaryPrimitive(XNOR, a, b, delay: delay)[0]
}
/**
* Perform an unsigned extension on a wire, i.e. add a false as its msb
* @param w The input wire
* @return The wire with an extra bit
*/
public func UnsignedExtend(
    w : BelnapWire
) : BelnapWire {
    let waveform = belnapSignature.UseConstantZero(width: 1)
    Combine([waveform, w])
}
/**
 * Bitwise gate
 */
public func UseBuf(
    a : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(BUF, [a], delay: delay)[0]
}
public func UseNot(
    a : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(NOT, [a], delay: delay)[0]
}
public func UseAnd(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(AND, [a, b], delay: delay)[0]
}
public func UseOr(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(OR, [a, b], delay: delay)[0]
}
public func UseNand(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(NAND, [a, b], delay: delay)[0]
}
public func UseNor(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(NOR, [a, b], delay: delay)[0]
}
public func UseXor(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(XOR, [a, b], delay: delay)[0]
}
public func UseXnor(
    a : BelnapWire, b : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseMapPrimitive(XNOR, [a, b], delay: delay)[0]
}
public func UseAnd(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(AND, ws, delay: delay)[0]
}
public func UseOr(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(OR, ws, delay: delay)[0]
}
public func UseNand(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(NAND, ws, delay: delay)[0]
}
public func UseNor(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(NOR, ws, delay: delay)[0]
}
public func UseXor(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(XOR, ws, delay: delay)[0]
}
public func UseXnor(
    ws : Array<BelnapWire>, delay!: Int64 = 0
) : BelnapWire {
    UseRippleBinaryPrimitive(XNOR, ws, delay: delay)[0]
}
public func UseAnd(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(AND, [w], delay: delay)
}
public func UseOr(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(OR, [w], delay: delay)
}
public func UseNand(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(NAND, [w], delay: delay)
}
public func UseNor(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(NOR, [w], delay: delay)
}
public func UseXor(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(XOR, [w], delay: delay)
}
public func UseXnor(
    w : BelnapWire, delay!: Int64 = 0
) : BelnapWire {
    UseBitwiseRippleBinaryPrimitive(XNOR, [w], delay: delay)
}
/**
 * Create a half adder subcircuit.
 * A half adder takes in two input wires and outputs
 * a sum and carry.
 *
 * @return A half adder subcircuit
 */
public func MakeHalfAdder() : BelnapInterfacedCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let s = UseXor(a, b)
    let c = UseAnd(a, b)
    MakeSubcircuit(
        [InterfaceWire(a, "A"), InterfaceWire(b, "B")],
        [InterfaceWire(s, "S"), InterfaceWire(c, "C")],
        "half_adder"
    )
}
/**
 * Apply a half adder.
 *
 * @param a Input A (1)
 * @param b Input B (1)
 * @return (Output S (1), Output C (1))
 */
public func UseHalfAdder(
    a!: BelnapWire,
    b!: BelnapWire
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeHalfAdder(), [a, b])
}
/**
 * Create a full adder subcircuit.
 * A full adder takes in two input wires and a carry,
 * and outputs a sum and a new carry.
 *
 * @return A full adder subcircuit
 */
public func MakeFullAdder() : BelnapInterfacedCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let cin = belnapSignature.UseWire(1)
    let inputXor = UseXor(a, b)
    let carryXor = UseXor(inputXor, cin)
    let carryAnd = UseAnd(inputXor, cin)
    let inputAnd = UseAnd(a, b)
    let carryOr = UseOr(carryAnd, inputAnd)
    MakeSubcircuit(
        [
            InterfaceWire(cin, "Cin"),
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B")
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
public func UseFullAdder(
    cin! : BelnapWire, a! : BelnapWire, b! : BelnapWire
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeFullAdder(), [cin, a, b])
}
/**
 * Create a ripple adder subcircuit for a given width: a circuit that
 * threads a carry through multiple full adders for each bit
 * of the input
 *
 * @param width The width of the input bits
 * @return A ripple adder subcircuit
 */
public func MakeRippleAdder(width : Int64) : BelnapInterfacedCircuit {
    let cin = belnapSignature.UseWire(1)
    let a = belnapSignature.UseWire(width)
    let b = belnapSignature.UseWire(width)
    MakeBitwiseRippleMap(MakeFullAdder(), 1, width, name: "ripple_adder")
}
/**
 * Apply a ripple adder. The width is determined from
 * the first two input wires.
 *
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
    let width = AssertBothSameWidth(a, b)
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
    let z = UseOr(
        UseAnd(a, UseNot(c)),
        UseAnd(c, b)
    )
    MakeSubcircuit(
        [
            InterfaceWire(c, "SEL"), InterfaceWire(a, "A"),
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
 *
 * @param width
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
            InterfaceWire(sel, "SEL"), InterfaceWire(a, "A"),
            InterfaceWire(b, "B")
        ],
        [
            InterfaceWire(output, "Z")
        ],
        "MUX2_1_${width}"
    )
}
/**
 * Apply a 2-multiplexer. The width is determined from the input wires.
 *
 * @param sel Input SEL0 (1)
 * @param a Input A (w)
 * @param b Input B (w)
 * @return Output Z (w)
 */
public func Mux2(sel!: BelnapWire, a!: BelnapWire, b!: BelnapWire) : BelnapWire {
    let width = AssertBothSameWidth(a, b)
    UseSubcircuit_1(
        Mux2_1_W(width),
        [sel, a, b]
    )
}
/**
 * Create a 4-multiplexer subcircuit for inputs of arbitrary width:
 * a circuit that produces one of four outputs depending on two control signals.
 *
 * @param width
 */
func Mux4_1_W(width: Int64) : BelnapInterfacedCircuit {
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
            InterfaceWire(s0, "SEL0"), InterfaceWire(s1, "SEL1"),
            InterfaceWire(a, "A"), InterfaceWire(b, "B"),
            InterfaceWire(c, "C"),InterfaceWire(d, "D")
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
    s0: BelnapWire, s1: BelnapWire,
    a: BelnapWire, b: BelnapWire, c: BelnapWire, d: BelnapWire
) : BelnapWire {
    let width = AssertBothSameWidth(a, b)
    AssertBothSameWidth(b, c)
    AssertBothSameWidth(c, d)
    UseSubcircuit_1(
        Mux4_1_W(width),
        [s0, s1, a, b, c, d]
    )
}