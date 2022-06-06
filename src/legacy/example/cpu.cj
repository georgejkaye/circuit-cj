package examples

import circuits.*

// Width of our buses
let w_inst = 16
let w_data = 8
func SimpleCPU(){
    // Clear
    let nclr_in = Input()
    // Clock
    let clk_in = Input()
    // Clock enable
    let ce_in = Input()
    // Signals from the decoder
    let MUXA   = NewLink(width: 1)
    let MUXB   = NewLink(width: 1)
    let MUXC   = NewLink(width: 1)
    let en_da  = NewLink(width: 1)
    let en_pc  = NewLink(width: 1)
    let en_in  = NewLink(width: 1)
    let ram_we = NewLink(width: 1)
    let alu_s0 = NewLink(width: 1)
    let alu_s1 = NewLink(width: 1)
    let alu_s2 = NewLink(width: 1)
    let alu_s3 = NewLink(width: 1)
    let alu_s4 = NewLink(width: 1)
    // Links from components we will build later
    let ram_out = NewLink(width: w_inst)
    let alu_out = NewLink(width: w_data)
    let acc_out = NewLink(width: w_data)
    // FD
    let fd = FD(d: NotGate(input: nclr_in), c: clk_in)
    // Instruction register
    let ir = Reg16(d: InLink(ram_out), clk: clk_in, ce: InLink(en_in), clr: fd)
    // Split signals into two buses of equal size
    let (ir_high, ir_low) = Split(ir)
    let (ram_high, ram_low) = Split(InLink(ram_out))
    // Program counter
    let pc = Reg8(d: InLink(alu_out), clk: clk_in, ce: InLink(en_pc), clr: fd)
    // MUXI
    let muxi = Mux(low: InLink(acc_out), high: pc, sel: InLink(MUXA))
    // MUXD
    let muxd = Mux(low: ram_low, high: ir_low, sel: InLink(MUXC))
    // ALU
    let alu = ALU(a: muxi, b: muxd, alu_s0: InLink(alu_s0), alu_s1: InLink(alu_s1), alu_s2: InLink(alu_s2), alu_s3: InLink(alu_s3), alu_s4: InLink(alu_s4))
    let alu_z = Lsbs(alu)
    let carry = Msb(alu)
    // Connect the outputs to an earlier link
    alu_z.Feedback(alu_out)
    let zero = Nor8(alu_z)
    // Accumulator
    let acc = Reg8(d : alu_z, clk: clk_in, ce: InLink(en_da), clr: fd)
    acc.Feedback(acc_out)
    // Extend the data to fit in the ram, which might be bigger
    let cpu_do = ExtendTo(acc, w_inst)
    // MUXA
    let muxa = Mux(low: pc, high: ir_low, sel: InLink(MUXC))
    let ram = Ram(cpu_do: cpu_do, addr: muxa, we: InLink(ram_we), clk: NotGate(input: Some(clk_in)))
    ram.Feedback(ram_out)
    // Decoder and associated links
    let decoder = Decoder(ir: ir_high, carry: carry, zero: zero, clk: clk_in, ce: ce_in, clr: fd)
    decoder.Feedback(0, MUXA)
    decoder.Feedback(1, MUXB)
    decoder.Feedback(2, MUXC)
    decoder.Feedback(3, en_da)
    decoder.Feedback(4, en_pc)
    decoder.Feedback(5, en_in)
    decoder.Feedback(6, ram_we)
    decoder.Feedback(7, alu_s0)
    decoder.Feedback(8, alu_s1)
    decoder.Feedback(9, alu_s2)
    decoder.Feedback(10, alu_s3)
    decoder.Feedback(11, alu_s4)
    // Flip flop for output
    let fdce = FDCE(d: Lsb(cpu_do), ce: And8(muxa), c: clk_in, clr: fd)
    // Serial out
    NotGate(input: Some(fdce))
}

func FD(d!: Hypergraph, c!: Hypergraph){
    BlackBox("FD", 2, 1, [d, c])
}
func Reg16(d!: Hypergraph, clk!: Hypergraph, ce!: Hypergraph, clr!: Hypergraph){
    BlackBox("Reg16", 19, 16, [d, clk, ce, clr])
}
func Reg8(d!: Hypergraph, clk!: Hypergraph, ce!: Hypergraph, clr!: Hypergraph){
    BlackBox("Reg8", 11, 8, [d, clk, ce, clr])
}
func ALU(a!: Hypergraph, b!: Hypergraph, alu_s0!: Hypergraph, alu_s1!: Hypergraph, alu_s2!: Hypergraph, alu_s3!: Hypergraph, alu_s4!: Hypergraph){
    BlackBox("ALU", 21, 9, [a, b, alu_s0, alu_s1, alu_s2, alu_s3])
}
func Ram(cpu_do!: Hypergraph, addr!: Hypergraph, we!: Hypergraph, clk!: Hypergraph){
    BlackBox("Ram", w_inst + w_data + 1 + 1, w_inst, [cpu_do, addr, we, clk])
}
func FDCE(d!: Hypergraph, ce!: Hypergraph, c!: Hypergraph, clr!: Hypergraph){
    BlackBox("FDCE", 4, 1, [d, ce, c, clr])
}
func ExtendTo(input: Hypergraph, width: Int64){
    BlackBox("ExtendTo", input.GetN(), width, [input])
}
func And8(inp: Hypergraph){
    BlackBox("And8", 8, 1, [inp])
}
func Nor8(inp: Hypergraph){
    BlackBox("Nor8", 8, 1, [inp])
}
func Decoder(ir!: Hypergraph, carry!: Hypergraph, zero!: Hypergraph, clk!: Hypergraph, ce!: Hypergraph, clr!: Hypergraph){
    BlackBox("Decoder", 13, 12, [ir, carry, zero, clk, ce, clr])
}