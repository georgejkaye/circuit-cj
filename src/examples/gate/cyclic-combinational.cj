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

public func CyclicCombinational() {
    let x = sig.UseWire(1)
    let c = sig.UseWire(1)
    let bottom = sig.UseWire(1)
    let muxa = Mux2(c, x, bottom)
    let muxaDelay = sig.UseDelay(muxa)
    let f = sig.UseBlackbox(
        "F",
        [Port(1, "A")],
        [Port(1, "Z")],
        [muxaDelay]
    )[0]
    let muxb = Mux2(c, f, x)
    let muxbDelay = sig.UseDelay(muxb)
    let g = sig.UseBlackbox(
        "G",
        [Port(1, "A")],
        [Port(1, "Z")],
        [muxbDelay]
    )[0]
    sig.Feedback(g, bottom)
    let muxc = Mux2(c, g, f)
    let muxcDelay = sig.UseDelay(muxc)
    sig.MakeSubcircuit(
        [InterfaceWire(x, "x"), InterfaceWire(c, "c")],
        [InterfaceWire(muxcDelay, "z")],
        "cyclic_combinational"
    )
}