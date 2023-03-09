/**
 * half-adder.cj
 *
 * A half-adder, one of the most simple combinational
 * circuits one can design.
 *
 * @author George Kaye
 * @since 0.1
 */

package examples.gate

public func HalfAdder(){
    // First we declare our inputs so we have handles on them
    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    // Now we feed the inputs to the two gates
    let carry = AndGate(a, b)
    let sum = XorGate(a, b)
    // We need to return both the carry and the sum
    MakeSubcircuit([
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B")
        ], [
            InterfaceWire(sum, "S"),
            InterfaceWire(carry, "C")
        ],
        "half adder"
    )
}