package circuitcj

import circuitcj.components.{MakeSubcircuit,InterfaceWire,WireUser}
import circuitcj.signatures.gate.{belnapSignature,UseRippleAdder}
import circuitcj.graphs.{Drawable}

main () {

    let sig = belnapSignature

    // Make a circuit that outputs only the sum of a ripple adder
    let a = sig.UseWire(4)
    let b = sig.UseWire(4)
    let c = sig.UseWire(1)

    let (lsbA, msbsA) = a.LsbAndMsbs()
    let (lsbsB, msbB) = b.LsbsAndMsb()

    let (sum, carry) = UseRippleAdder(a: a, b: b, cin: c)
    let circuit = MakeSubcircuit(
        [InterfaceWire(a, "A"), InterfaceWire(b, "B"), InterfaceWire(c, "C")],
        [InterfaceWire(sum, "S")],
        "add"
    )
    circuit.WriteDotToFile("add-0", depth: 0)
    circuit.WriteDotToFile("add-1", depth: 1)
    circuit.WriteDotToFile("add-2", depth: 2)
}