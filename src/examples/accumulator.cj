package examples

import circuits.*
import debug.*

external func Accumulator(width!: Int64, initial!: Int64){
    let sum_link = NewLink(width: width)
    let prev_sum = InLink(sum_link)
    let x = Input(width: width)
    let sum = Plus(prev_sum, x)
    let reg = Register(input: sum, initial: initial)
    reg.Feedback(sum_link)
    sum
}