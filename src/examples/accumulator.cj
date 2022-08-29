/**
 * examples/accumulator.cj
 *
 * A simple n-width accumulator that adds the input to the stored value.
 * The initial value can also be specified.
 */

package examples

import components.*

public func Accumulator(width!: Int64, initial!: Int64){
    let input = MakeWire(width)
    let prev = MakeWire(width)
    let zero = ConstantZero()
    let (sum, carry) = RippleAdder(prev, input, zero)
    let reg = SimpleRegister(initial: initial, signed: false, input: sum)
    Feedback(reg, prev)
    MakeSubcircuit([
            InterfaceWire(input, "A")
        ], [
            InterfaceWire(sum, "S")
        ],
        "accumulator"
    )
}