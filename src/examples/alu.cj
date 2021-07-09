package examples

import circuits.*

/**
 * Arbitrary width ALU which can perform two operations
 * instruction 0: ADD
 * instruction 1: AND
 */
func ALU(width: Int64){
    let inputA = Input(width: width)
    let inputB = Input(width: width)
    // We only have two instructions so one bit is enough
    let instruction = Input()
    // Library components
    let add = Plus(inputA, inputB)
    let and = And(inputA, inputB)
    // Perform different operation based on instruction signal
    // 0: Add    1: And
    let addInstruction = NotGate(input: instruction)
    let andInstruction = instruction
    // Use the instruction signal to determine which of the 
    // computations should be output
    var control = Empty()
    for(i in 0..width){
        control = Concat([control, AndGate(add[i], addInstruction)])
    }
    for(i in 0..width){
        control = Concat([control, AndGate(and[i], andInstruction)])
    }
    Or(control)
}