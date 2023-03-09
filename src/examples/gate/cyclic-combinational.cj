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

public func CyclicCombinational(delays!: Bool) {
    let x = sig.UseWire(1)
    let c = sig.UseWire(1)
    let feedback = sig.UseWire(1)
    let muxa = Mux2(c, x, feedback)
    let muxaWire = if(delays) {
        UseDelay(muxa)
    } else {
        muxa
    }
    let f = UseBlackbox(
        "F",
        [Port(1, "A")],
        [Port(1, "Z")],
        [muxaWire]
    )[0]
    let muxb = Mux2(c, f, x)
    let muxbWire = if(delays) {
        UseDelay(muxb)
    } else {
        muxb
    }
    let g = UseBlackbox(
        "G",
        [Port(1, "A")],
        [Port(1, "Z")],
        [muxbWire]
    )[0]
    Feedback(g, feedback)
    let muxc = Mux2(c, g, f)
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