/**
 * examples/cpu.cj
 * A simple 8 bit CPU
 * http://www.simplecpudesign.com/simple_cpu_v1/
 *
 * @author George Kaye
 * @since 0.2
 */
package examples.gate
/**
 * Create an ALU with the following modes:
 *
 *  S4 S3 S2 S1 S0  Z
 *  0  0  0  0  0   ADD (A+B)
 *  0  0  0  0  1   BITWISE AND (A&B)
 *  0  0  0  1  0   INPUT A
 *  0  0  0  1  1   INPUT B
 *  0  1  1  0  0   SUBTRACT (A-B)
 *  1  0  1  0  0   INCREMENT (A+1)
 *  1  0  0  0  0   INPUT A
 *  0  0  1  0  0   ADD (A+B)+1
 *  0  1  0  0  0   SUBTRACT (A-B)-1
 *
 * @return The ALU subcircuit
 */
func ALU() {
    // Input wires
    let a = sig.UseWire(8)
    let b = sig.UseWire(8)
    let s0 = sig.UseWire(1)
    let s1 = sig.UseWire(1)
    let s2 = sig.UseWire(1)
    let s3 = sig.UseWire(1)
    let s4 = sig.UseWire(1)
    // Combinational logic
    let not1 = UseNot(s4)
    let rep1 = Replicate(not1, 8)
    let inv1 = UseXor(b, Replicate(s3, 8))
    let and1 = UseAnd(rep1, inv1)
    let (sum, carry) = UseRippleAdder(a, and1, s2)
    let and2 = UseAnd(a, b)
    let mux = Mux4(s1, s0, sum, and2, a, b)
    // Final subcircuit
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
/**
 * @param d
 * @param ce
 * @param c
 * @param clk
 * @return FDCE register blackbox
 */
func FDCE(d: Wire_, ce: Wire_, c: Wire_, clr: Wire_) {
    let fdce = belnapSignature.AddBlackbox(
        "FDCE",
        [
            Port(1, name: "D"), Port(1, name: "CE"),
            Port(1, name: "C"), Port(1, name: "CLR")
        ],
        [Port(1, name: "Q")])
    UseBlackbox(fdce, [d, ce, c, clr])[0]
}
/**
 * @param pre
 * @param d
 * @param ce
 * @param c
 * @return FDPE register blackbox
 */
func FDPE(pre: Wire_, d: Wire_, ce: Wire_, c: Wire_) {
    let fdpe = belnapSignature.AddBlackbox(
        "FDPE",
        [
            Port(1, name: "PRE"),
            Port(1, name: "D"),
            Port(1, name: "CE"),
            Port(1, name: "C")
        ],
        [Port(1, name: "Q")]
    )
    UseBlackbox(fdpe, [pre, d, ce, c])[0]
}
/**
 * @param d
 * @param c
 * @param clr
 * @return FDC register blackbox
 */
func FDC(d: Wire_, c: Wire_, clr: Wire_) {
    let fdc = belnapSignature.AddBlackbox(
        "FDC",
        [
            Port(1, name: "D"),
            Port(1, name: "C"),
            Port(1, name: "CLR")
        ],
        [Port(1, name: "Q")]
    )
    UseBlackbox(fdc, [d, c, clr])[0]
}
/**
 * @param d
 * @param c
 * @return FD register blackbox
 */
func FD(d: Wire_, c: Wire_) {
    let fd = belnapSignature.AddBlackbox(
        "FD",
        [
            Port(1, name: "D"),
            Port(1, name: "C")
        ],
        [Port(1, name: "Q")],
    )
    UseBlackbox(fd, [d, c])[0]
}
/**
 * @param cpu_do
 * @param addr
 * @param ram_we
 * @param clk
 * @return RAM blackbox
 */
func RAM(cpu_do: Wire_, addr: Wire_, ram_we: Wire_, clk: Wire_) {
    let ram = belnapSignature.AddBlackbox(
        "ram",
        [
            Port(16, name: "din"),
            Port(8, name: "addr"),
            Port(1, name: "we"),
            Port(1, name: "clk")
        ],
        [Port(16, name: "dout")]
    )
    UseBlackbox(ram, [cpu_do, addr, ram_we, clk])[0]
}
/**
 * @param w The width of the input wire
 * @return a subcircuit containing an appropriate number of FDCE registers
 *           in parallel
 */
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
/**
 * Create a sequence generator, a circuit that determines which stage of the
 * fetch-decode-execute-increment cycle we are in.
 *
 * @return The sequence generator subcircuit
 */
func SequenceGenerator() {
    // Inputs
    let clr = sig.UseWire(1)
    let clk = sig.UseWire(1)
    let ce = sig.UseWire(1)
    let fb = sig.UseWire(1)
    // registers
    let reg1 = FDPE(clr, fb, ce, clk)
    let reg2 = FDCE(reg1, ce, clk, clr)
    let reg3 = FDCE(reg2, ce, clk, clr)
    let reg4 = FDCE(reg3, ce, clk, clr)
    // Feedback after the last register
    Feedback(reg4, fb)
    // Final subcircuit
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
/**
 * Create an instruction decoder subcircuit with the following instruction set.
 *
 * Load ACC kk : 0000 XXXX KKKKKKKK
 * Add ACC kk : 0100 XXXX KKKKKKKK
 * And ACC kk : 0001 XXXX KKKKKKKK
 * Sub ACC kk : 0110 XXXX KKKKKKKK
 * Input ACC pp : 1010 XXXX PPPPPPPP
 * Output ACC pp : 1110 XXXX PPPPPPPP
 * Jump U aa : 1000 XXXX AAAAAAAA
 * Jump Z aa : 1001 00XX AAAAAAAA
 * Jump C aa : 1001 10XX AAAAAAAA
 * Jump NZ aa : 1001 01XX AAAAAAAA
 * Jump NC aa : 1001 11XX AAAAAAAA
 *
 * @return The instruction decoder subcircuit
 */
func InstructionDecoder() {
    // Input wire
    let a = sig.UseWire(8)
    // Split the wire into eight bits for separate processing
    let bits = Split(a)
    // Determing the instruction from the bits
    let input = UseAnd([bits[7], UseNot(bits[6]), bits[5], UseNot(bits[4])])
    let output = UseAnd([bits[7], bits[6], bits[5], UseNot(bits[4])])
    let load = UseAnd([UseNot(bits[7]), UseNot(bits[6]), UseNot(bits[5]), UseNot(bits[4])])
    let add = UseAnd([UseNot(bits[7]), bits[6], UseNot(bits[5]), UseNot(bits[4])])
    let jump = UseAnd([bits[7], UseNot(bits[6]), UseNot(bits[5]), UseNot(bits[4])])
    let jump_condition = UseAnd([bits[7], UseNot(bits[6]), UseNot(bits[5]), bits[4]])
    let sub = UseAnd([UseNot(bits[7]), bits[6], bits[5], UseNot(bits[4])])
    let bitand = UseAnd([UseNot(bits[7]), UseNot(bits[6]), UseNot(bits[5]), bits[4]])
    let jumpz = UseAnd([jump_condition, UseNot(bits[3]), UseNot(bits[2])])
    let jumpnz = UseAnd([jump_condition, UseNot(bits[3]), bits[2]])
    let jumpc = UseAnd([jump_condition, bits[3], UseNot(bits[2])])
    let jumpnc = UseAnd([jump_condition, bits[3], bits[2]])
    // Final subcircuit
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
/**
 * Use the instruction decoder as part of the larger decoder.
 *
 * @param ir
 * @param decode
 * @param execute
 * @return
     (add, load, output, input, jumpz, jump, jumpnz, jumpc, jumpnc, sub, bitand)
 */
func Decoder_InstructionDecoder(ir: Wire_, decode: Wire_, execute: Wire_) {
    let instruction_decoder = UseSubcircuit(InstructionDecoder(), [ir])
    let phase = UseOr(decode, execute)
    let add = UseAnd(instruction_decoder[0], phase)
    let load = UseAnd(instruction_decoder[1], phase)
    let output = UseAnd(instruction_decoder[2], phase)
    let input = UseAnd(instruction_decoder[3], phase)
    let jumpz = UseAnd(instruction_decoder[4], phase)
    let jump = UseAnd(instruction_decoder[5], phase)
    let jumpnz = UseAnd(instruction_decoder[6], phase)
    let jumpc = UseAnd(instruction_decoder[7], phase)
    let jumpnc = UseAnd(instruction_decoder[8], phase)
    let sub = UseAnd(instruction_decoder[9], phase)
    let bitand = UseAnd(instruction_decoder[10], phase)
    (add, load, output, input, jumpz, jump, jumpnz, jumpc, jumpnc, sub, bitand)
}
/**
 * Use the sequence generator as part of the larger decoder.
 *
 * @param clk
 * @param ce
 * @param clr
 * @param carry
 * @param zero
 * @param add
 * @param sub
 * @return (fetch, decode, execute, increment, carry_reg, zero_reg)
 */
func Decoder_SequenceGenerator(
    clk: Wire_, ce: Wire_, clr: Wire_, carry: Wire_, zero: Wire_, add: Wire_,
    sub: Wire_, bitand: Wire_
) {
    // Use the sequence generator
    let sequence = UseSubcircuit(SequenceGenerator(), [clk, ce, clr])
    // Wires for each stage in the cycle
    let fetch = sequence[0]
    let decode = sequence[1]
    let execute = sequence[2]
    let increment = sequence[3]
    let en_st = UseOr([add, sub, bitand])
    let reg = UseSubcircuit_1(
        Register(2), [Combine(carry, zero), clk, en_st, clr]
    )
    let (carry_reg, zero_reg) = Split(reg, 1)
    // Output wires
    (fetch, decode, execute, increment, carry_reg, zero_reg)
}
/**
 * Compute the jump logic.
 *
 * @param clk
 * @param clr
 * @param increment
 * @param execute
 * @param jumpz
 * @param zero_reg
 * @param jumpnz
 * @param jumpc
 * @param carry_reg
 * @param jumpnc
 * @param jump
 * @return en_pc
 */
func Decoder_Jump(
    clk: Wire_, clr: Wire_, increment: Wire_, execute: Wire_, jumpz: Wire_,
    zero_reg: Wire_, jumpnz: Wire_, jumpc: Wire_, carry_reg: Wire_,
    jumpnc: Wire_, jump: Wire_
) {
    let is_jump = UseOr(
        [
            UseAnd(jumpz, zero_reg), UseAnd(jumpnz, UseNot(zero_reg)),
            UseAnd(jumpc, carry_reg), UseAnd(jumpnc, UseNot(zero_reg)),
            jump
        ]
    )
    let jump_not_taken = FDC(UseNot(is_jump), clk, clr)
    let en_pc = UseBuf(
        UseOr(UseAnd(increment, jump_not_taken), UseAnd(execute, is_jump))
    )
    en_pc
}
/**
 * Create the full decoder circuit.
 *
 * @return The decoder circuit
 */
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
    // Use the instruction decoder
    let (add, load, output, input, jumpz, jump, jumpnz, jumpc, jumpnc, sub, bitand) =
        Decoder_InstructionDecoder(ir, decodeFb, executeFb)
    // Use the sequence generator
    let (fetch, decode, execute, increment, carry_reg, zero_reg) =
        Decoder_SequenceGenerator(clk, ce, clr, carry, zero, add, sub, bitand)
    // Perform feedbacks
    Feedback(decode, decodeFb)
    Feedback(execute, executeFb)
    // Use the jump logic
    let en_pc = Decoder_Jump(
        clk, clr, increment, execute, jumpz, zero_reg, jumpnz, jumpc, carry_reg,
        jumpnc, jump
    )
    // Use the RAM
    let ram = UseBuf(UseAnd(execute, output))
    // Compute the output wires
    let is_jump = UseOr([jump, jumpz, jumpnz, jumpc, jumpnc])
    let alu_s0 = UseBuf(UseOr([bitand, input, load, is_jump]))
    let alu_s1 = UseBuf(UseOr([load, input, output, is_jump]))
    let alu_s2 = UseBuf(UseOr(increment, sub))
    let alu_s3 = UseBuf(sub)
    let alu_s4 = UseBuf(increment)
    let muxa = UseBuf(increment)
    let muxb = UseBuf(UseOr([load, add, bitand, sub]))
    let muxc = UseBuf(UseOr([input, output]))
    let en_in = UseBuf(fetch)
    let en_da = UseBuf(UseAnd(execute, UseOr([load, add, sub, bitand, input])))
    MakeSubcircuit(
        [
            InterfaceWire(ir, "IR"), InterfaceWire(carry, "Carry"),
            InterfaceWire(zero, "Zero"), InterfaceWire(clk, "CLK"),
            InterfaceWire(ce, "CE"), InterfaceWire(clr, "CLR")
        ],
        [
            InterfaceWire(muxa, "MUXA"), InterfaceWire(muxb, "MUXB"),
            InterfaceWire(muxc, "MUXC"), InterfaceWire(en_da, "EN_DA"),
            InterfaceWire(en_pc, "EN_PC"), InterfaceWire(en_in, "EN_IN"),
            InterfaceWire(ram, "RAM"), InterfaceWire(alu_s0, "ALU_S0"),
            InterfaceWire(alu_s1, "ALU_S1"), InterfaceWire(alu_s2, "ALU_S2"),
            InterfaceWire(alu_s3, "ALU_S3"), InterfaceWire(alu_s4, "ALU_S4")
        ],
        "decoder"
    )
}
/**
 * Create a simple CPU that operates on eight bit wires.
 *
 * @return CPU circuit
 */
public func SimpleCPU() {
    // Initialise the three input wires
    let nclr = sig.UseWire(1)
    let clk = sig.UseWire(1)
    let vcc = sig.UseWire(1)
    // The clear signal is a function of the inputs
    let clr = FD(UseNot(nclr), clk)
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
    let decoder = UseSubcircuit(
        Decoder(), [ir_decoder, carry, zero, clk, UseBuf(vcc), clr]
    )
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
    let muxi = Mux2(sel: muxa, a: ir_muxi, b: pc)
    // Mux_D
    let (instruction_muxd, _) = Split(instruction, 8)
    let acc_fb = sig.UseWire(8)
    let muxd = Mux2(sel: muxb, a: instruction_muxd, b: acc_fb)
    // Mux_A
    let addr = Mux2(sel: muxc, a: pc, b: ir_muxi)
    // ALU
    let (alu_z, alu_cout) = UseSubcircuit_2(
        ALU(), [muxi, muxd, alu_s0, alu_s1, alu_s2, alu_s3, alu_s4]
    )
    Feedback(alu_cout, carry)
    Feedback(UseNor(alu_z), zero)
    Feedback(alu_z, counter_d)
    // Accumulator
    let acc = UseSubcircuit_1(Register(8), [alu_z, clk, en_da, clr])
    Feedback(acc, acc_fb)
    // RAM
    let cpu_do = Combine(acc, sig.UseConstantZero(width: 8))
    let cpu_di = RAM(cpu_do, addr, ram_we, UseNot(clk))
    Feedback(cpu_di, instruction)
    // Serial out
    let serial_out = UseNot(FDCE(cpu_do.Lsb(), UseAnd(addr), clk, clr))
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
