/**
 * gates.cj
 *
 * This file contains gates that can be used in a circuit
 */

package hypergraphs

import debug.*

/**
 * Create a hypergraph for a given operation
 * @param m         The inputs of the operation
 * @param n         The outputs of the operation
 * @param generator The generator that corresponds to this operation
 * @param name      The name to give the resulting hypergraph
 * @return A hypergraph corresponding to this operation
 */
func OpMToN(generator : Generator, name!: String = "", wires!: ArrayList<Wire>, input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {

    Debug("OpMToN - ${generator}", "Creating operation, wires = ${WireListToString(wires)}")

    let (dom, cod) = Signature(generator)
    match(input){
        case $None => {}
        case Some(f) => {
            if(f.GetN() != dom){
                throw BadInputException("OpMToN - ${generator}", "input", dom, f.GetName(), f.GetN())
            }
        }
    }
    if(wires.size() != cod){
        throw BadOutputLabelsException("OpMToN - ${generator}", wires.size(), cod)
    }

    let hb = HypBuilder(dom, cod, wires)
    let op = hb.CreateEdge(generator, hb.GetInputs(), hb.GetOutputs())
    let res = hb.ToGraph()
    match(input){
        case Some(f) => Seq(f, res)
        case $None   => res
    }
}

func OpMToZero(gen : Generator, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    OpMToN(gen, name: name, wires: ArrayList<Wire>(), input: input)
}

func OpMToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    let bus = FindBus(output)
    let wires : ArrayList<Wire> = ArrayList<Wire>([NewWire(output, elem)])
    OpMToN(gen, name: name, wires: wires, input: input)
}

func OpMToTwo(gen : Generator, output1!: String = "", elem1!: Int64 = 0, output2!: String = "", elem2!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
   let bus1 = FindBus(output1)
   let bus2 = FindBus(output2)
   let wire1 = NewWire(bus1, elem1)
   let wire2 = NewWire(bus2, elem2)
   OpMToN(gen, name: name, wires: ArrayList<Wire>([wire1, wire2]), input: input)
}

/**
 * Create a hypergraph for an operation 0 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpZeroToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = ""){ 
    OpMToOne(gen, output: output, elem: elem, name: name) 
}
/**
 * Create a hypergraph for an operation 1 -> 0
 * @param gen   The generator that corresponds to this operation
 * @param name  The name of the resulting hypergraph
 * @param input The optional input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToZero(gen : Generator, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToZero(gen, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 1 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    OpMToOne(gen, output: output, elem: elem, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToOne(gen, output: output, elem: elem, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param lhs   The hypergraph that will be the first argument to this operation
 * @param rhs   The hypergraph that will be the second argument to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", lhs!: Option<Hypergraph>, rhs!: Option<Hypergraph>){
    let lhs = match(lhs){
        case Some(f) => f
        case $None   => Identity(1)
    }
    let rhs = match(rhs){
        case Some(f) => f
        case $None   => Identity(1)
    }
    OpMToOne(gen, output: output, elem: elem, name: name, input: Concat([lhs,rhs]))
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToOne(gen, output: output, elem: elem, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param x     The hypergraph that will be the first argument to this operation
 * @param y     The hypergraph that will be the second argument to this operation
 * @param z     The hypergraph that will be the third argument to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", x!: Option<Hypergraph>, y!: Option<Hypergraph>, z!: Option<Hypergraph>){
    let x = match(x){
        case Some(f) => f
        case $None   => Identity(1)
    }
    let y = match(y){
        case Some(f) => f
        case $None   => Identity(1)
    }
    let z = match(z){
        case Some(f) => f
        case $None   => Identity(1)
    }
    OpMToOne(gen, output: output, elem: elem, name: name, input: Concat([x,y,z]))
}
/**
 * Create a hypergraph for an operation 1 -> 2
 * @param gen   The generator that corresponds to this operation
 * @param lhs   The name of the first output port
 * @param rhs   The name of the second output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToTwo(gen : Generator, output1!: String = "", elem1!: Int64 = 0, output2!: String = "", elem2!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToTwo(gen, output1: output1, elem1: elem1, output2: output2, elem2: elem2, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 1 -> 2
 * @param gen   The generator that corresponds to this operation
 * @param out   The name of the output bus
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToTwo(gen : Generator, output!: String = "", elem!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToTwo(gen, output1: output, elem1: elem, output2: output, elem2: elem + 1, name: name, input: input) 
}

/**
 * Create a hypergraph for a bottom value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a bottom value
 */
external func Bottom(output!: String = "", elem!: Int64 = 0) { 
    OpZeroToOne(VALUE(BOTTOM), output: output, elem: elem, name: "Bottom") 
}
/**
 * Create a hypergraph for a top value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a top value
 */
external func Top(output!: String = "", elem!: Int64 = 0){
    OpZeroToOne(VALUE(TOP), output: output, elem: elem, name: "Top")
}
/**
 * Create a hypergraph for a true value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a true value
 */
