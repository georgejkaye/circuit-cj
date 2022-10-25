/**
 * examples/cpu.cj
 * A simple 8 bit CPU
 * http://www.simplecpudesign.com/simple_cpu_v1/
 *
 * @author George Kaye
 * @since 2022-06-21
 */

package examples.gate

import syntax.*
import graphs.*

func ALU() {
    let a = sig.UseWire(8)
    let s0 = sig.UseWire(1)
    let s1 = sig.UseWire(1)
    let s2 = sig.UseWire(1)
    let s3 = sig.UseWire(1)
    let s4 = sig.UseWire(1)
    let b = sig.UseWire(8)

    let not1 = Not(s4)
    let rep1 = Replicate(not1, 8)
    let inv1 = Xor(b, Replicate(s3, 8))
    let and1 = And(rep1, inv1)

    let (sum, carry) = UseRippleAdder(a, and1, s2)
    let and2 = And(a, b)

    let mux = Mux4(s1, s0, sum, and2, a, b)

    MakeSubcircuit(
        [
            InterfaceWire(a, "A"),
            InterfaceWire(b, "B"),
            InterfaceWire(s0, "S0"),
            InterfaceWire(s1, "S1"),
            InterfaceWire(s2, "S2"),
            InterfaceWire(s3, "S3"),
            InterfaceWire(s4, "S4")
        ],
        [
            InterfaceWire(mux, "Z"),
            InterfaceWire(carry, "Cout")
        ],
        "alu"
    )
}

func FDCE(d: Wire_, ce: Wire_, c: Wire_, clr: Wire_) {
    BlackBox(
        "FDCE",
        [
            Port(1, name: "D"),
            Port(1, name: "CE"),
            Port(1, name: "C"),
            Port(1, name: "CLR")
        ],
        [Port(1, name: "Q")],
        [d, ce, c, clr]
    )[0]
}
func FDPE(pre: Wire_, d: Wire_, ce: Wire_, c: Wire_) {
    BlackBox(
        "FDPE",
        [
            Port(1, name: "PRE"),
            Port(1, name: "D"),
            Port(1, name: "CE"),
            Port(1, name: "C")
        ],
        [Port(1, name: "Q")],
        [pre, d, ce, c]
    )[0]
}
func FDC(d: Wire_, c: Wire_, clr: Wire_) {
    BlackBox(
        "FDC",
        [
            Port(1, name: "D"),
            Port(1, name: "C"),
            Port(1, name: "CLR")
        ],
        [Port(1, name: "Q")],
        [d, c, clr]
    )[0]
}
func FD(d: Wire_, c: Wire_) {
    BlackBox(
        "FD",
        [
            Port(1, name: "D"),
            Port(1, name: "C")
        ],
        [Port(1, name: "Q")],
        [d, c]
    )[0]
}
func RAM(cpu_do: Wire_, addr: Wire_, ram_we: Wire_, clk: Wire_) {
    BlackBox(
        "ram",
        [
            Port(16, name: "din"),
            Port(8, name: "addr"),
            Port(1, name: "we"),
            Port(1, name: "clk")
        ],
        [Port(16, name: "dout")],
        [cpu_do, addr, ram_we, clk]
    )[0]
}

public func Register(w: Int64): Circuit_ {
    if (w != 1 && w % 2 == 1){
        Todo("Off bit registers not implemented")
    }
    let d = sig.UseWire(w)
    let clr = sig.UseWire(1)
    let ce = sig.UseWire(1)
    let clk = sig.UseWire(1)
    let output = if (w == 1) {
        FDCE(d, ce, clk, clr)
    } else {
        let splitWidth = w / 2
        let (l, r) = Split(d, splitWidth)
        let lhs = UseSubcircuit_1(Register(splitWidth), [l, clr, ce, clk])
        let rhs = UseSubcircuit_1(Register(splitWidth), [r, clr, ce, clk])
        Combine(lhs, rhs)
    }
    MakeSubcircuit(
        [
            InterfaceWire(d, "D"),
            InterfaceWire(clr, "CLR"),
            InterfaceWire(ce, "CE"),
            InterfaceWire(clk, "CLK")
        ],
        [InterfaceWire(output, "Q")],
        "register_${w}"
    )
}

