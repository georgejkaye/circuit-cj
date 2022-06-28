/**
 * cpu.cj
 * A simple 8 bit CPU 
 * http://www.simplecpudesign.com/simple_cpu_v1/
 *
 * @author George Kaye
 * @since 2022-06-21
 */

package examples

import graphs.*

func ALU() {
    let a = MakeWire(8)
    let s0 = MakeWire(1)
    let s1 = MakeWire(1)
    let s2 = MakeWire(1)
    let s3 = MakeWire(1)
    let s4 = MakeWire(1)
    let b = MakeWire(8)

    let not1 = Not(s4)
    let rep1 = Replicate(not1, 8)
    let inv1 = Xor(b, Replicate(s3, 8))
    let and1 = And(rep1, inv1)

    let (sum, carry) = RippleAdder(a, and1, s2)
    let and2 = And(a, b)

    let mux = Mux4(sum, and2, a, b, s1, s0)

    MakeSubcircuit([a, b, s0, s1, s2, s3, s4], [mux, carry], name: "alu")
}

func FDCE(d : Wire, ce : Wire, c : Wire, clr : Wire) {
    BlackBox("FDCE", [1,1,1,1], [1], [d, ce, c, clr])[0]
}
func FDPE(pre: Wire, d : Wire, ce : Wire, c : Wire) {
    BlackBox("FDPE", [1,1,1,1], [1], [pre, d, ce, c])[0]
}
func FDC(d : Wire, c : Wire, clr : Wire) {
    BlackBox("FDC", [1,1,1], [1], [d, c, clr])[0]
}
func RAM(cpu_do : Wire, addr : Wire, ram_we : Wire) {
    BlackBox("ram", [16,8,1], [16], [cpu_do,addr,ram_we])[0]
}

func Register(w : Int64) : InterfacedHypergraph {
    if (w % 2 == 1) {
        throw TodoException("Odd bit registers not implemented")
    }
    let d = MakeWire(w)
    let clr = MakeWire(1)
    let ce = MakeWire(1)
    let clk = MakeWire(1)
    let splitWidth = w / 2
    let (l, r) = Split(d, splitWidth, splitWidth)
    let outputs = if (splitWidth == 1) {
        Bitwise([d], { w : Array<Wire> => FDCE(w[0], ce, clk, clr) })
    } else {
        let lhs = UseSubcircuit_1(Register(splitWidth), [l, clr, ce, clk])
        let rhs = UseSubcircuit_1(Register(splitWidth), [r, clr, ce, clk])
        Combine(lhs, rhs)
    }
    MakeSubcircuit([d, clr, ce, clk], [outputs], name: "register_${w}")
}

func SequenceGenerator() {
    let clr = MakeWire(1)
    let clk = MakeWire(1)
    let ce = MakeWire(1)
    let fb = MakeWire(1)

    let reg1 = FDPE(clr, fb, ce, clk)
    let reg2 = FDCE(reg1, ce, clk, clr)
    let reg3 = FDCE(reg2, ce, clk, clr)
    let reg4 = FDCE(reg3, ce, clk, clr)

    Feedback(reg4, fb)
    MakeSubcircuit([clk, ce, clr], [reg1, reg2, reg3, reg4], name: "sequence_generator")
}

func InstructionDecoder() {
    let a = MakeWire(8)
    let bits = Split(a)
    
    let input = And([bits[7], Not(bits[6]), bits[5], Not(bits[4])])
    let output = And([bits[7], bits[6], bits[5], Not(bits[4])])
    let load = And([Not(bits[7]), Not(bits[6]), Not(bits[5]), Not(bits[4])])
    let add = And([Not(bits[7]), bits[6], Not(bits[5]), Not(bits[4])])
    let jump = And([bits[7], Not(bits[6]), Not(bits[5]), Not(bits[4])])
    let jump_condition = And([bits[7], Not(bits[6]), Not(bits[5]), bits[4]])
    let sub = And([Not(bits[7]), bits[6], bits[5], Not(bits[4])])
    let bitand = And([Not(bits[7]), Not(bits[6]), Not(bits[5]), bits[4]])
    let jumpz = And([jump_condition, Not(bits[3]), Not(bits[2])])
    let jumpnz = And([jump_condition, Not(bits[3]), bits[2]])
    let jumpc = And([jump_condition, bits[3], Not(bits[2])])
    let jumpnc = And([jump_condition, bits[3], bits[2]])
    MakeSubcircuit([a], [input, output, load, add, jump, sub, bitand, jumpz, jumpnz, jumpc, jumpnc], name: "instruction_decoder")
}


