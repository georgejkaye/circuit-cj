/**
 * examples/accumulator.cj
 *
 * A simple n-width accumulator that adds the input to the stored value.
 * The initial value can also be specified.
 */

package examples

import components.*
import signatures.gate.*

let sig = gateLevelSignature

public func Accumulator(width!: Int64, initial!: Int64){
    let input = sig.UseWire(width)
    let prev = sig.UseWire(width)
    let zero = ConstantZero()
    let (sum, carry) = RippleAdder(prev, input, zero)
    RegisterGuardedFeedback(prev, initial: initial, signed: false, input: sum)
    MakeSubcircuit([
            InterfaceWire(input, "A")
        ], [
            InterfaceWire(sum, "S")
        ],
        "accumulator"
    )
}