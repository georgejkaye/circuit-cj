/**
 * half-adder.cj
 *
 * A half-adder, one of the most simple combinational
 * combinational one can design.
 */

package examples

import components.*

public func HalfAdder(a : Wire, b : Wire){
    // First we declare our inputs so we have handles on them
    let a = MakeWire(1)
    let b = MakeWire(1)
    // Now we feed the inputs to the two gates
    let carry = AndGate(a, b)
    let sum = XorGate(a, b)
    // We need to return both the carry and the sum
    MakeSubcircuit([a,b], [carry,sum])
}