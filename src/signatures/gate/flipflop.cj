/**
 * signatures/gate/flipflop.cj
 *
 * Some example flip flops in the Belnap circuit
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
public func MakeSRNorLatch(
    delay1!: Int64 = 0, delay2!: Int64 = 0
) : BelnapInterfacedCircuit {
    let r = belnapSignature.UseWire(1)
    let s = belnapSignature.UseWire(1)
    let fb = belnapSignature.UseWire(1)
    let topNor = UseNor(r, fb, delay: delay1)
    let botNor = UseNor(topNor, s, delay: delay2)
    Feedback(botNor, fb)
    MakeSubcircuit(
        [InterfaceWire(r, "R"), InterfaceWire(s, "S")],
        [InterfaceWire(topNor, "Q"), InterfaceWire(botNor, "Q'")],
        "sr_nor_latch"
    )
}
public func UseSRNorLatch(
    r!: BelnapWire, s!: BelnapWire, delay1!: Int64 = 0, delay2!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeSRNorLatch(delay1: delay1, delay2: delay2), [r, s])
}
/**
 * Make a SR NAND latch
 *
 * @param delay
 * @return The SR NAND latch
 */
public func MakeSRNandLatch(
    delay1!: Int64 = 0, delay2!: Int64 = 0
) : BelnapInterfacedCircuit {
    let s = belnapSignature.UseWire(1)
    let r = belnapSignature.UseWire(1)
    let fb = belnapSignature.UseWire(1)
    let topNand = UseNand(s, fb, delay: delay1)
    let botNand = UseNand(topNand, r, delay: delay2)
    Feedback(botNand, fb)
    MakeSubcircuit(
        [InterfaceWire(s, "S'"), InterfaceWire(r, "R'")],
        [InterfaceWire(topNand, "Q"), InterfaceWire(botNand, "Q'")],
        "sr_nand_latch"
    )
}
/**
 * Use a SR NAND latch
 *
 * @param s
 * @param r
 * @param delay
 * @return (Q, ¬Q)
 */
public func UseSRNandLatch(
    s!: BelnapWire, r!: BelnapWire, delay1!: Int64 = 0, delay2!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeSRNandLatch(delay1: delay1, delay2: delay2), [s, r])
}
/**
 * Make a gated SR NAND latch
 *
 * @param delay1 The delay of the top NAND of the 'gate' part of the circuit
 * @param delay2 The delay of the bottom NAND of the 'gate' part of the circuit
 * @param delay3 The delay of the top NAND of the 'latch' part of the circuit
 * @param delay4 The delay of the bottom NAND of the 'latch' part of the circuit
 * @return The gated SR NAND latch
 */
public func MakeGatedSRNandLatch(
    delay1!: Int64 = 0, delay2!: Int64 = 0, delay3!: Int64 = 0,
    delay4!: Int64 = 0
) : BelnapInterfacedCircuit {
    let s = belnapSignature.UseWire(1)
    let e = belnapSignature.UseWire(1)
    let r = belnapSignature.UseWire(1)
    let nand1 = UseNand(s, e, delay: delay1)
    let nand2 = UseNand(e, r, delay: delay2)
    let (q, qprime) = UseSRNandLatch(
        s: nand1, r: nand2, delay1: delay3, delay2: delay4
    )
    MakeSubcircuit(
        [InterfaceWire(s, "S"), InterfaceWire(e, "E"), InterfaceWire(r, "R")],
        [InterfaceWire(q, "Q"), InterfaceWire(qprime, "Q'")],
        "clocked_sr_nand_flipflop"
    )
}
/**
 * Use a gated SR NAND latch
 *
 * @param s
 * @param e
 * @param r
 * @param delay1 The delay of the top NAND of the 'gate' part of the circuit
 * @param delay2 The delay of the bottom NAND of the 'gate' part of the circuit
 * @param delay3 The delay of the top NAND of the 'latch' part of the circuit
 * @param delay4 The delay of the bottom NAND of the 'latch' part of the circuit
 * @return (q, qprime)
 */
public func UseGatedSRNandLatch(
    s!: BelnapWire, e!: BelnapWire, r!: BelnapWire, delay1!: Int64 = 0,
    delay2!: Int64 = 0, delay3!: Int64 = 0, delay4!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(
        MakeGatedSRNandLatch(
            delay1: delay1, delay2: delay2, delay3: delay3, delay4: delay4
        ),
        [s, e, r]
    )
}
/**
 * Make a D flip flop, using SR NAND latches
 *
 * @param delay
 * @return The D flip flop
 */
public func MakeDFlipFlop(
    delay1!: Int64 = 0, delay2!: Int64 = 0, delay3!: Int64 = 0,
    delay4!: Int64 = 0, delay5!: Int64 = 0, delay6!: Int64 = 0,
    delay7!: Int64 = 0
) : BelnapInterfacedCircuit {
    let clock = belnapSignature.UseWire(1)
    let data = belnapSignature.UseWire(1)
    let fromBottom = belnapSignature.UseWire(1)
    let (_, topLatchQBar) = UseSubcircuit_2(
        MakeSRNandLatch(delay1: delay1, delay2: delay2),
        [fromBottom, clock],
    )
    let fromTop = UseNand(topLatchQBar, clock, delay: delay3)
    let (botLatchQ, botLatchQBar) = UseSubcircuit_2(
        MakeSRNandLatch(delay1: delay4, delay2: delay5),
        [fromTop, data],
    )
    Feedback(botLatchQBar, fromBottom)
    let (rightLatchQ, rightLatchQBar) = UseSubcircuit_2(
        MakeSRNandLatch(delay1: delay6, delay2: delay7),
        [topLatchQBar, botLatchQ],
    )
    MakeSubcircuit([
            InterfaceWire(clock, "Clk"),
            InterfaceWire(data, "D")
        ], [
            InterfaceWire(rightLatchQ, "Q"),
            InterfaceWire(rightLatchQBar, "Q\u{0305}")
        ],
        "D_flipflop"
    )
}
/**
 * Use a D flip flop with SR NAND latches
 *
 * @param d
 * @param clk
 * @param delay
 * @return (Q, ¬Q)
 */
public func UseDFlipFlop(
    d!: BelnapWire, clk!: BelnapWire, delay1!: Int64 = 0, delay2!: Int64 = 0,
    delay3!: Int64 = 0, delay4!: Int64 = 0, delay5!: Int64 = 0,
    delay6!: Int64 = 0, delay7!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(
        MakeDFlipFlop(
            delay1: delay1, delay2: delay2, delay3: delay3, delay4: delay4,
            delay5: delay5, delay6: delay6, delay7: delay7
        ), [clk, d]
    )
}