func Decoder_InstructionDecoder(ir : Wire, decode : Wire, execute : Wire) {
    let instruction_decoder = UseSubcircuit(InstructionDecoder(), [ir])
    let phase = Or(decode, execute)
    let add = And(instruction_decoder[0], phase)
    let load = And(instruction_decoder[1], phase)
    let output = And(instruction_decoder[2], phase)
    let input = And(instruction_decoder[3], phase)
    let jumpz = And(instruction_decoder[4], phase)
    let jump = And(instruction_decoder[5], phase)
    let jumpnz = And(instruction_decoder[6], phase)
    let jumpc = And(instruction_decoder[7], phase)
    let jumpnc = And(instruction_decoder[8], phase)
    let sub = And(instruction_decoder[9], phase)
    let bitand = And(instruction_decoder[10], phase)
    (add, load, output, input, jumpz, jump, jumpnz, jumpc, jumpnc, sub, bitand)
}

func Decoder_SequenceGenerator(clk : Wire, ce : Wire, clr : Wire, carry : Wire, zero : Wire, add : Wire, sub : Wire, bitand : Wire) {
    let sequence = UseSubcircuit(SequenceGenerator(), [clk, ce, clr])
    let fetch = sequence[0]
    let decode = sequence[1]
    let execute = sequence[2]
    let increment = sequence[3]

    let en_st = Or([add, sub, bitand])

    let reg = UseSubcircuit_1(Register(2), [Combine(carry, zero), clk, en_st, clr])
    let (carry_reg, zero_reg) = Split(reg, 1, 1)
    (fetch, decode, execute, increment, carry_reg, zero_reg)
}

func Decoder_Jump(
    clk : Wire, clr : Wire, increment : Wire, execute : Wire, 
    jumpz : Wire, zero_reg : Wire, jumpnz : Wire, jumpc : Wire, carry_reg : Wire, jumpnc : Wire, jump : Wire
) {
    let is_jump = Or([
        And(jumpz, zero_reg),
        And(jumpnz, Not(zero_reg)),
        And(jumpc, carry_reg),
        And(jumpnc, Not(zero_reg)),
        jump
    ])
    let jump_not_taken = FDC(Not(is_jump), clk, clr)
    let en_pc = Buf(
        Or(
            And(increment, jump_not_taken),
            And(execute, is_jump)
        )
    )
    en_pc
}

func Decoder() {

    // Inputs
    let ir = MakeWire(8)
    let clk = MakeWire(1)
    let ce = MakeWire(1)
    let clr = MakeWire(1)
    let carry = MakeWire(1)
    let zero = MakeWire(1)

    // Declare inputs for feedback
    let decodeFb = MakeWire(1)
    let executeFb = MakeWire(1)

    let (add, load, output, input, jumpz, jump, jumpnz, jumpc, jumpnc, sub, bitand) =
        Decoder_InstructionDecoder(ir, decodeFb, executeFb)

    let (fetch, decode, execute, increment, carry_reg, zero_reg) =
        Decoder_SequenceGenerator(clk, ce, clr, carry, zero, add, sub, bitand)

    Feedback(decode, decodeFb)
    Feedback(execute, executeFb)

    let en_pc = Decoder_Jump(clk, clr, increment, execute, jumpz, zero_reg, jumpnz, jumpc, carry_reg, jumpnc, jump)
    let ram = Buf(And(execute, output))
    let is_jump = Or([jump, jumpz, jumpnz, jumpc, jumpnc])
    let alu_s0 = Buf(Or([bitand, input, load, is_jump]))
    let alu_s1 = Buf(Or([load, input, output, is_jump]))
    let alu_s2 = Buf(Or(increment, sub))
    let alu_s3 = Buf(sub)
    let alu_s4 = Buf(increment)
    let muxa = Buf(increment)
    let muxb = Buf(Or([load, add, bitand, sub]))
    let muxc = Buf(Or([input, output]))
    let en_in = Buf(fetch)
    let en_da = Buf(And(execute, Or([load, add, sub, bitand, input])))

    MakeSubcircuit([ir, carry, zero, clk, ce, clr], [ram, alu_s0, alu_s1, alu_s2, alu_s3, alu_s4, muxa, muxb, muxc, en_in, en_da, en_pc])
}