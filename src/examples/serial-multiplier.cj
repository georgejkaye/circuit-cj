/** 
 * serial-multiplier.cj
 *
 * This example has been taken from the Hardcaml repo:
 * https://github.com/janestreet/hardcaml/blob/master/docs/serial_multiplier_example.mdx
 */


package examples

import components.*

func PartialProduct(a : WireEnd, b0: WireEnd) : WireEnd {
    Mux(sel: b0, high: a, low: ConstantZero(a.GetWidth()))
}

func RunningSum(first : WireEnd, prev_sum: WireEnd, a: WireEnd, b0: WireEnd) : WireEnd {
    let lhs = Mux(sel: first, high: prev_sum, low: ConstantZero(a.GetWidth()))
    let rhs = PartialProduct(a, b0)
    let a = UnsignedExtend(lhs)
    let b = UnsignedExtend(rhs)
    let (sum, carry) = Plus(a, b)
    sum
}

func RunningSumLoop(first: WireEnd, a : WireEnd, b0 : WireEnd) : (WireEnd, WireEnd) {
    let prev_sum = Wire(a.GetWidth())
    let sum = RunningSum(first, prev_sum, a, b0)
    let (lsb, msbs) = LsbAndMsbs(sum)
    Feedback(msbs, prev_sum)
    (msbs, lsb)
}


func ComputedBits(bit : WireEnd, width : Int64) : WireEnd {
    let prev = Wire(width)
    let msbs = Msbs(prev)
    let combined = Combine([bit, msbs]) 
    DelayedFeedback(combined, prev)
    combined
}

public func SerialMultiplierBit(width : Int64) {
    let first = Wire(1)
    let a = Wire(width)
    let b0 = Wire(1)
    let (sum, bit) = RunningSumLoop(first, a, b0)
    let computedBits = ComputedBits(bit, width)
    let output = Combine([sum, computedBits])
    MakeCircuit([first, a, b0], [output])
}