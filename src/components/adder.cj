package components

import prelude.*
import syntax.*

public func Adder(a : WireEnd, b : WireEnd) : WireEnd {
    let width = a.GetVertex().GetWidth()
    if (width != b.GetVertex().GetWidth()) {
        throw WiresNotAllSameWidthException("Adder", width, b)
    }
    let adderSpec = Specification("adder", [width, width], [width])
    BlackBox(adderSpec, [a, b])[0]
}

public func HalfAdder(a : WireEnd, b : WireEnd) : (WireEnd, WireEnd) {
    if (a.GetVertex().GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", a, 1)
    }
    if (b.GetVertex().GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", b, 1)
    }
    let s = XorGate(a, b)
    let c = AndGate(a, b)
    (s, c)
}

public func FullAdder(a : WireEnd, b : WireEnd, cin : WireEnd) : (WireEnd, WireEnd) {
    if (a.GetVertex().GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", a, 1)
    }
    if (b.GetVertex().GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", b, 1)
    }
    if (cin.GetVertex().GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", cin, 1)
    }
    let xor = XorGate(a, b)
    let s = XorGate(xor, cin)
    let and1 = AndGate(xor, cin)
    let and2 = AndGate(a, b)
    let cout = OrGate(and1, and2)
    (s, cout)
}

public func RippleAdder(a : WireEnd, b: WireEnd) : WireEnd {
    let width = a.GetVertex().GetWidth()
    if (width != b.GetVertex().GetWidth()) {
        throw WiresNotAllSameWidthException("RippleAdder", width, b)
    }
    let splitA = Split(a, Array<Int64>(width){ i : Int64 => 1 })
    let splitB = Split(b, Array<Int64>(width){ i : Int64 => 1 })
    let added = map_acc_2(
        { 
            a : WireEnd, b : WireEnd, c : WireEnd => 
            FullAdder(a, b, c)

        },
        splitA,
        splitB,
        InfiniteWaveform(False)
    )
    Combine(added)
}