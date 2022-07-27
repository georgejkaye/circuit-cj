package components

import prelude.*
import syntax.*

public func Adder(a : Wire, b : Wire) : Wire {
    let width = a.GetWidth()
    if (width != b.GetWidth()) {
        throw WiresNotAllSameWidthException("Adder", width, b)
    }
    BlackBox(
        "adder", 
        [
            Port(width, name: "A"),
            Port(width, name: "B")
        ], [
            Port(width, name: "SUM")
        ],
        [a, b]
    )[0]
}

public func HalfAdder() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let s = XorGate(a, b)
    let c = AndGate(a, b)
    MakeSubcircuit(
        [NamedWire(a, "A"), NamedWire(b, "B")],
        [NamedWire(s, "S"), NamedWire(c, "C")],
        name: "half_adder"
    )
}

public func FullAdder() : InterfacedHypergraph {
    let a = MakeWire(1)
    let b = MakeWire(1)
    let cin = MakeWire(1)
    let inputXor = XorGate(a, b)
    let carryXor = XorGate(inputXor, cin)
    let carryAnd = AndGate(inputXor, cin)
    let inputAnd = AndGate(a, b)
    let carryOr = OrGate(carryAnd, inputAnd)
    MakeSubcircuit(
        [NamedWire(a, "A"), NamedWire(b, "B"), NamedWire(cin, "Cin")],
        [NamedWire(carryXor, "S"), NamedWire(carryOr, "Cout")],
        name: "full_adder"
    )
}

public func RippleAdder(width : Int64) : InterfacedHypergraph {
    let a = MakeWire(width)
    let b = MakeWire(width)
    let c = MakeWire(1)
    let (s, cout) = Bitwise([a, b], {
        ws : Array<Wire>, carry : Wire =>
            UseSubcircuit_2(FullAdder(), [ws[0], ws[1], carry])
    }, c)
    MakeSubcircuit(
        [NamedWire(a, "A"), NamedWire(b, "B"), NamedWire(c, "Cin")],
        [NamedWire(s, "S"), NamedWire(cout, "Cout")],
        name: "ripple_adder"
    )
}

public func RippleAdder(a : Wire, b : Wire, c : Wire) : (Wire, Wire) {
    AssertWiresSameWidth(a, b)
    AssertWireWidth(c, 1)
    UseSubcircuit_2(RippleAdder(a.GetWidth()), [a, b, c])
}

public func Plus(a : Wire, b : Wire) : (Wire, Wire) {
    RippleAdder(a, b, InfiniteWaveform(False))
}
public func Subtract(a : Wire, b : Wire) : (Wire, Wire) {
    AssertWiresSameWidth(a, b)
    let carry = InfiniteWaveform(True)
    let xor = XorGate(b, carry)
    RippleAdder(a, xor, carry)
}