package examples

import circuits.*
import debug.*

func Accumulator(width: Int64, initial: Int64){
    let link_link = NewLink(width: width)
    let prev_sum = InLink(link: link_link)
    let x = Input(width: width)
    let sum = Plus(prev_sum, x)
    let circ = FeedbackReg(link: link_link, input: sum, initial: 0)
}