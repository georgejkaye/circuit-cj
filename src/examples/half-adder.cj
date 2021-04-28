package examples
import hypergraphs.*

external func HalfAdderPorts(){
    // First we declare our inputs so we have handles on them
    let a = Input(port: "a", width: 1)
    let b = Input(port: "b", width: 1)
    // Now we feed the inputs to the two gates
    let carry = AndGate(lhs: a, rhs: b, port: "carry")
    let sum = XorGate(lhs: a, rhs: b, port: "sum")
    // We need to return both the carry and the sum
    carry
    // Seq(Par(a,b), carry)
    //Output([carry, sum])
}

external func HalfAdderCombinator(){
    let carry = AndGate(port: "carry")
    let sum = XorGate(port: "sum")
    let comp = Par(carry, sum)
    let copy = Copy(2)
    Seq(copy, comp)
}