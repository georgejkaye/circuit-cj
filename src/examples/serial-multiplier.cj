package examples

import hypergraphs.*

external func partial_product(a!: Hypergraph, b0!: Hypergraph){
    Mux(width: a.GetN(), s: b0, a: a, b: Zero(width: a.GetN()))
}

external func running_sum(first!: Hypergraph, sum!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let lhs = Mux(width: sum.GetN(), s: first, a: Zero(width: a.GetN()), b: sum)
    let rhs = partial_product(a: a, b0: b0)
    Plus(a: UnsignedExtend(lhs), b: UnsignedExtend(rhs))
}

external func running_sum_loop(first!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let spec = LinkSpec("prev_sum", 4)
    let prev_sum = Delay(width: 4, input: InLink(spec: spec))
    let sum = running_sum(first: first, sum: prev_sum, a: a, b0: b0)
    let msbs = Drop(sum, 0)
    let lsb = Get(sum, 0)
    let out_link = OutLink(spec: spec, input: msbs)
    Output([out_link, lsb, msbs])
}