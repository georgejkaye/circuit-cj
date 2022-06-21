package components

import prelude.*
import syntax.*

public func Adder(a : WireEnd, b : WireEnd) : WireEnd {
    let width = a.GetWidth()
    if (width != b.GetWidth()) {
        throw WiresNotAllSameWidthException("Adder", width, b)
    }
    let adderSpec = Specification("adder", [width, width], [width])
    BlackBox(adderSpec, [a, b])[0]
}

public func HalfAdder(a : WireEnd, b : WireEnd) : (WireEnd, WireEnd) {
    if (a.GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", a, 1)
    }
    if (b.GetWidth() != 1){
        throw IncompatibleWidthException("HalfAdder", b, 1)
    }
    let s = XorGate(a, b)
    let c = AndGate(a, b)
    (s, c)
}

public func FullAdder(a : WireEnd, b : WireEnd, cin : WireEnd) : (WireEnd, WireEnd) {
    if (a.GetWidth() != 1){
        throw IncompatibleWidthException("FullAdder", a, 1)
    }
    if (b.GetWidth() != 1){
        throw IncompatibleWidthException("FullAdder", b, 1)
    }
    if (cin.GetWidth() != 1){
        throw IncompatibleWidthException("FullAdder", cin, 1)
    }
    let inputXor = XorGate(a, b)
    let carryXor = XorGate(inputXor, cin)
    let carryAnd = AndGate(inputXor, cin)
    let inputAnd = AndGate(a, b)
    let carryOr = OrGate(carryAnd, inputAnd)
    (carryXor, carryOr)
}

public func RippleAdder(a : WireEnd, b: WireEnd, c : WireEnd) : (WireEnd, WireEnd) {
    let width = a.GetWidth()
    if (width != b.GetWidth()) {
        throw WiresNotAllSameWidthException("RippleAdder", width, b)
    }
    ForEachBit([a, b], {
        ws : Array<WireEnd>, carry : WireEnd =>
        FullAdder(ws[0], ws[1], carry)
    }, c)
}
public func RippleAdderSubtractor(a : WireEnd, b : WireEnd, c : WireEnd) : (WireEnd, WireEnd) {
    let xor = XorGate(b, c)
    RippleAdder(a, xor, c)
}


public func Plus(a : WireEnd, b : WireEnd) : (WireEnd, WireEnd) {
    RippleAdder(a, b, InfiniteWaveform(False))
}
public func Subtract(a : WireEnd, b : WireEnd) : (WireEnd, WireEnd) {
    let carry = InfiniteWaveform(True)
    let xor = XorGate(b, carry)
    RippleAdder(a, b, carry)
}