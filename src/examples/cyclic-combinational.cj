package examples

import circuits.*

func CyclicCombinational() {
   
    let x = Input()
    let c = Input()
    let link = NewLink(width: 1)
    let mux1 = Mux(low: x, high: InLink(link), sel: c)
    let f = BlackBox("F", 1, 1, input: Some(mux1))
    let mux2 = Mux(low: f, high: x, sel: c)
    let g = BlackBox("G", 1, 1, input: Some(mux2))
    let fb = Feedback(link: link, input: g)
    Mux(high: f, low: fb, sel: c)
}