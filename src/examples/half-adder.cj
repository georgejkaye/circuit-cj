/**
 * half-adder.cj
 *
 * A half-adder, one of the most simple combinational
 * combinational one can design.
 */

package examples

import components.*

public func HalfAdder(){
    // First we declare our inputs so we have handles on them
    let a = Wire(1)
    let b = Wire(1)
    // Now we feed the inputs to the two gates
    let carry = AndGate(a, b)
    let sum = XorGate(a, b)
    // We need to return both the carry and the sum
    MakeCircuit([a,b], [carry,sum])
}