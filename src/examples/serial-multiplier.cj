package examples

import hypergraphs.*

func partial_product(a!: Hypergraph, b0!: Hypergraph){
    Mux(width: a.GetN(), s: b0, a: a, b: Zero(width: a.GetN()))
}

func running_sum(first!: Hypergraph, sum!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let lhs = Mux(width: sum.GetN(), s: first, a: Zero(width: a.GetN()), b: sum)
    let rhs = partial_product(a: a, b0: b0)
    Plus(a: UnsignedExtend(lhs), b: UnsignedExtend(rhs))
}

func running_sum_loop(first!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let spec = LinkSpec("prev_sum", 4)
    let prev_sum = Delay(width: 4, input: InLink(spec: spec))
    let sum = running_sum(first: first, sum: prev_sum, a: a, b0: b0)
    let msbs = Drop(sum, 0)
    Feedback(spec: spec, input: msbs)
}

func computed_bits(width!: Int64, bit!: Hypergraph){
    let spec = LinkSpec("d", width)
    let prev_bits = Register(initial: 0, width: 4, input: InLink(spec: spec))
    let bits = Par(Drop(prev_bits, 0), bit)
    Feedback(spec: spec, input: bits)
}

external func serial_multiplier_bit(width!: Int64){
    let first = Input(width: 1, label: "first")
    let a = Input(width: width, label: "a")
    let b0 = Input(width: 1, label: "b0")
    let sum_bit = running_sum_loop(first: first, a: a, b0: b0)
    let bit = Get(sum_bit, 0)
    let sum = Drop(sum_bit, 0)
    WriteDotToFile(bit, "dot/bit.dot")
    let computed_bits_v = computed_bits(width: width, bit: bit)
    computed_bits_v
}