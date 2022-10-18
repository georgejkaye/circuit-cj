/**
 * serial-multiplier.cj
 *
 * A circuit that multiplies two numbers together. Taken from the Hardcaml repo:
 * https://github.com/janestreet/hardcaml/blob/master/docs/serial_multiplier_example.mdx
 *
 * @author George Kaye
 * @since 0.1
 */

package examples.gate

import components.*
import signatures.gate.*

func PartialProduct(a : Wire_, b0: Wire_) : Wire_ {
    Mux2(a, ConstantZero(a.GetWidth()), b0)
}

func RunningSum(first : Wire_, prev_sum: Wire_, a: Wire_, b0: Wire_) : Wire_ {
    let lhs = Mux2(ConstantZero(a.GetWidth()), prev_sum, first)
    let rhs = PartialProduct(a, b0)
    let a = UnsignedExtend(lhs)
    let b = UnsignedExtend(rhs)
    let (sum, carry) = UseRippleAdder(a, b, ConstantZero())
    sum
}

func RunningSumLoop(first: Wire_, a : Wire_, b0 : Wire_) : (Wire_, Wire_) {
    let prev_sum = sig.UseWire(a.GetWidth())
    let sum = RunningSum(first, prev_sum, a, b0)
    let (lsb, msbs) = LsbAndMsbs(sum)
    Feedback(msbs, prev_sum)
    (msbs, lsb)
}


func ComputedBits(bit : Wire_, width : Int64) : Wire_ {
    let prev = sig.UseWire(width)
    let msbs = Msbs(prev)
    let combined = Combine([bit, msbs])
    DelayGuardedFeedback(combined, prev)
    combined
}

public func SerialMultiplierBit(width : Int64) {
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