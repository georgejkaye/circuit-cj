from circuits import circuits.*

func CyclicCombinational {
   
    let c = Input()
    let x = Input()
    let link = NewLink(width: 1)
    let mux1 = Mux(a: x, b: InLink(link: link), s: c)
    let f = BlackBox("F", 1, 1, input: mux1)
    let mux2 = Mux(a: f, b: x, s: c)
    let g = BlackBox("G", 1, 1, input: mux2)
    let fb = Feedback(link: link, input: g)
    let circ = Mux(a: f, b: fb, s: c)


}