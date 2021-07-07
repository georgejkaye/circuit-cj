package examples

import circuits.*
import debug.*

func Accumulator(width: Int64, initial: Int64){
    let sum_link = NewLink(width: width)
    let prev_sum = InLink(sum_link)
    let x = Input(width: width)
    let sum = Plus(prev_sum, x)
    let circ = FeedbackReg(link: sum_link, input: sum, initial: 0)
}