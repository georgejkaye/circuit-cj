/**
 * alu.cj
 * 
 * A simple ALU with AND, OR and ADD/SUB.
 * Follows a tutorial http://www.csc.villanova.edu/~mdamian/Past/csc2400fa13/assign/ALU.html
 *
 * @author George Kaye
 * @version 1.0
 * @since 2022-06-21
 */

package examples

import components.*

func FullAdder(a : Wire, b : Wire, c : Wire) {
    let inputXor = XorGate(a, b)
    let inputAnd = AndGate(a, b)
    let carryXor = XorGate(c, inputXor)
    let carryAnd = AndGate(c, inputXor)
    let carryOr = OrGate(inputAnd, carryAnd)
    (carryXor, carryOr)
}

func MultibitFullAdder(a : Wire, b : Wire, c : Wire) {
    ForEachBit(
        [a, b],
        { ws : Array<Wire>, c : Wire => FullAdder(ws[0], ws[1], c)},
        c
    )
}

/**
 * Create an arbitrary width adder than can also handle subtraction.
 *
 * This is implemented in the components/ library but is provided here
 * as an example.
 *
 * @param w The width of the inputs
 */
public func AddSub(a : Wire, b : Wire, c : Wire) {
    let a = MakeWire(a.GetWidth())
    let b = MakeWire(a.GetWidth())
    let control = MakeWire(1)

    let xorGates = XorGate(b, Copy(c, b.GetWidth()))
    let finalBitA = Msb(a)
    let finalBitB = Msb(xorGates)
    let (sum, carry) = MultibitFullAdder(a, xorGates, c)
    let finalBitSum = Msb(sum)
    let overflow = OrGate(
        AndGate([
            NotGate(finalBitSum), 
            finalBitB, 
            finalBitA
        ]),
        AndGate([
            finalBitSum,
            NotGate(finalBitB),
            NotGate(finalBitA)
        ])
    )
    let (graph, addSub) = MakeSubcircuit([a,b,c],[sum,overflow,carry])
    (addSub[0], addSub[1], addSub[2])
}

public func ALU(w : Int64){
    let a = MakeWire(w)
    let b = MakeWire(w)
    let c0 = MakeWire(1)
    let c1 = MakeWire(1)
    let and = AndGate(a, b)
    let or = OrGate(a, b)
    let (sum, overflow, carry) = AddSub(a, b, c1)
    let mux1 = Mux2(sel: c0, low: and, high: or)
    let mux2 = Mux2(sel: c1, low: mux1, high: sum)

    let result = mux2
    let zero = NotGate(OrGate(result))
    let negative = Msb(result)

    MakeSubcircuit([a,b,c0,c1], [result, zero, negative, overflow, carry])[0]
}