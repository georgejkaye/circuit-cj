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
    let inputA = MakeWire(1)
    let inputB = MakeWire(1)
    let inputC = MakeWire(1)
    let inputXor = XorGate(inputA, inputB)
    let inputAnd = AndGate(inputA, inputB)
    let carryXor = XorGate(inputC, inputXor)
    let carryAnd = AndGate(inputC, inputXor)
    let carryOr = OrGate(inputAnd, carryAnd)
    let (circuit, wires) = MakeSubcircuit([inputA, inputB, inputC], [carryXor, carryOr], inputs: [a, b, c], name: "+")
    (wires[0], wires[1])
}

func MultibitFullAdder(a : Wire, b : Wire, c : Wire) {
    let inputA = MakeWire(a.GetWidth())
    let inputB = MakeWire(b.GetWidth())
    let inputC = MakeWire(c.GetWidth())
    let (sum, carry) = Bitwise(
        [inputA, inputB],
        { ws : Array<Wire>, c : Wire => FullAdder(ws[0], ws[1], c)},
        c
    )
    let (circuit, wires) = MakeSubcircuit([inputA, inputB, inputC], [sum, carry], inputs: [a, b, c], name: "+${a.GetWidth()}")
    (wires[0], wires[1])
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
    // Input wires
    let inputA = MakeWire(a.GetWidth())
    let inputB = MakeWire(a.GetWidth())
    let inputC = MakeWire(1)
    // To allow subtraction
    let xorGates = Xor(inputB, Copy(inputC, b.GetWidth()))
    let (sum, carry) = MultibitFullAdder(inputB, xorGates, inputC)
    let finalBitA = Msb(inputA)
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
    let (graph, addSub) = MakeSubcircuit([inputA,inputB,inputC],[sum,overflow,carry], inputs: [a,b,c], name: "ADD/SUB")
    (addSub[0], addSub[1], addSub[2])
}

public func ALU(w : Int64){
    let a = MakeWire(w)
    let b = MakeWire(w)
    let c0 = MakeWire(1)
    let c1 = MakeWire(1)
    let and = And(a, b)
    let or = Or(a, b)
    let (sum, overflow, carry) = AddSub(a, b, c1)
    let mux1 = Mux2(sel: c0, low: and, high: or)
    let mux2 = Mux2(sel: c1, low: mux1, high: sum)

    let result = mux2
    let zero = Not(Or(result))
    let negative = Msb(result)

    MakeSubcircuit([a,b,c0,c1], [result, zero, negative, overflow, carry], name: "ALU")[0]
}