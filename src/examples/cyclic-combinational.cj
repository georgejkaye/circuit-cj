package examples

public func CyclicCombinational() {
    let x = MakeWire(1)
    let c = MakeWire(1)

    let bottom = MakeWire(1)

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