/** 
 * serial-multiplier.cj
 *
 * This example has been taken from the Hardcaml repo:
 * https://github.com/janestreet/hardcaml/blob/master/docs/serial_multiplier_example.mdx
 */


package examples

import components.*

func PartialProduct(a : Wire, b0: Wire) : Wire {
    Mux2(sel: b0, high: a, low: ConstantZero(a.GetWidth()))
}

func RunningSum(first : Wire, prev_sum: Wire, a: Wire, b0: Wire) : Wire {
    let lhs = Mux2(sel: first, high: prev_sum, low: ConstantZero(a.GetWidth()))
    let rhs = PartialProduct(a, b0)
    let a = UnsignedExtend(lhs)
    let b = UnsignedExtend(rhs)
    let (sum, carry) = Plus(a, b)
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
    MakeSubcircuit([first, a, b0], [output])
}