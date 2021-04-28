package examples
import hypergraphs.*

external func HalfAdderPorts(){
    // First we declare our inputs so we have handles on them
    // let a = Input("a", 1)
    // let b = Input("b", 1)
    // Now we feed the inputs to the two gates
    // let carry = AndGate(lhs: a, rhs: b)
    // let sum = XorGate(lhs: a, rhs: b)
    // We need to return both the carry and the sum
    // Output([carry, sum])
}

external func HalfAdderCombinator(){
    let carry = AndGate(output: "carry")
    let sum = XorGate(output: "sum")
    let comp = Par(carry, sum)
    let copy = Copy(2)
    Seq(copy, comp)
}