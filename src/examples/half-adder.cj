package examples
import hypergraphs.*

external func HalfAdderFunctional(){
    // First we declare our inputs so we have handles on them
    let a = Input(label: "a", width: 1)
    let b = Input(label: "b", width: 1)
    // Now we feed the inputs to the two gates
    let carry = AndGate(lhs: a, rhs: b, output: "carry")
    let sum = XorGate(lhs: a, rhs: b, output: "sum")
    // We need to return both the carry and the sum
    Output([carry, sum], name: "half adder - functional style")
}

external func HalfAdderCombinator(){
    // Not necessary but nice if we want to label our inputs
    let a = Identity(1, output: "a")
    let b = Identity(1, output: "b")
    let inputs = Par(a,b)
    // We need to copy our inputs so there are versions for the AND and the XOR
    let copy = Copy(2)
    // Define the stack of the two gates
    let carry = AndGate(output: "carry")
    let sum = XorGate(output: "sum")
    let gates = Par(sum, carry)
    // Compose these three slices together
    Seq([inputs, copy, gates], name: "half adder - combinator style")
}