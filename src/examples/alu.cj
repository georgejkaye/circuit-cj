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

func FullAdder() {
    let inputA = MakeWire(1)
    let inputB = MakeWire(1)
    let inputC = MakeWire(1)
    let inputXor = XorGate(inputA, inputB)
    let inputAnd = AndGate(inputA, inputB)
    let carryXor = XorGate(inputC, inputXor)
    let carryAnd = AndGate(inputC, inputXor)
    let carryOr = OrGate(inputAnd, carryAnd)
    MakeSubcircuit([inputA, inputB, inputC], [carryXor, carryOr], name: "+")
}

func MultibitFullAdder(width : Int64) {
    let a = MakeWire(width)
    let b = MakeWire(width)
    let c = MakeWire(1)
    let (sum, carry) = Bitwise(
        [a, b],
        { ws : Array<Wire>, c : Wire => FullAdder(ws[0], ws[1], c)},
        c
    )
    MakeSubcircuit([a, b, c], [sum, carry], name: "+_${a.GetWidth()}")
}

/**
 * Create an arbitrary width adder than can also handle subtraction.
 *
 * This is implemented in the components/ library but is provided here
 * as an example.
 *
 * @param w The width of the inputs
 */
public func AddSub(width : Int64) {
    // Input wires
    let a = MakeWire(width)
    let b = MakeWire(width)
    let c = MakeWire(1)
    // To allow subtraction
    let xorGates = Xor(b, Copy(c, width))
    let (sum, carry) = UseSubcircuit_2(MultibitFullAdder(width), [a, b, c])
    let finalBitA = Msb(a)
    let finalBitB = Msb(xorGates)
    let finalBitSum = Msb(sum)
    let overflow = Or(
        And([
            NotGate(finalBitSum), 
            finalBitB, 
            finalBitA
        ]),
        And([
            finalBitSum,
            NotGate(finalBitB),
            NotGate(finalBitA)
        ])
    )
    MakeSubcircuit([a, b, c], [sum, overflow, carry], name: "ADD/SUB")
}

public func ALU(w : Int64){
    let a = MakeWire(w)
    let b = MakeWire(w)
    let c0 = MakeWire(1)
    let c1 = MakeWire(1)
    let and = And(a, b)
    let or = Or(a, b)
    let (sum, overflow, carry) = UseSubcircuit_3(AddSub(w), [a, b, c0])
    let mux1 = Mux2(sel: c0, low: and, high: or)
    let mux2 = Mux2(sel: c1, low: mux1, high: sum)

    let result = mux2
    let zero = Not(Or(result))
    let negative = Msb(result)

    MakeSubcircuit([a,b,c0,c1], [result, zero, negative, overflow, carry], name: "ALU")
}