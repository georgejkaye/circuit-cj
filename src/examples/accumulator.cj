package examples

import hypergraphs.*
import library.*
import debug.*

external func Accumulator(n : Int64){
    Debug("Accumulator", "Making accumulator")
    Debug("Accumulator", "Making link spec")
    let link_spec = LinkSpec("prev_sum", 4)
    Debug("Accumulator", "Making in link")
    let prev_sum = InLink(spec: link_spec)
    Debug("Accumulator", "Making input bus")
    let x = Input(label: "x", width: 4)
    Debug("Accumulator", "Making adder operation")
    let sum = Plus(width: 4, a: prev_sum, b: x, sum: "sum")
    Debug("Accumulator", "Making register")
    let reg = Register(width: 4, initial: n, input: sum)
    Debug("Accumulator", "Making out link")
    let out_link = OutLink(spec: link_spec, input: reg)
    Debug("Accumulator", "Returning outputs")
    sum
}