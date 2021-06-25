package examples

import circuits.*
import debug.*

external func Accumulator(width!: Int64, initial!: Int64 = 0){
    Info("Accumulator", "Making accumulator")
    let link_spec = NewSpec(name: "prev_sum", width: width)
    let prev_sum = InLink(spec: link_spec, label: "prev_sum")
    let x = Input(label: "x", width: width)
    let sum = Plus(a: reg, b: x, label: "sum", name: "Plus")
    FeedbackReg(spec: link_spec, input: sum, initial: initial)
}