/**
 * examples/cyclic-combinational.cj
 *
 * An example of a cyclic combinational circuit: a
 * circuit that has non-delay-guarded feedback but
 * is still a combinational circuit
 *
 * @author George Kaye
 * @since 0.1
 */
package examples.gate
/**
 * Create a cyclic combinational circuit, either with or without delays.
 *
 * @param delays
 * @param the cyclic combinational circuit
 */
public func CyclicCombinational(delays!: Bool) {
    // Input wires
    let x = sig.UseWire(1)
    let c = sig.UseWire(1)
    // Wire from feedback
    let feedback = sig.UseWire(1)
    // Top half of the circuit
    let muxa = UseMux2(s0: c, i0: x, i1: feedback)
    let muxaWire = if(delays) {
        UseDelay(muxa)
    } else {
        muxa
    }
    let fbb = belnapSignature.AddBlackbox("f", [Port(1, "A")], [Port(1, "Z")])
    let f = UseBlackbox(fbb, [muxaWire])[0]
    // Bottom half of the circuit
    let muxb = UseMux2(s0: c, i0: f, i1: x)
    let muxbWire = if(delays) {
        UseDelay(muxb)
    } else {
        muxb
    }
    let gbb = belnapSignature.AddBlackbox("g", [Port(1, "A")], [Port(1, "Z")])
    let g = UseBlackbox(gbb, [muxbWire])[0]
    Feedback(g, feedback)
    // Final multiplexer
    let muxc = UseMux2(s0: c, i0: g, i1: f)
    let muxcWire = if(delays) {
        UseDelay(muxc)
    } else {
        muxc
    }
    MakeSubcircuit(
        [InterfaceWire(x, "X"), InterfaceWire(c, "C")],
        [InterfaceWire(muxcWire, "Z")],
        "cyclic_combinational"
    )
}