external func True(output!: String = "", elem!: Int64 = 0) { 
    OpZeroToOne(VALUE(TRUE), output: output, elem: elem, name: "True") 
}
/**
 * Create a hypergraph for a false value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a false value
 */
external func False(output!: String = "", elem!: Int64 = 0){
    OpZeroToOne(VALUE(FALSE), output: output, elem: elem, name: "False")
}

/**
 * Create a hypergraph for a fork
 * @param input=None   The input to the fork
 * @param lhs=""       The name of the first output port
 * @param rhs=""       The name of the second output port
 * @param name=""      The name of the resulting hypergraph
 * @return A hypergraph for a fork
 */
external func Fork(output1!: String = "", elem1!: Int64 = 0, output2!: String = "", elem2!: Int64 = 0, input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpOneToTwo(FORK, output1: output1, elem1: elem1, output2: output2, elem2: elem2, name: "Fork", input: input) 
}
/**
 * Create a hypergraph for a join
 * @param input=None The input to the join
 * @param port=""    The name of the output port
 * @param name=""    The name of the resulting hypergraph
 * @return A hypergraph for a join
 */
external func Join(output!: String = "", elem!: Int64 = 0,  input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpTwoToOne(JOIN, output: output, name: "Join", input: input) 
}
/**
 * Create a hypergraph for a join
 * @param lhs        The first input to the join
 * @param rhs        The second input to the join
 * @param port=""    The name of the output port
 * @param name=""    The name of the resulting hypergraph
 * @return A hypergraph for a join
 */
external func Join(output!: String = "", elem!: Int64 = 0, lhs!: Option<Hypergraph>, rhs!: Option<Hypergraph>){
    OpTwoToOne(JOIN, output: output, elem: elem, name: "Join", lhs: lhs, rhs: rhs)
}
/**
 * Create a hypergraph for a stub
 * @param input=None  The input to the stub
 * @param port=""     The name of the output port
 * @param name=""     The name of the resulting hypergraph
 * @return A hypergraph for a stub
 */
external func Stub(input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpOneToZero(STUB, name: "Stub", input: input) 
}

/**
 * Create a copy hypergraph n -> 2n
 * @param n The number of wires to copy
 * @return The copy hypergraph
 */
func CreateCopy(n : Int64, output1!: String = "", output2!: String = "") : Hypergraph {
    if(n < 0){
        throw NegativeWireException("CreateCopy")
    }
    if(n == 0){
        Empty()
    } else {
        let c1 = Par(CreateCopy(n-1, output1: output1, output2: output2), Fork(output1: output1, elem1: n-1, output2: output2, elem2: n-1))
        let c2 = Par([Identity(n-1), Swap(n-1,1), Identity(1)])
        Seq(c1,c2, name: "Copy ${n}")
    }
}
/**
 * Create a copy hypergraph n -> 2n
 * @param n       The number of wires to copy
 * @param name    The name of the resulting hypergraph
 * @param output1 The labels of the first output bus
 * @param output2 The label of the second output bus
 * @param input   The input to the copy
 * @return        A hypergraph for a copy
 */
external func Copy(n : Int64, name!: String = "", output1!: String = "", output2!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    match(input){
        case Some(f) => {
            if(f.GetN() != 2 * n){
                    throw BadInputException("Copy", "input", n, f.GetName(), f.GetN())
            }
        }
        case $None   => {}
    }
    let copy = CreateCopy(n, output1: output1, output2: output2)
    match(input){
        case Some(f) => Seq(f, copy, name: name)
        case $None   => copy
    }
}
/**
 * Create an erase hypergraph n -> 0
 * @param n The number of wires to erase
 * @return A hypergraph for an erase
 */
func CreateErase(n : Int64, name!: String = "") : Hypergraph {
    if(n == 0){
        Empty(name: name)
    } else {
        CreateErase(n-1, name: name)
    }
}
/**
 * Create an erase hypergraph n -> 0
 * @param n     The number of wires to copy
 * @param input The input to the erase
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a erase
 */
external func Erase(n : Int64, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    let erase = CreateErase(n, name: name)
    match(input){
        case Some(f) => Seq(f, CreateErase(n), name: name)
        case $None   => erase
    }
}
/**
 * Create a merge hypergraph 2n -> n
 * @param n The number of wires to copy
 * @return The copy hypergraph
 */
external func CreateMerge(n : Int64, name!: String = "", output!: String = "") : Hypergraph {
    if(n < 0){
        throw NegativeWireException("CreateMerge")
    }
    if(n == 0){
        Empty(name: name)
    } else {
        let m1 = Par([Identity(n-1), Swap(n-1,1), Identity(1)])
        let m2 = Par(Merge(n-1, output: output), Join(output: output, elem: n-1))
        Seq(m1, m2, name: name)
    }
}
/**
 * Create a merge hypergraph 2n -> n
 * @param n      The number of wires to merge
 * @param input  The input to the merge
 * @param labels The labels of the output ports
 * @param name   The name of the resulting hypergraph
 * @return A hypergraph for a merge
 */
