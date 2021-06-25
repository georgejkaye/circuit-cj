package examples
import circuits.*

external func HalfAdderCombinator(){
    // Not necessary but nice if we want to label our inputs
    let a = Identity(1, label: "a1")
    let b = Identity(1, label: "b1")
    let inputs = a + b
    // We need to copy our inputs so there are versions for the AND and the XOR
    let copy = Copy(2)
    // Define the stack of the two gates
    let carry = AndGate(label: "carry1")
    let sum = XorGate(label: "sum1")
    let gates = sum + carry
    // Compose these three slices together
    inputs * copy * gates
}

external func HalfAdderFunctional(){
    // First we declare our inputs so we have handles on them
    let a = Input(label: "a2", width: 1)
    let b = Input(label: "b2", width: 1)
    // Now we feed the inputs to the two gates
    let carry = AndGate(lhs: a, rhs: b, label: "carry2")
    let sum = XorGate(lhs: a, rhs: b, label: "sum2")
    // We need to return both the carry and the sum
    Concat([sum, carry], name: "half adder - functional style")
}