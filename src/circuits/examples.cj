/**
 * examples.cj
 * 
 * This file contains examples of circuits
 * This is a temporary hack: when the package manager actually works, these should live in the examples package
 * Otherwise every time you make a new example you have to recompile the circuits stuff and it takes ages
 */

package circuits

/**
 * Arbitrary width ALU which
 * instruction 0: ADD
 * instruction 1: AND
 */

// func ALU(width: Int64){
//     let inputA = Input(width: width)
//     let inputB = Input(width: width)
//     // We only have two instructions so one bit is enough
//     let instruction = Input()
//     // Library components
//     let add = Plus(inputA, inputB)
//     let and = And(inputA, inputB)
//     // Perform different operation based on instruction signal
//     // 0: Add    1: And
//     let addInstruction = NotGate(input: instruction)
//     let andInstruction = instruction
//     // Use the instruction signal to determine which of the 
//     // computations should be output
//     var control = Empty()
//     for(i in 0..width){
//         control = Concat([control, AndGate(add[i], addInstruction)])
//     }
//     for(i in 0..width){
//         control = Concat([control, AndGate(and[i], andInstruction)])
//     }
//     Or(control)
// }

// func SimpleCPU(){
//     // Width of our buses
//     let w_inst = 16
//     let w_data = 8
//     // Clear
//     let nclr_in = Input()
//     // Clock
//     let clk_in = Input()
//     // Clock enable
//     let ce_in = Input()
//     // Signals from the decoder
//     let muxa   = NewLink(width: 1)
//     let muxb   = NewLink(width: 1)
//     let muxc   = NewLink(width: 1)
//     let en_da  = NewLink(width: 1)
//     let en_pc  = NewLink(width: 1)
//     let en_in  = NewLink(width: 1)
//     let ram_we = NewLink(width: 1)
//     let alu_s0 = NewLink(width: 1)
//     let alu_s1 = NewLink(width: 1)
//     let alu_s2 = NewLink(width: 1)
//     let alu_s3 = NewLink(width: 1)
//     let alu_s4 = NewLink(width: 1)
//     // Links from components we will build later
//     let ram_out = NewLink(width: w_inst)
//     let alu_out = NewLink(width: w_data)
//     let acc_out = NewLink(width: w_data)
//     // FD
//     let fd = FD(d: NotGate(input: nclr_in), c: clk)
//     // Instruction register
//     let ir = Reg(d: ram_dout, clk: clk_in, ce: en_in, clr: fd)
//     // Split signals into two buses of equal size
//     let (ir_high, ir_low) = Split(ir)
//     let (ram_high, ram_low) = Split(InLink(ram_dout))
//     // Program counter
//     let pc = Reg(d: alu_out, clk: clk_in, ce: en_pc, clr: fd)
//     // MUXI
//     let muxi = Mux(low: InLink(acc_in), high: pc, sel: muxa)
//     // MUXD
//     let muxd = Mux(low: ram_low, high: ir_low, sel: muxb)
//     // ALU
//     let alu = ALU(a: muxi, b: muxd, alu_s0: alu_s0, alu_s0: alu_s1, alu_s0: alu_s2, alu_s0: alu_s3, alu_s0: alu_s4)
//     let alu_z = Lsbs(alu)
//     // Connect the outputs to an earlier link, but also output them
//     alu_z.LinkAndOutput(alu_out)
//     let carry = Msb(alu)
//     let zero = NorGate(alu)
//     // Accumulator
//     let acc = Reg(d : alu, clk: clk_in, ce: en_da, clr: clr_in)
//     acc.LinkAndOutput(acc_out)
//     // Extend the data to fit in the ram, which might be bigger
//     let cpu_do = ExtendTo(acc, w_inst)
//     // MUXA
//     let muxa = Mux(low: pc, high: ir_low, sel: InLink(muxc))
//     let ram = Ram(w_inst + w_data + 1 + 1, w_inst, [cpu_do, muxa, InLink(ram_we), NotGate(clk)])
//     ram.Link(ram_dout)
//     // Decoder and associated links
//     let decoder = Decoder(ir: ir_high, carry: carry, zero: zero, clk: clk_in, ce: ce_in, clr: clr_in)
//     decoder.Link(0, muxa)
//     decoder.Link(1, muxb)
//     decoder.Link(2, muxc)
//     decoder.Link(3, en_da)
//     decoder.Link(4, en_pc)
//     decoder.Link(5, en_in)
//     decoder.Link(6, ram_we)
//     decoder.Link(7, alu_s0)
//     decoder.Link(8, alu_s1)
//     decoder.Link(9, alu_s2)
//     decoder.Link(10, alu_s3)
//     decoder.Link(11, alu_s4)
//     // Flip flop for output
//     let fdce = FDCE(d: Lsb(cpu_do), ce: muxa, c: clk_in, clr: clr_in)
//     // Serial out
//     NotGate(fdce)
// }

// let Reg(width: Int64, d: Hypergraph, clk: Hypergraph, ce: Hypergraph, clr: Hypergraph){
//     BlackBox("register_${width}", width + 3, width)
//}

// func Split(width: Int64, input: Hypergraph){
//     BlackBox(width, width, input: input)S
// }

