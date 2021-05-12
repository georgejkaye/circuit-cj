package examples

import hypergraphs.*
import debug.*

external func Accumulator(width!: Int64, initial!: Int64 = 0){
    Debug("Accumulator", "Making accumulator")
    Debug("Accumulator", "Making link spec")
    let link_spec = LinkSpec("prev_sum", width)
    Info("Accumulator", "Making in link")
    let prev_sum = InLink(spec: link_spec, output: "prev_sum")
    Info("Accumulator", "Making input bus")
    let x = Input(label: "x", width: width)
    Info("Accumulator", "Making adder operation")
    let sum = Plus(width: width, a: prev_sum, b: x, output: "sum", name: "Plus")
    Info("Accumulator", "Making register")
    let reg = Register(width: width, initial: initial, input: sum, output: "reg")
    Info("Accumulator", "Making out link")
    let out_link = OutLink(spec: link_spec, input: reg)
    Output([sum])
}