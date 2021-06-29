from circuits import circuits.*

func CyclicCombinational {
   
    let c = Input()
    let x = Input()
    let spec = NewLink(width: 1)
    let mux1 = Mux(a: x, b: InLink(spec: spec), s: c)
    let f = BlackBox("F", 1, 1, input: mux1)
    let mux2 = Mux(a: f, b: x, s: c)
    let g = BlackBox("G", 1, 1, input: mux2)
    let fb = Feedback(spec: spec, input: g)
    let circ = Mux(a: f, b: fb, s: c)


}