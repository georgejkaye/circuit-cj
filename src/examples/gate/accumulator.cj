/**
 * examples/accumulator.cj
 *
 * A simple n-width accumulator that adds the input to the stored value.
 * The initial value can also be specified.
 *
 * @author George Kaye
 * @since 0.1
 */
package examples.gate
public func Accumulator(width!: Int64, initial!: Int64) : Circuit_ {
    // Declare the input wire
    let input = sig.UseWire(width)
    // Declare the previous sum wire, which we will feedback to later
    let prev = sig.UseWire(width)
    // Initialise a constant zero to use as the initial carry
    let zero = sig.UseConstantZero(width: 1)
    // Combine the wires into a ripple adder
    let (sum, _) = UseRippleAdder(a: prev, b: input, cin: zero)
    // Feedback the output of the adder to the previous sum, guarded by
    // register with the initial value in
    RegisterGuardedFeedback(sum, prev, initial: initial, signed: false)
    // Put everything together in a subcircuit
    MakeSubcircuit(
        [InterfaceWire(input, "A")], [InterfaceWire(sum, "S")], "accumulator"
    )
}