// /**
//  * Naive fibonacci circuit to compute the nth fibonacci number
//  * @param n The fibonacci number to compute (from s0 = 0, s1 = 1, s2 = 1...)
//  * @param width The width of the number buses
//  */
// func Fibonacci(n : Int64, width!: Int64) : Hypergraph {
//     if(n == 0){
//         UnsignedValueFromInt(0, width: width)
//     } else if (n == 1) {
//         UnsignedValueFromInt(1, width: width)
//     } else {
//         Plus(Fibonacci(n - 1, width: width), Fibonacci(n - 2, width: width))
//     }
// }
// /**
//  * Example cyclic combinational circuit
//  */
// func CyclicCombinational(){
//     let x = Input()
//     let c = Input()
//     let link = NewLink(width: 1)
//     let mux1 = Mux(low: x, high: InLink(link: link), sel: c)
//     let f = BlackBox("F", 1, 1, input: Some(mux1))
//     let mux2 = Mux(low: f, high: x, sel: c)
//     let g = BlackBox("G", 1, 1, input: Some(mux2))
//     let fb = Feedback(link: link, input: g)
//     Mux(high: f, low: fb, sel: c)
// }
// /**
//  * Testing the if construct
//  */
// func IfTest(){
//     let a = UnsignedValueFromInt(6, width: 4)
//     let b = UnsignedValueFromInt(5, width: 4)
//     If(ifArg: Equals(a : a, b : b), thenArg: BlackBox("F", 1, 2), elseArg: BlackBox("G", 1, 2))
// }
// /**
//  * Naive sorting network
//  * @param width The width of the input wires
//  * @param inputs The number of inputs to sort
//  */
// func SortingNetwork(width: Int64, inputs: Int64) : Hypergraph {
//     if(inputs < 1){
//         Empty()
//     } else if (inputs == 1){
//         Identity(width)
//     } else {
//         var circ = SortingNetwork(width, inputs - 1) * Identity(width)
//         for(i in 0..inputs - 1){
//             let j = inputs - i - 2
//             var slice = Empty()
//             for(k in 0..inputs - 1){
//                 if (k == j){
//                     slice = slice * SortingComparator(width)
//                 } else {
//                     slice = slice * Identity(width)
//                 }
//             }
//             circ = circ + slice
//         }
//         circ
//     }
// }


// func FirFilter(width : Int64, coeffs: Hypergraph){
//     let inputs = Input(width: width)
//     // Serial in parallel ou shift register
//     let register = SerialInParallelOut(input, coeffs.GetN() / width)
//     // Multiply each outpout
//     let products = ForEach(register, {x : Hypergraph => Multiply(coeffs.Get(0, width))})
//     // Sum up all the products
//     Fold(products, init: 0, op: {x : Hypergraph, acc : Hypergraph => Plus(acc, x)})
// }

// func SortingComparator(width: Int64){
//     BlackBox("cmp", 2 * width, 2 * width)
// }

// func partial_product(a!: Hypergraph, b0!: Hypergraph){
//     Mux(sel: b0, high: a, low: Zero(width: a.GetN()))
// }

// func running_sum(first!: Hypergraph, sum!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
//     let lhs = Mux(sel: first, high: Zero(width: a.GetN()), low: sum)
//     let rhs = partial_product(a: a, b0: b0)
//     let a = UnsignedExtend(lhs)
//     let b = UnsignedExtend(rhs)
//     Plus(a, b)
// }

// func running_sum_loop(first!: Hypergraph, a!: Hypergraph, b0!: Hypergraph){
//     let width = a.GetN()
//     let link = NewLink(width: width)
//     let prev_sum = Delay(width: width, input: InLink(link: link))
//     let sum = running_sum(first: first, sum: prev_sum, a: a, b0: b0)
//     let msbs = Msbs(sum)
//     Feedback(link: link, input: msbs)
// }

// func computed_bits(width!: Int64, bit!: Hypergraph){
//     let link = NewLink(width: width)
//     let prev_bits = Register(initial: 0, width: width, input: InLink(link: link))
//     let bits = Msbs(prev_bits) * bit
//     Feedback(link: link, input: bits)
// }

// func serial_multiplier_bit(width!: Int64){
//     let first = Input(width: 1)
//     let a = Input(width: width)
//     let b0 = Input(width: 1)
//     let sum_bit = running_sum_loop(first: first, a: a, b0: b0)
//     let bit = Lsb(sum_bit)
//     let sum = Msbs(sum_bit)
//     let computed_bits_v = computed_bits(width: width, bit: bit)
//     Concat([sum, computed_bits_v])
// }

// func serial_multiplier(a : Int64, b : Int64, w : Int64){
//     let av = UnsignedValueFromInt(a, width: w)
//     let bv = UnsignedValueFromInt(b, width: w)
// }

// func Accumulator(width!: Int64, initial!: Int64){
//     let link = NewLink(width: width)
//     let prev_sum = InLink(link: link)
//     let x = Input(width: width)
//     let sum = Plus(prev_sum, x)
//     FeedbackReg(link: link, input: Some(sum), initial: initial)
// }