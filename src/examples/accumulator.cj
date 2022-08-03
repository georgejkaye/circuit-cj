/**
 * accumulator.cj
 *
 * A simple n-width accumulator that adds the input to the stored value.
 * The initial value can also be specified.
 */

package examples

import components.*

public func Accumulator(width!: Int64, initial!: Int64){
    let input = MakeWire(width)
    let prev = MakeWire(width)
    let reg = SimpleRegister(initial: initial, signed: false, input: prev)
    let (sum, carry) = Plus(reg, input)
    Feedback(sum, prev)
    MakeSubcircuit([
        InterfaceWire(input, "A")
    ], [
        InterfaceWire(sum, "S")
    ])
}