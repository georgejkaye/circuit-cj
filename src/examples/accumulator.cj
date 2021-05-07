package examples

import hypergraphs.*
import debug.*

external func Accumulator(w : Int64, n : Int64){
    Debug("Accumulator", "Making accumulator")
    Debug("Accumulator", "Making link spec")
    let link_spec = LinkSpec("prev_sum", w)
    Debug("Accumulator", "Making in link")
    let prev_sum = InLink(spec: link_spec, output: "prev_sum")
    WriteDotToFile(prev_sum, "dot/prevsum.dot")
    Debug("Accumulator", "Making input bus")
    let x = Input(label: "x", width: w)
    WriteDotToFile(x, "dot/input.dot")
    Debug("Accumulator", "Making adder operation")
    let sum = Plus(width: w, a: prev_sum, b: x, output: "sum", name: "Plus")
    Debug("Accumulator", "Making register")
    let reg = Register(width: w, initial: n, input: sum)
    reg
    //plus
    // Debug("Accumulator", "Making out link")
    // let out_link = OutLink(spec: link_spec, input: reg)
    // out_link
    //Debug("Accumulator", "Returning outputs")
    //Output([out_link,sum])
}