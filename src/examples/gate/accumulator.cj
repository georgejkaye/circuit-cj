/**
 * examples/accumulator.cj
 *
 * A simple n-width accumulator that adds the input to the stored value.
 * The initial value can also be specified.
 */

package examples.gate

public func Accumulator(width!: Int64, initial!: Int64) : Circuit_ {
    let input = sig.UseWire(width)
    let prev = sig.UseWire(width)
    let zero = sig.UseConstantZero(width: 1)
    let (sum, carry) = UseRippleAdder(prev, input, zero)
    RegisterGuardedFeedback(initial, width, false, sum, prev)
    MakeSubcircuit([
            InterfaceWire(input, "A")
        ], [
            InterfaceWire(sum, "S")
        ],
        "accumulator"
    )
}