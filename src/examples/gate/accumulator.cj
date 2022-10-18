/**
 * examples/accumulator.cj
 *
 * A simple n-width accumulator that adds the input to the stored value.
 * The initial value can also be specified.
 */

package examples.gate

import components.*
import signatures.gate.*

public func Accumulator(width!: Int64, initial!: Int64) : Circuit_ {
    let input = sig.UseWire(width)
    let prev = sig.UseWire(width)
    println("prev ${prev.GetWidth()}")
    let zero = sig.UseInfiniteWaveform([Signal([FALSE])])
    let (sum, carry) = UseRippleAdder(prev, input, zero)
    RegisterGuardedFeedback(sum, prev, initial: initial, signed: false)
    MakeSubcircuit([
            InterfaceWire(input, "A")
        ], [
            InterfaceWire(sum, "S")
        ],
        "accumulator"
    )
}