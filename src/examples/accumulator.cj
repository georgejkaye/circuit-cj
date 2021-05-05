package examples

import hypergraphs.*
import library.*

external func Accumulator(n : Int64){
    let link_spec = LinkSpec("prev_sum", 4)
    let prev_sum = InLink(spec: link_spec)
    let x = Input(label: "x", width: 4)
    let sum = Plus(width: 4, a: prev_sum, b: x, sum: "sum")
    sum
    //let reg = Register(width: 4, initial: n, input: sum)
    //print("herewwwwwwwwwww\n")
    //reg
    //let out_link = OutLink(spec: link_spec, input: reg)
    //out_link
    // print("here3333333333333333\n")
    // sum
}