/**
 * signatures/gate/
 *
 * Primitives and composites for the belnap signature
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
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
    MakeBitwiseRippleMap(
        MakeFullAdder(), acc: 1, ops: width, name: "ripple_adder"
    )
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
    a!: BelnapWire,
    b!: BelnapWire,
    cin!: BelnapWire
) : (BelnapWire, BelnapWire) {
    let width = AssertBothSameWidth(a, b)
    AssertHasWidth(cin, 1)
    UseSubcircuit_2(MakeRippleAdder(width), [cin, a, b])
}
/**
 * Create a 2-multiplexer subcircuit for inputs of one bit.
 */
func MakeMux2_1() : BelnapInterfacedCircuit {
    let a = belnapSignature.UseWire(1)
    let b = belnapSignature.UseWire(1)
    let c = belnapSignature.UseWire(1)
    let z = UseOr(
        UseAnd(a, UseNot(c)),
        UseAnd(c, b)
    )
    MakeSubcircuit(
        [
            InterfaceWire(c, "S0"), InterfaceWire(a, "I0"),
            InterfaceWire(b, "I1")
        ],
        [
            InterfaceWire(z, "Z")
        ],
        "MUX2_1"
    )
}
/**
 * Create a 2-multiplexer subcircuit for inputs of arbitrary widths.
 *
 * @param width
 * @return The multiplexer
 */
public func MakeMux2(width!: Int64) : BelnapInterfacedCircuit {
    AssertStrictlyPositive(width)
    if(width == 1) {
        MakeMux2_1()
    } else {
        MakeBitwiseMap(
           MakeMux2(width: 1), numberOfOperations: width,
           sharedInputWires: HashSet(0), name: "MUX2_${width}"
        )
    }

}
/**
 * Apply a 2-multiplexer. The width is determined from the input wires.
 *
 * @param sel Input SEL0 (1)
 * @param a Input A (w)
 * @param b Input B (w)
 * @return Output Z (w)
 */
public func UseMux2(
    s0!: BelnapWire, i0!: BelnapWire, i1!: BelnapWire
) : BelnapWire {
    let width = AssertBothSameWidth(i0, i1)
    UseSubcircuit_1(MakeMux2(width: width), [s0, i0, i1])
}
/**
 * Create a 4-multiplexer subcircuit for inputs of arbitrary width:
 * a circuit that produces one of four outputs depending on two control signals.
 *
 * @param width
 */
func MakeMux4(width!: Int64) : BelnapInterfacedCircuit {
    let a  = belnapSignature.UseWire(width)
    let b  = belnapSignature.UseWire(width)
    let c  = belnapSignature.UseWire(width)
    let d  = belnapSignature.UseWire(width)
    let s0 = belnapSignature.UseWire(1)
    let s1 = belnapSignature.UseWire(1)
    let m1 = UseMux2(s0: s0, i0: a, i1: b)
    let m2 = UseMux2(s0: s0, i0: c, i1: d)
    let m3 = UseMux2(s0: s1, i0: m1, i1: m2)
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
public func UseMux4(
    s0!: BelnapWire, s1!: BelnapWire,
    i0!: BelnapWire, i1!: BelnapWire, i2!: BelnapWire, i3!: BelnapWire
) : BelnapWire {
    let width = AssertBothSameWidth(i0, i1)
    AssertBothSameWidth(i1, i2)
    AssertBothSameWidth(i2, i3)
    UseSubcircuit_1(MakeMux4(width: width), [s0, s1, i0, i1, i2, i3])
}
public func MakeMux(
    inputs!: Int64, width!: Int64
) : BelnapInterfacedCircuit {
    if(inputs == 2) {
        MakeMux2(width: width)
    } else {
        // The number of control wires is the solution of inputs = 2^x
        let numberOfControlWires = AssertPowerOf(inputs, 2)
        // All but one of these control wires is used in the recursive subcall
        let numberOfControlWiresPerSubcall = numberOfControlWires - 1
        let numberOfDataWiresPerSubcall = inputs / 2
        let numberOfInputWiresPerSubcall =
            numberOfControlWiresPerSubcall + numberOfDataWiresPerSubcall
        let controlWires = Array<BelnapWire>(numberOfControlWires, {_ =>
            UseWire<GateLevelValue, GateLevelPrimitive>(1)
        })
        let getSubcallInputs = { =>
            Array<BelnapWire>(numberOfInputWiresPerSubcall, { i =>
                if(i < numberOfControlWiresPerSubcall) {
                    controlWires[i + 1]
                } else {
                    UseWire<GateLevelValue, GateLevelPrimitive>(width)
                }
            })
        }
        let topInputs = getSubcallInputs()
        let botInputs = getSubcallInputs()
        let topHalf = UseMux(topInputs)
        let botHalf = UseMux(botInputs)
        // We select between the two submuxes with a final mux2
        let finalMux = UseMux2(s0: controlWires[0], i0: topHalf, i1: botHalf)
        // The final input wires are [zero, subcontrols, data]
        let totalNumberOfInputWires = numberOfControlWires + inputs
        let totalInputs = Array<BelnapInterfaceWire>(
            totalNumberOfInputWires, { i =>
                if(i < numberOfControlWires) {
                    let controlWireName = "S${i}"
                    InterfaceWire(controlWires[i], controlWireName)
                } else {
                    let dataIndex = i - numberOfControlWires
                    let dataWireName = "I${dataIndex}"
                    if(i < numberOfControlWires + numberOfDataWiresPerSubcall) {
                        let inputIndex =
                            dataIndex + numberOfControlWiresPerSubcall
                        InterfaceWire(
                            topInputs[inputIndex], dataWireName
                        )
                    } else {
                        let inputIndex =
                            dataIndex - numberOfDataWiresPerSubcall +
                                numberOfControlWiresPerSubcall
                        InterfaceWire(botInputs[inputIndex], dataWireName)
                    }
                }
        })
        MakeSubcircuit(
            totalInputs, [BelnapInterfaceWire(finalMux, "Z")],
            "MUX${inputs}_${width}"
        )
    }
}
/**
 * Use a multiplexer, the size of which is determined by an array of input wires
 *
 * @param inputs
 * @return The multiplexer circuit
 */
func UseMux(inputs: Array<BelnapWire>) : BelnapWire {
    let exponent = Int64(floor(log(Float64(inputs.size)) / log(2.0)))
    let choices = inputs.size - exponent
    let width = AssertAllElementsHaveSameWidth(inputs, start: exponent)
    UseSubcircuit_1<GateLevelValue, GateLevelPrimitive>(
        MakeMux(inputs: choices, width: width), inputs
    )
}
/**
 * Use a multiplexer, the size of which is determined by an array of input wires
 *
 * @param selectors
 * @param inputs
 * @return The multiplexer circuit
 */
public func UseMux(
    selectors!: Array<BelnapWire>, inputs!: Array<BelnapWire>
) : BelnapWire {
    UseMux(concat(selectors, inputs))
}
/**
 * Use a multiplexer, the size of which is determined by an array of input wires
 *
 * @param selector
 * @param inputs
 * @return The multiplexer circuit
 */
public func UseMux(
    selector!: BelnapWire, inputs!: Array<BelnapWire>
) : BelnapWire {
    UseMux(selectors: [selector], inputs: inputs)
}