package examples
import circuits.*

external func HalfAdderCombinator(){
    // We need to copy our inputs so there are versions for the AND and the XOR
    let copy = Copy(2)
    // Define the stack of the two gates
    let carry = AndGate()
    let sum = XorGate()
    let gates = sum * carry
    // Compose these three slices together
    copy + gates
}

external func HalfAdderFunctional(){
    // First we declare our inputs so we have handles on them
    let a = Input()
    let b = Input()
    // Now we feed the inputs to the two gates
    let carry = AndGate(a, b)
    let sum = XorGate(a, b)
    // We need to return both the carry and the sum
    Concat([sum, carry])
}