func SequenceGenerator() {
    let clr = sig.UseWire(1)
    let clk = sig.UseWire(1)
    let ce = sig.UseWire(1)
    let fb = sig.UseWire(1)

    let reg1 = FDPE(clr, fb, ce, clk)
    let reg2 = FDCE(reg1, ce, clk, clr)
    let reg3 = FDCE(reg2, ce, clk, clr)
    let reg4 = FDCE(reg3, ce, clk, clr)

    Feedback(reg4, fb)
    MakeSubcircuit(
        [
            InterfaceWire(clk, "CLK"),
            InterfaceWire(ce, "CE"),
            InterfaceWire(clr, "CLR")
        ],
        [
            InterfaceWire(reg1, "F"),
            InterfaceWire(reg2, "D"),
            InterfaceWire(reg3, "E"),
            InterfaceWire(reg4, "I")
        ],
        "sequence_generator"
    )
}

func InstructionDecoder() {
    let a = sig.UseWire(8)
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
    MakeSubcircuit(
        [InterfaceWire(a, "A")],
        [
            InterfaceWire(add, "ADD"),
            InterfaceWire(load, "LOAD"),
            InterfaceWire(output, "OUTPUT"),
            InterfaceWire(input, "INPUT"),
            InterfaceWire(jumpz, "JUMPZ"),
            InterfaceWire(jump, "JUMP"),
            InterfaceWire(jumpnz, "JUMPNZ"),
            InterfaceWire(jumpc, "JUMPC"),
            InterfaceWire(jumpnc, "JUMPNC"),
            InterfaceWire(sub, "SUB"),
            InterfaceWire(bitand, "BITAND")
        ],
        "instruction_decoder"
    )
}

