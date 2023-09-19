/**
 * serial-multiplier.cj
 *
 * A circuit that multiplies two numbers together. Taken from the Hardcaml repo:
 * https://github.com/janestreet/hardcaml/blob/d2ec2d76ea9562c8211923057118257720c4a0aa/docs/serial_multiplier_example.mdx
 *
 * @author George Kaye
 * @since 0.1
 */
package examples.gate
/**
 * Compute a partial product: if b0 is high, then return a, otherwise return
 * zero.
 *
 * @param a
 * @param b0
 * @return the partial product for this bit
 */
func PartialProduct(a : Wire_, b0: Wire_) : Wire_ {
    UseMux2(s0: b0, i0: sig.UseConstantZero(width: a.GetWidth()),  i1: a)
}
/**
 * Compute a running sum.
 *
 * @param first Whether this is the first bit: if so, clear the initial to 0
 * @param prev_sum
 * @param a
 * @param b0
 */
func RunningSum(first : Wire_, prev_sum: Wire_, a: Wire_, b0: Wire_) : Wire_ {
    let lhs = UseMux2(
        s0: first, i0: prev_sum, i1: sig.UseConstantZero(width: a.GetWidth())
    )
    let rhs = PartialProduct(a, b0)
    let aExtended = UnsignedExtend(lhs)
    let bExtended = UnsignedExtend(rhs)
    let (sum, carry) = UseRippleAdder(
        a: aExtended, b: bExtended, cin: sig.UseConstantZero(width: 1)
    )
    sum
}
/**
 * Create the loop to compute the running sum.
 *
 * @param first Whether this is the first bit
 * @param a
 * @param b0
 * @return (msbs, lsb)
 */
func RunningSumLoop(first: Wire_, a : Wire_, b0 : Wire_) : (Wire_, Wire_) {
    let prev_sum = sig.UseWire(a.GetWidth())
    let sum = RunningSum(first, prev_sum, a, b0)
    let (lsb, msbs) = sum.LsbAndMsbs()
    let sum_reg =
        RegisterGuardedFeedback(msbs, prev_sum, initial: 0, signed: false)
    (sum_reg, lsb)
}
/**
 * Store the computed bits in a register.
 *
 * @param bit The newest bit
 * @param width
 * @output The output of the register
 */
func ComputedBits(bit : Wire_, width : Int64) : Wire_ {
    let prev = sig.UseWire(width)
    let msbs = prev.Msbs()
    let combined = Combine([bit, msbs])
    let combined_reg =
        RegisterGuardedFeedback(combined, prev, initial: 0, signed: false)
    combined_reg
}
/**
 * Create a serial multiplier circuit.
 *
 * @param width
 * @return The circuit
 */
public func SerialMultiplier(width : Int64) {
    let first = sig.UseWire(1)
    let a = sig.UseWire(width)
    let b0 = sig.UseWire(1)
    let (sum, bit) = RunningSumLoop(first, a, b0)
    let computedBits = ComputedBits(bit, width)
    let output = Combine([sum, computedBits])
    MakeSubcircuit([
            InterfaceWire(first, "first"),
            InterfaceWire(a, "A"),
            InterfaceWire(b0, "B0")
        ], [
            InterfaceWire(output, "Output")
        ],
        "serial_multiplier"
    )
}