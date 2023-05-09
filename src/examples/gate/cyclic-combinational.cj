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
    let muxa = Mux2(sel: c, a: x, b: feedback)
    let muxaWire = if(delays) {
        UseDelay(muxa)
    } else {
        muxa
    }
    let f = UseBlackbox("F", [Port(1, "A")], [Port(1, "Z")], [muxaWire])[0]
    // Bottom half of the circuit
    let muxb = Mux2(sel: c, a: f, b: x)
    let muxbWire = if(delays) {
        UseDelay(muxb)
    } else {
        muxb
    }
    let g = UseBlackbox("G", [Port(1, "A")], [Port(1, "Z")], [muxbWire])[0]
    Feedback(g, feedback)
    // Final multiplexer
    let muxc = Mux2(sel: c, a: g, b: f)
    let muxcWire = if(delays) {
        UseDelay(muxc)
    } else {
        muxc
    }
    MakeSubcircuit(
        [InterfaceWire(x, "x"), InterfaceWire(c, "c")],
        [InterfaceWire(muxcWire, "z")],
        "cyclic_combinational"
    )
}