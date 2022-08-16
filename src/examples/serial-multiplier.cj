/**
 * serial-multiplier.cj
 *
 * A circuit that multiplies two numbers together. Taken from the Hardcaml repo:
 * https://github.com/janestreet/hardcaml/blob/master/docs/serial_multiplier_example.mdx
 *
 * @author George Kaye
 * @since 0.1
 */

package examples

import components.*

func PartialProduct(a : Wire, b0: Wire) : Wire {
    Mux2(a, ConstantZero(a.GetWidth()), b0)
}

func RunningSum(first : Wire, prev_sum: Wire, a: Wire, b0: Wire) : Wire {
    let lhs = Mux2(ConstantZero(a.GetWidth()), prev_sum, first)
    let rhs = PartialProduct(a, b0)
    let a = UnsignedExtend(lhs)
    let b = UnsignedExtend(rhs)
    let (sum, carry) = RippleAdder(a, b, ConstantZero())
    sum
}

func RunningSumLoop(first: Wire, a : Wire, b0 : Wire) : (Wire, Wire) {
    let prev_sum = MakeWire(a.GetWidth())
    let sum = RunningSum(first, prev_sum, a, b0)
    let (lsb, msbs) = LsbAndMsbs(sum)
    Feedback(msbs, prev_sum)
    (msbs, lsb)
}


func ComputedBits(bit : Wire, width : Int64) : Wire {
    let prev = MakeWire(width)
    let msbs = Msbs(prev)
    let combined = Combine([bit, msbs])
    DelayedFeedback(combined, prev)
    combined
}

public func SerialMultiplierBit(width : Int64) {
    let first = MakeWire(1)
    let a = MakeWire(width)
    let b0 = MakeWire(1)
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