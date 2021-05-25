package examples

import circuits.*
import debug.*

external func Accumulator(width!: Int64, initial!: Int64 = 0){
    Info("Accumulator", "Making accumulator")
    let link_spec = LinkSpec("prev_sum", width)
    let prev_sum = InLink(spec: link_spec, output: "prev_sum")
    let reg = Register(width: width, initial: initial, input: prev_sum, output: "reg")
    let x = Input(label: "x", width: width)
    let sum = Plus(a: reg, b: x, output: "sum", name: "Plus")
    Feedback(spec: link_spec, input: sum)
}