func Decoder_InstructionDecoder(ir: Wire_, decode: Wire_, execute: Wire_) {
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

func Decoder_SequenceGenerator(clk: Wire_, ce: Wire_, clr: Wire_, carry: Wire_, zero: Wire_, add: Wire_, sub: Wire_,
    bitand: Wire_) {
    let sequence = UseSubcircuit(SequenceGenerator(), [clk, ce, clr])
    let fetch = sequence[0]
    let decode = sequence[1]
    let execute = sequence[2]
    let increment = sequence[3]

    let en_st = Or([add, sub, bitand])

    let reg = UseSubcircuit_1(Register(2), [Combine(carry, zero), clk, en_st, clr])
    let (carry_reg, zero_reg) = Split(reg, 1)
    (fetch, decode, execute, increment, carry_reg, zero_reg)
}

func Decoder_Jump(
    clk: Wire_,
    clr: Wire_,
    increment: Wire_,
    execute: Wire_,
    jumpz: Wire_,
    zero_reg: Wire_,
    jumpnz: Wire_,
    jumpc: Wire_,
    carry_reg: Wire_,
    jumpnc: Wire_,
    jump: Wire_
) {
    let is_jump = Or(
        [
            And(jumpz, zero_reg),
            And(jumpnz, Not(zero_reg)),
            And(jumpc, carry_reg),
            And(jumpnc, Not(zero_reg)),
            jump
        ]
    )
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
    let ir = sig.UseWire(8)
    let clk = sig.UseWire(1)
    let ce = sig.UseWire(1)
    let clr = sig.UseWire(1)
    let carry = sig.UseWire(1)
    let zero = sig.UseWire(1)

    // Declare inputs for feedback
    let decodeFb = sig.UseWire(1)
    let executeFb = sig.UseWire(1)

    let (add, load, output, input, jumpz, jump, jumpnz, jumpc, jumpnc, sub, bitand) = Decoder_InstructionDecoder(ir,
        decodeFb, executeFb)

    let (fetch, decode, execute, increment, carry_reg, zero_reg) = Decoder_SequenceGenerator(clk, ce, clr, carry, zero,
        add, sub, bitand)

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

    MakeSubcircuit(
        [
            InterfaceWire(ir, "IR"),
            InterfaceWire(carry, "Carry"),
            InterfaceWire(zero, "Zero"),
            InterfaceWire(clk, "CLK"),
            InterfaceWire(ce, "CE"),
            InterfaceWire(clr, "CLR")
        ],
        [
            InterfaceWire(muxa, "MUXA"),
            InterfaceWire(muxb, "MUXB"),
            InterfaceWire(muxc, "MUXC"),
            InterfaceWire(en_da, "EN_DA"),
            InterfaceWire(en_pc, "EN_PC"),
            InterfaceWire(en_in, "EN_IN"),
            InterfaceWire(ram, "RAM"),
            InterfaceWire(alu_s0, "ALU_S0"),
            InterfaceWire(alu_s1, "ALU_S1"),
            InterfaceWire(alu_s2, "ALU_S2"),
            InterfaceWire(alu_s3, "ALU_S3"),
            InterfaceWire(alu_s4, "ALU_S4")
        ],
        "decoder"
    )
}

public func SimpleCPU() {
    let nclr = sig.UseWire(1)
    let clk = sig.UseWire(1)
    let vcc = sig.UseWire(1)
    let clr = FD(Not(nclr), clk)

    // Instruction register
    let instruction = sig.UseWire(16)
    let en_in = sig.UseWire(1)
    let ir = UseSubcircuit_1(Register(16), [instruction, clk, en_in, clr])
    let (ir_muxi, ir_decoder) = Split(ir, 8)

    // Program counter
    let en_pc = sig.UseWire(1)
    let counter_d = sig.UseWire(8)
    let pc = UseSubcircuit_1(Register(8), [counter_d, clk, en_pc, clr])

    // Decoder
    let carry = sig.UseWire(1)
    let zero = sig.UseWire(1)
    let decoder = UseSubcircuit(Decoder(), [ir_decoder, carry, zero, clk, Buf(vcc), clr])
    let muxa = decoder[0]
    let muxb = decoder[1]
    let muxc = decoder[2]
    let en_da = decoder[3]
    Feedback(decoder[4], en_pc)
    Feedback(decoder[5], en_in)
    let ram_we = decoder[6]
    let alu_s0 = decoder[7]
    let alu_s1 = decoder[8]
    let alu_s2 = decoder[9]
    let alu_s3 = decoder[10]
    let alu_s4 = decoder[11]

    // Mux_I
    let muxi = Mux2(muxa, ir_muxi, pc)

    // Mux_D
    let (instruction_muxd, _) = Split(instruction, 8)
    let acc_fb = sig.UseWire(8)
    let muxd = Mux2(muxb, instruction_muxd, acc_fb)

    // Mux_A
    let addr = Mux2(muxc, pc, ir_muxi)

    // ALU
    let (alu_z, alu_cout) = UseSubcircuit_2(ALU(), [muxi, muxd, alu_s0, alu_s1, alu_s2, alu_s3, alu_s4])
    Feedback(alu_cout, carry)
    Feedback(Nor(alu_z), zero)
    Feedback(alu_z, counter_d)

    // Accumulator
    let acc = UseSubcircuit_1(Register(8), [alu_z, clk, en_da, clr])
    Feedback(acc, acc_fb)

    // RAM
    let cpu_do = Combine(acc, ConstantZero(8))
    let cpu_di = RAM(cpu_do, addr, ram_we, Not(clk))
    Feedback(cpu_di, instruction)

    // Serial out
    let serial_out = Not(
        FDCE(
            Lsb(cpu_do),
            And(addr),
            clk,
            clr
        )
    )

    // Make the subcircuit
    MakeSubcircuit(
        [
            InterfaceWire(nclr, "NCLR"),
            InterfaceWire(clk, "CLK"),
            InterfaceWire(vcc, "VCC")
        ],
        [InterfaceWire(serial_out, "SERIAL_OUT")],
        "CPU"
    )
}
