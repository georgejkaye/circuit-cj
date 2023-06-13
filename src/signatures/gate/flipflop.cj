package signatures.gate

public func SRLatch(delay!: Int64 = 0) : BelnapInterfacedCircuit {
    let s = belnapSignature.UseWire(1)
    let r = belnapSignature.UseWire(1)
    let fb = belnapSignature.UseWire(1)
    let topNand = UseNand(s, fb, delay: delay)
    let botNand = UseNand(topNand, r, delay: delay)
    Feedback(botNand, fb)
    MakeSubcircuit(
        [InterfaceWire(s, "S\u{0305}"), InterfaceWire(r, "R\u{0305}")],
        [InterfaceWire(topNand, "Q"), InterfaceWire(botNand, "Q\u{0305}")],
        "sr_latch"
    )
}

public func DFlipFlop(delay!: Int64 = 0) : BelnapInterfacedCircuit {
    let clock = belnapSignature.UseWire(1)
    let data = belnapSignature.UseWire(1)
    let fromBottom = belnapSignature.UseWire(1)
    let (_, topLatchQBar) = UseSubcircuit_2(
        SRLatch(delay: delay),
        [fromBottom, clock],
    )
    let fromTop = UseNand(topLatchQBar, clock)
    let (botLatchQ, botLatchQBar) = UseSubcircuit_2(
        SRLatch(delay: delay),
        [fromTop, data],
    )
    Feedback(botLatchQBar, fromBottom)
    let (rightLatchQ, rightLatchQBar) = UseSubcircuit_2(
        SRLatch(delay: delay),
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

public func UseDFlipFlop(
    d!: BelnapWire, clk!: BelnapWire, delay!: Int64 = 0
) : (BelnapWire, BelnapWire) {
    UseSubcircuit_2(
        DFlipFlop(delay: delay),
        [clk, d]
    )
}