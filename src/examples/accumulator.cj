package examples

import debug.*

import components.*
import arithmetic.*

public func Accumulator(width!: Int64, initial!: Int64){
    let input = Wire(width)
    let prev = Wire(width)
    let reg = SimpleRegister(initial: initial, signed: false, input: prev)
    let add = Adder(reg, input)
    Feedback(add, prev)
    MakeCircuit([input], [add])
}