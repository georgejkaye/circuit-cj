package examples

import circuits.*
import debug.*

func partial_product(a!: Hypergraph, b0!: Hypergraph){
    Mux(width: a.GetN(), s: b0, a: a, b: Zero(width: a.GetN()))
}

func running_sum(first!: Hypergraph, sum!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let lhs = Mux(s: first, a: Zero(width: a.GetN()), b: sum)
    let rhs = partial_product(a: a, b0: b0)
    let a = UnsignedExtend(lhs)
    let b = UnsignedExtend(rhs)
    Plus(a, b)
}

func running_sum_loop(first!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
    let link = NewLink(name: "prev_sum", width: 4)
    let prev_sum = Delay(width: 4, input: InLink(link: link))
    let sum = running_sum(first: first, sum: prev_sum, a: a, b0: b0)
    let msbs = Msbs(sum)
    Feedback(link: link, input: msbs, label: "loop")
}

func computed_bits(width!: Int64, bit!: Hypergraph){
    let link = NewLink(name: "d", width: width)
    let prev_bits = Register(initial: 0, width: 4, input: InLink(link: link))
    let bits = Par(Msbs(prev_bits), bit)
    Feedback(link: link, input: bits)
}

external func serial_multiplier_bit(width!: Int64){
    Info("serial_multiplier_bit", "Making serial multiplier circuit for one bit")
    let first = Input(width: 1, label: "first")
    let a = Input(width: width, label: "a")
    let b0 = Input(width: 1, label: "b0")
    let sum_bit = running_sum_loop(first: first, a: a, b0: b0)
    let bit = Lsb(sum_bit)
    let sum = Msbs(sum_bit)
    let computed_bits_v = computed_bits(width: width, bit: bit)
    Concat([sum, computed_bits_v])
}