package examples

import circuits.*
import debug.*

func Accumulator(width: Int64, initial: Int64){
    let link_spec = NewLink(width: width)
    let prev_sum = InLink(spec: link_spec)
    let x = Input(width: width)
    let sum = Plus(a: prev_sum, b: x)
    let circ = FeedbackReg(spec: link_spec, input: sum, initial: 0)
}