external func Merge(n : Int64, name!: String = "", output!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    match(input){
        case Some(f) => {
            if(f.GetN() != 2 * n){
                    throw BadInputException("Merge", "input", 2 * n, f.GetName(), f.GetN())
            }
        }
        case $None   => {}
    }
    let merge = CreateMerge(n, name: name, output: output)
    match(input){
        case Some(f) => Seq(f, merge, name: name)
        case $None   => merge
    }
}
/**
 * Create an init hypergraph 0 -> n
 * @param n The number of wires to init
 * @return A hypergraph for an init
 */
external func CreateInit(n : Int64, name!: String = "", output!: String = "") : Hypergraph {
    if(n == 0){
        Empty(name: name)
    } else {
        Par(Init(n-1, output: output), Bottom(output: output, elem: n-1), name: name)  
    }
}
/**
 * Create an init hypergraph 0 -> n
 * @param n      The number of wires to init
 * @param input  The input to the erase
 * @param labels The labels of the output ports
 * @param name   The name of the resulting hypergraph
 * @return A hypergraph for a erase
 */
external func Init(n : Int64, name!: String = "", output!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    let ini = CreateInit(n, output: output, name: name)
    match(input){
        case Some(f) => Seq(f, ini, name: name)
        case $None   => ini
    }
}

external func NotGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpOneToOne(NOT, output: output, elem: elem, name: name, input: input) 
}
external func AndGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(AND, output: output, elem: elem, name: name, input: input) 
}
external func AndGate(lhs!: Hypergraph, rhs!: Hypergraph, output!: String = "", elem!: Int64 = 0, name!: String = ""){ 
    OpTwoToOne(AND, output: output, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func OrGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(OR, output: output, elem: elem, name: name, input: input) 
}
external func OrGate(lhs!: Hypergraph, rhs!: Hypergraph, output!: String = "", elem!: Int64 = 0, name!: String = ""){ 
    OpTwoToOne(OR, output: output, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func XorGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(XOR, output: output, elem: elem, name: name, input: input) 
}
external func XorGate(lhs!: Hypergraph, rhs!: Hypergraph, output!: String = "", elem!: Int64 = 0, name!: String = ""){ 
    OpTwoToOne(XOR, output: output, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func NandGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(NAND, output: output, elem: elem, name: name, input: input) 
}
external func NandGate(lhs!: Hypergraph, rhs!: Hypergraph, output!: String = "", elem!: Int64 = 0, name!: String = ""){
    OpTwoToOne(NAND, output: output, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func NorGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(NOR, output: output, elem: elem, name: name, input: input) 
}
external func NorGate(lhs!: Hypergraph, rhs!: Hypergraph, output!: String = "", elem!: Int64 = 0, name!: String = ""){ 
    OpTwoToOne(NOR, output: output, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func XnorGate(output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(XNOR, output: output, elem: elem, name: name, input: input) 
}
external func XnorGate(lhs!: Hypergraph, rhs!: Hypergraph, output!: String = "", elem!: Int64 = 0, name!: String = ""){ 
    OpTwoToOne(XNOR, output: output, elem: elem, name: name, lhs: lhs, rhs: rhs)
}

external func Mux(width!: Int64, output!: String = "", elem!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    let muxInputs = 2 * width + 1
    match(input){
        case Some(f) => {
            if(f.GetN() != 2 * width + 1){
                throw BadInputException("Mux", "input", muxInputs, f.GetName(), f.GetN())
            }
        }
        case $None => {}
    }
    let wires = ArrayList<Wire>()
    let hb = HypBuilder(muxInputs, width, output, elem)
    var currentC = hb.GetInputs()[muxInputs - 1]
    if(width > 1){
        for(i in 0..width-1){
            // Go from bottom to top
            let j = width - i - 1
            // Create a fork to split the control signal
            let fork = hb.CreateEdge(FORK, [currentC])
            // Create the mux edge
            let mux = hb.CreateEdge(MUX, [hb.GetInputs()[j], hb.GetInputs()[j + width], fork.targets[1]], [hb.GetOutputs()[j]])
            // Assign the control wire for the next iteration
            currentC = fork.targets[0]
        }
    }
    // Create the final mux edge
    let mux = hb.CreateEdge(MUX, [hb.GetInput(0), hb.GetInputs()[width], currentC], [hb.GetOutput(0)])
    let res = hb.ToGraph()
    match(input){
        case Some(f) => Seq(f, res)
        case $None   => res
    }
}

external func Mux(width!: Int64, output!: String = "", elem!: Int64 = 0, name!: String = "", a!: Hypergraph, b!: Hypergraph, s!: Option<Hypergraph> = None<Hypergraph>){
    if(a.GetN() != width){
        throw BadInputException("Mux", "a", width, a.GetName(), a.GetN())
    }
    if(b.GetN() != width){
        throw BadInputException("Mux", "b", width, b.GetName(), b.GetN())
    }
    let z = match(s){
        case Some(f) => {
            if(f.GetN() != 1){
                throw BadInputException("Mux", "s", width, f.GetName(), f.GetN())
            }
            f
        }
        case $None   => Identity(1)
    }
    Mux(width: width, output: output, elem: elem, name: name, input: Concat([a,b,z]))
}

