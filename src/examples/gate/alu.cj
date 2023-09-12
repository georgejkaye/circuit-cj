/**
 * examples/alu.cj
 *
 * A simple ALU with AND, OR and ADD/SUB.
 * Follows a tutorial
 * http://www.csc.villanova.edu/~mdamian/Past/csc2400fa13/assign/ALU.html
 *
 * @author George Kaye
 * @version 1.0
 * @since 2022-06-21
 */
package examples.gate
/**
 * Create a full adder
 * @return A full adder subcircuit
 */
func FullAdder() {
    // Input wires
    let inputA = sig.UseWire(1)
    let inputB = sig.UseWire(1)
    let inputC = sig.UseWire(1)
    // Combinational logic
    let inputXor = UseXor(inputA, inputB)
    let inputAnd = UseAnd(inputA, inputB)
    let carryXor = UseXor(inputC, inputXor)
    let carryAnd = UseAnd(inputC, inputXor)
    let carryOr = UseOr(inputAnd, carryAnd)
    // Final subcircuit
    MakeSubcircuit([
            InterfaceWire(inputA, "A"),
            InterfaceWire(inputB, "B"),
            InterfaceWire(inputC, "C")
        ], [
            InterfaceWire(carryXor, "S"),
            InterfaceWire(carryOr, "C")
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
    // A full adder is a bitwise ripple with the carry as the initial value
    MakeBitwiseRippleMap(
        FullAdder(), acc: 1, ops: width, name: "+_${width}"
    )
}
/**
 * Create an arbitrary width adder than can also handle subtraction.
 * @param w The width of the inputs
 * @return The add/sub subcircuit
 */
func AddSub(width : Int64) {
    // Input wires
    let a = sig.UseWire(width)
    let b = sig.UseWire(width)
    let c = sig.UseWire(1)
    // To allow subtraction
    let xorGates = UseXor(b, Replicate(c, width))
    let (sum, carry) = UseSubcircuit_2(MultibitFullAdder(width), [c, a, b])
    let finalBitA = a.Msb()
    let finalBitB = xorGates.Msb()
    let finalBitSum = sum.Msb()
    let not = UseNot(finalBitSum)
    let overflow = UseOr(
        UseAnd([not, finalBitB, finalBitA]),
        UseAnd([finalBitSum, UseNot(finalBitB), UseNot(finalBitA)])
    )
    MakeSubcircuit([
        InterfaceWire(a, "A"), InterfaceWire(b, "B"), InterfaceWire(c, "C")
    ], [
        InterfaceWire(sum, "Sum"), InterfaceWire(overflow, "Overflow"),
        InterfaceWire(carry, "Carry")
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
    // Declare the four input wires
    let a = sig.UseWire(w)
    let b = sig.UseWire(w)
    let c0 = sig.UseWire(1)
    let c1 = sig.UseWire(1)
    // Connect the inputs to the three computation blocks
    let and = UseAnd(a, b)
    let or = UseOr(a, b)
    let (sum, overflow, carry) = UseSubcircuit_3(AddSub(w), [a, b, c0])
    // Use the multiplexers to decide which computation to return
    let mux1 = UseMux2(s0: c1, i0: and, i1: or)
    let mux2 = UseMux2(s0: c1, i0: mux1, i1: sum)
    // Compute the outputs appropriately
    let result = mux2
    let notzero = UseOr(result)
    let zero = UseNot(notzero)
    let negative = result.Msb()
    // Put everything together
    MakeSubcircuit([
            InterfaceWire(a, "A"), InterfaceWire(b, "B"),
            InterfaceWire(c0, "C0"), InterfaceWire(c1, "C1")
        ], [
            InterfaceWire(result, "Result"), InterfaceWire(zero, "Zero"),
            InterfaceWire(negative, "Neg"), InterfaceWire(overflow, "Overflow"),
            InterfaceWire(carry, "Carry")
        ],
        "ALU"
    )
}