/**
 * signatures/gate/flipflop.cj
 *
 * Some example flip flops in the Belnap circuit
 *
 * @author George Kaye
 * @since 0.3
 */
package signatures.gate
/**
 * Make a SR NAND latch
 *
 * @param delay
 * @return The SR NAND latch
 */
public func MakeSRLatch(
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
        "sr_latch"
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
public func UseSRLatch(
    s!: BelnapWire, r!: BelnapWire, delay1!: Int64 = 0, delay2!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeSRLatch(delay1: delay1, delay2: delay2), [s, r])
}
/**
 * Make a D flip flop, using SR NAND latches
 *
 * @param delay
 * @return The D flip flop
 */
public func MakeDFlipFlop(delay!: Int64 = 0) : BelnapInterfacedCircuit {
    let clock = belnapSignature.UseWire(1)
    let data = belnapSignature.UseWire(1)
    let fromBottom = belnapSignature.UseWire(1)
    let (_, topLatchQBar) = UseSubcircuit_2(
        MakeSRLatch(),
        [fromBottom, clock],
    )
    let fromTop = UseNand(topLatchQBar, clock)
    let (botLatchQ, botLatchQBar) = UseSubcircuit_2(
        MakeSRLatch(),
        [fromTop, data],
    )
    Feedback(botLatchQBar, fromBottom)
    let (rightLatchQ, rightLatchQBar) = UseSubcircuit_2(
        MakeSRLatch(),
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
    d!: BelnapWire, clk!: BelnapWire, delay!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(MakeDFlipFlop(delay: delay), [clk, d])
}