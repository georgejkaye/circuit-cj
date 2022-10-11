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

package examples

public func CyclicCombinational() {
    let x = sig.UseWire(1)
    let c = sig.UseWire(1)

    let bottom = sig.UseWire(1)

    let muxa = Mux2(c, x, bottom)
    let f = BlackBox(
        "F",
        [Port(1, "A")],
        [Port(1, "Z")],
        [muxa]
    )[0]
    let muxb = Mux2(c, f, x)
    let g = BlackBox(
        "G",
        [Port(1, "A")],
        [Port(1, "Z")],
        [muxb]
    )[0]
    Feedback(g, bottom)
    let z = Mux2(c, g, f)
    MakeSubcircuit(
        [InterfaceWire(x, "x"), InterfaceWire(c, "c")],
        [InterfaceWire(z, "z")],
        "cyclic_combinational"
    )
}