package examples

import circuits.*
import debug.*

func partial_product(a!: Hypergraph, b0!: Hypergraph){
    Mux(sel: b0, low: a, high: Zero(width: a.GetN()))
}

func running_sum(first!: Hypergraph, sum!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let lhs = Mux(sel: first, low: Zero(width: a.GetN()), high: sum)
    let rhs = partial_product(a: a, b0: b0)
    let a = UnsignedExtend(lhs)
    let b = UnsignedExtend(rhs)
    Plus(a, b)
}

func running_sum_loop(first!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let link = NewLink(name: "prev_sum", width: 4)
    let prev_sum = Delay(width: 4, input: InLink(link))
    let sum = running_sum(first: first, sum: prev_sum, a: a, b0: b0)
    let msbs = Msbs(sum)
    Feedback(link: link, input: msbs)
}

func computed_bits(width!: Int64, bit!: Hypergraph){
    let link = NewLink(name: "d", width: width)
    let prev_bits = Register(initial: 0, input: InLink(link))
    let bits = Par(Msbs(prev_bits), bit)
    Feedback(link: link, input: bits)
}

external func serial_multiplier_bit(width!: Int64){
    let first = Input(width: 1)
    let a = Input(width: width)
    let b0 = Input(width: 1)
    let sum_bit = running_sum_loop(first: first, a: a, b0: b0)
    let bit = Lsb(sum_bit)
    let sum = Msbs(sum_bit)
    let computed_bits_v = computed_bits(width: width, bit: bit)
    Concat([sum, computed_bits_v])
}