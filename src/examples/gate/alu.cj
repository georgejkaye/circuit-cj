/**
 * examples/alu.cj
 *
 * A simple ALU with AND, OR and ADD/SUB.
 * Follows a tutorial http://www.csc.villanova.edu/~mdamian/Past/csc2400fa13/assign/ALU.html
 *
 * @author George Kaye
 * @version 1.0
 * @since 2022-06-21
 */

package examples.gate

import components.*
import signatures.gate.*

/**
 * Create a full adder
 * @return A full adder subcircuit
 */
func FullAdder() {
    let inputA = sig.UseWire(1)
    let inputB = sig.UseWire(1)
    let inputC = sig.UseWire(1)
    let inputXor = XorGate(inputA, inputB)
    let inputAnd = AndGate(inputA, inputB)
    let carryXor = XorGate(inputC, inputXor)
    let carryAnd = AndGate(inputC, inputXor)
    let carryOr = OrGate(inputAnd, carryAnd)
    MakeSubcircuit([
            sig.NameWire(inputA, "A"),
            sig.NameWire(inputB, "B"),
            sig.NameWire(inputC, "C")
        ], [
            sig.NameWire(carryXor, "S"),
            sig.NameWire(carryOr, "C")
        ],
        "+"
    )
}
/**
 * Create a full adder that operates on arbitrary width wires
 * @param width The width to specify for
 * @return A multibit full adder subcircuit
 */
func MultibitFullAdder(width : Int64) {
    let a = sig.UseWire(width)
    let b = sig.UseWire(width)
    let c = sig.UseWire(1)
    let (sum, carry) = BitwiseRipple(
        { acc : Array<Wire_>, cur : Array<Wire_> =>
            UseSubcircuit_2(
                FullAdder(),
                [cur[0], cur[1], acc[0]]
            )
        },
        [c],
        [a, b]
    )
    MakeSubcircuit([
            sig.NameWire(a, "A"),
            sig.NameWire(b, "B"),
            sig.NameWire(c, "C")
        ], [
            sig.NameWire(sum, "S"),
            sig.NameWire(carry, "C")
        ],
        "+_${a.GetWidth()}"
    )
}
/**
 * Create an arbitrary width adder than can also handle subtraction.
 * @param w The width of the inputs
 * @return The add/sub subcircuit
 */
public func AddSub(width : Int64) {
    // Input wires
    let a = sig.UseWire(width)
    let b = sig.UseWire(width)
    let c = sig.UseWire(1)
    // To allow subtraction
    let xorGates = Xor(b, Replicate(c, width))
    let (sum, carry) = UseSubcircuit_2(MultibitFullAdder(width), [a, b, c])
    let finalBitA = Msb(a)
    let finalBitB = Msb(xorGates)
    let finalBitSum = Msb(sum)
    let not = NotGate(finalBitSum)
    let overflow = Or(
        And([
            not,
            finalBitB,
            finalBitA
        ]),
        And([
            finalBitSum,
            NotGate(finalBitB),
            NotGate(finalBitA)
        ])
    )
    MakeSubcircuit([
            sig.NameWire(a, "A"),
            sig.NameWire(b, "B"),
            sig.NameWire(c, "C")
        ], [
            sig.NameWire(sum, "Sum"),
            sig.NameWire(overflow, "Overflow"),
            sig.NameWire(carry, "Carry")
        ],
        "ADD/SUB"
    )
}
/**
 * Create an ALU that can perform addition, subtraction and bitwise and,
 * specified for wires of a given width
 * @param w The width of the input wires
 * @return The ALU subcircuit
 */
public func ALU(w : Int64){
    let a = sig.UseWire(w)
    let b = sig.UseWire(w)
    let c0 = sig.UseWire(1)
    let c1 = sig.UseWire(1)
    let and = And(a, b)
    let or = Or(a, b)
    let (sum, overflow, carry) = UseSubcircuit_3(AddSub(w), [a, b, c0])
    let mux1 = Mux2(c1, and, or)
    let mux2 = Mux2(c1, mux1, sum)

    let result = mux2
    let notzero = Or(result)
    let zero = Not(notzero)
    let negative = Msb(result)

    MakeSubcircuit([
            sig.NameWire(a, "A"),
            sig.NameWire(b, "B"),
            sig.NameWire(c0, "C0"),
            sig.NameWire(c1, "C1")
        ], [
            sig.NameWire(result, "Result"),
            sig.NameWire(zero, "Zero"),
            sig.NameWire(negative, "Neg"),
            sig.NameWire(overflow, "Overflow"),
            sig.NameWire(carry, "Carry")
        ],
        "ALU"
    )
}