/**
 * gates.cj
 *
 * This file contains gates that can be used in a circuit
 */

package circuits

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
        case $None => ()
        case Some(f) =>
            if(f.GetN() != dom){
                throw BadInputGraphException("OpMToN - ${generator}", "input", dom, f.GetName(), f.GetN())
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
/**
 * Create a hypergraph for a given operation of m -> 0
 * @param gen   The generator that corresponds to this operation
 * @param name  The name to give the resulting hypergraph
 * @param input The hypergraph to compose to the front of this operation
 * @return A hypergraph corresponding to this operation
 */
func OpMToZero(gen : Generator, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    OpMToN(gen, name: name, wires: ArrayList<Wire>(), input: input)
}
/**
 * Create a hypergraph for a given operation of m -> 1
 * @param gen    The generator that corresponds to this operation
 * @param output The name to assign to the output bus - if elem is not provided, this must be unique
 * @param elem   The element of the bus to assign the output to
 * @param name   The name to give the resulting hypergraph
 * @param input  The hypergraph to compose to the front of this operation
 * @return A hypergraph corresponding to this operation
 */
func OpMToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    let wire = if(elem < 0){
        let bus = NewBus(label)
        NewWire(bus)
    } else {
        NewWire(label, elem)
    }
    let wires : ArrayList<Wire> = ArrayList<Wire>([wire])
    OpMToN(gen, name: name, wires: wires, input: input)
}
/**
 * Create a hypergraph for a given operation of m -> 2
 * @param gen     The generator that corresponds to this operation
 * @param output1 The name to assign to the first output bus - if elem1 is not provided, this must be unique
 * @param elem1   The element of the first bus to assign the output to
 * @param output2 The name to assign to the second output bus - if elem2 is not provided, this must be unique
 * @param elem2   The element of the second bus to assign the output to
 * @param name    The name to give the resulting hypergraph
 * @param input   The hypergraph to compose to the front of this operation
 * @return A hypergraph corresponding to this operation
 */
func OpMToTwo(gen : Generator, output1!: String = "", elem1!: Int64 = 0, output2!: String = "", elem2!: Int64 = 0, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
   let wire1 = if(elem1 < 0){
        let bus = NewBus(output1)
        NewWire(bus)
    } else {
        NewWire(output1, elem1)
    }
    let wire2 = if(elem2 < 0){
        let bus = NewBus(output2)
        NewWire(bus)
    } else {
        NewWire(output2, elem2)
    }
   OpMToN(gen, name: name, wires: ArrayList<Wire>([wire1, wire2]), input: input)
}
/**
 * Create a hypergraph for an operation 0 -> 1
 * @param gen    The generator that corresponds to this operation
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param name   The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpZeroToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = ""){ 
    OpMToOne(gen, label: label, elem: elem, name: name) 
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
 * @param gen    The generator that corresponds to this operation
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param name   The name of the resulting hypergraph
 * @param input  The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    OpMToOne(gen, label: label, elem: elem, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen    The generator that corresponds to this operation
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param name   The name of the resulting hypergraph
 * @param input  The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToOne(gen, label: label, elem: elem, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen    The generator that corresponds to this operation
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param name   The name of the resulting hypergraph
 * @param lhs    The hypergraph that will be the first argument to this operation
 * @param rhs    The hypergraph that will be the second argument to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", lhs!: Option<Hypergraph>, rhs!: Option<Hypergraph>){
    let lhs = match(lhs){
        case Some(f) => f
        case $None   => Identity(1)
    }
    let rhs = match(rhs){
        case Some(f) => f
        case $None   => Identity(1)
    }
    OpMToOne(gen, label: label, elem: elem, name: name, input: Concat([lhs,rhs]))
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToOne(gen, label: label, elem: elem, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param x     The hypergraph that will be the first argument to this operation
 * @param y     The hypergraph that will be the second argument to this operation
 * @param z     The hypergraph that will be the third argument to this operation
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", x!: Option<Hypergraph>, y!: Option<Hypergraph>, z!: Option<Hypergraph>){
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
    OpMToOne(gen, label: label, elem: elem, name: name, input: Concat([x,y,z]))
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
 * @param gen    The generator that corresponds to this operation
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param name   The name of the resulting hypergraph
 * @param input  The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToTwo(gen : Generator, label!: String = "", elem!: Int64 = -1, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToTwo(gen, output1: label, elem1: elem, output2: label, elem2: elem + 1, name: name, input: input) 
}

/**
 * Create a hypergraph for a bottom value
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @return A hypergraph for a bottom value
 */
external func Bottom(label!: String = "", elem!: Int64 = -1) { 
    OpZeroToOne(VALUE(BOTTOM), label: label, elem: elem, name: "Bottom") 
}
/**
 * Create a hypergraph for a top value
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @return A hypergraph for a top value
 */
external func Top(label!: String = "", elem!: Int64 = -1){
    OpZeroToOne(VALUE(TOP), label: label, elem: elem, name: "Top")
}
/**
 * Create a hypergraph for a true value
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @return A hypergraph for a true value
 */
external func True(label!: String = "", elem!: Int64 = -1) { 
    OpZeroToOne(VALUE(TRUE), label: label, elem: elem, name: "True") 
}
/**
 * Create a hypergraph for a false value
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @return A hypergraph for a false value
 */
external func False(label!: String = "", elem!: Int64 = -1){
    OpZeroToOne(VALUE(FALSE), label: label, elem: elem, name: "False")
}
/**
 * Create a hypergraph for a fork
 * @param output1 The label of the first bus to assign the output to, if elem is not provided this must be unique
 * @param elem1   The element of the first bus to assign to output to
 * @param output2 The label of the second bus to assign the output to, if elem is not provided this must be unique
 * @param elem2   The element of the second bus to assign to output to
 * @param input   The input to the fork
 * @return A hypergraph for a fork
 */
external func Fork(output1!: String = "", elem1!: Int64 = 0, output2!: String = "", elem2!: Int64 = 0, input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpOneToTwo(FORK, output1: output1, elem1: elem1, output2: output2, elem2: elem2, name: "Fork", input: input) 
}
/**
 * Create a hypergraph for a join
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param input  The input to the join
 * @return A hypergraph for a join
 */
external func Join(label!: String = "", elem!: Int64 = -1,  input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpTwoToOne(JOIN, label: label, name: "Join", input: input) 
}
/**
 * Create a hypergraph for a join
 * @param output The label of the bus to assign the output to, if elem is not provided this must be unique
 * @param elem   The element of the bus to assign to output to
 * @param lhs    The first input to the join
 * @param rhs    The second input to the join
 * @return A hypergraph for a join
 */
external func Join(label!: String = "", elem!: Int64 = -1, lhs!: Option<Hypergraph>, rhs!: Option<Hypergraph>){
    OpTwoToOne(JOIN, label: label, elem: elem, name: "Join", lhs: lhs, rhs: rhs)
}
/**
 * Create a hypergraph for a stub
 * @param input  The input to the stub
 * @return A hypergraph for a stub
 */
external func Stub(input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpOneToZero(STUB, name: "Stub", input: input) 
}
/**
 * Create a copy hypergraph n -> 2n
 * @param n The number of wires to copy
 * @param output1 The name of the first bus
 * @param output2 The name of the second bus
 * @return The copy hypergraph
 */
func CreateCopy(n : Int64, output1!: String = "", output2!: String = "") : HypBuilder {
    if(n < 0){
        throw NegativeWireException("CreateCopy")
    }
    if(n == 0){
        HypBuilder()
    } else {
        // Create the 'head' of this copy, which is just a fork
        // This is actually at the bottom of the stack to make numbering the outputs easier
        let headCopy = HypBuilder(1, 2, [NewWire(output1, n), NewWire(output2, n-1)])
        headCopy.CreateEdge(FORK, [headCopy.GetInput(0)], [headCopy.GetOutput(0), headCopy.GetOutput(1)])
        // Create the 'tail' of this copy, which is Copy(n-1)
        let tailCopy = CreateCopy(n-1, output1: output1, output2: output2) 
        // Stick the head and the tail together
        let completeCopy = HypBuilder()
        // The tail inputs are on top
        completeCopy.AddInputs(tailCopy.GetInputs())
        // Then add the head input
        completeCopy.AddInput(headCopy.GetInput(0))
        // Add the first half of the tail outputs
        for(i in 0..n-1){
            completeCopy.AddOutput(tailCopy.GetOutput(i))
        }
        // Add the first head output
        completeCopy.AddOutput(headCopy.GetOutput(0))
        // Add the second half of the tail outputs
        for(i in 0..n-1){
            completeCopy.AddOutput(tailCopy.GetOutput(n - 1 + i))
        }
        // Add the second head output
        completeCopy.AddOutput(headCopy.GetOutput(1))
        // Add the edges from both head and tail
        completeCopy.AddEdges(tailCopy.GetEdges())
        completeCopy.AddEdges(headCopy.GetEdges())
        // Return the completed builder
        completeCopy
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
        case Some(f) =>
            if(f.GetN() != 2 * n){
                    throw BadInputGraphException("Copy", "input", n, f.GetName(), f.GetN())
            }
        case $None   => ()
    }

    NewBus(output1)
    NewBus(output2)
    let copy = CreateCopy(n, output1: output1, output2: output2).ToGraph()
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
external func CreateMerge(n : Int64, name!: String = "", label!: String = "") : Hypergraph {
    if(n < 0){
        throw NegativeWireException("CreateMerge")
    }
    if(n == 0){
        Empty(name: name)
    } else {
        let m1 = Par([Identity(n-1), Symmetry(n-1,1), Identity(1)])
        let m2 = Par(Merge(n-1, label: label), Join(label: label, elem: n-1))
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
external func Merge(n : Int64, name!: String = "", label!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    match(input){
        case Some(f) =>
            if(f.GetN() != 2 * n){
                    throw BadInputGraphException("Merge", "input", 2 * n, f.GetName(), f.GetN())
            }
        case $None   => ()
    }
    let merge = CreateMerge(n, name: name, label: label)
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
external func CreateInit(n : Int64, name!: String = "", label!: String = "") : Hypergraph {
    if(n == 0){
        Empty(name: name)
    } else {
        Par(Init(n-1, label: label), Bottom(label: label, elem: n-1), name: name)  
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
external func Init(n : Int64, name!: String = "", label!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    let ini = CreateInit(n, label: label, name: name)
    match(input){
        case Some(f) => Seq(f, ini, name: name)
        case $None   => ini
    }
}

external func NotGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpOneToOne(NOT, label: label, elem: elem, name: name, input: input) 
}
external func AndGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(AND, label: label, elem: elem, name: name, input: input) 
}
external func AndGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", elem!: Int64 = -1, name!: String = ""){ 
    OpTwoToOne(AND, label: label, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func OrGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(OR, label: label, elem: elem, name: name, input: input) 
}
external func OrGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", elem!: Int64 = -1, name!: String = ""){ 
    OpTwoToOne(OR, label: label, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func XorGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph { 
    OpTwoToOne(XOR, label: label, elem: elem, name: name, input: input) 
}
external func XorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", elem!: Int64 = -1, name!: String = ""){ 
    OpTwoToOne(XOR, label: label, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func NandGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(NAND, label: label, elem: elem, name: name, input: input) 
}
external func NandGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", elem!: Int64 = -1, name!: String = ""){
    OpTwoToOne(NAND, label: label, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func NorGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(NOR, label: label, elem: elem, name: name, input: input) 
}
external func NorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", elem!: Int64 = -1, name!: String = ""){ 
    OpTwoToOne(NOR, label: label, elem: elem, name: name, lhs: lhs, rhs: rhs) 
}

external func XnorGate(label!: String = "", elem!: Int64 = -1, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpTwoToOne(XNOR, label: label, elem: elem, name: name, input: input) 
}
external func XnorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", elem!: Int64 = -1, name!: String = ""){ 
    OpTwoToOne(XNOR, label: label, elem: elem, name: name, lhs: lhs, rhs: rhs)
}

external func Mux(width!: Int64 = 1, label!: String = "", elem!: Int64 = -1, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    Debug("Mux", "Creating mux of width ${width}")
    let muxInputs = 2 * width + 1
    match(input){
        case Some(f) =>
            if(f.GetN() != 2 * width + 1){
                throw BadInputGraphException("Mux", "input", muxInputs, f.GetName(), f.GetN())
            }
        case $None => ()
    }
    let wires = ArrayList<Wire>()
    let hb = if(elem < 0) { HypBuilder(muxInputs, width, label) } else { HypBuilder(muxInputs, width, label, elem) }
    var currentC = hb.GetInputs()[muxInputs - 1]
    if(width > 1){
        for(i in 0..width-1){
            // Go from bottom to top
            let j = width - i - 1
            // Create a fork to split the control signal
            let fork = hb.CreateEdge(FORK, [currentC])
            // Create the mux edge
            let mux = hb.CreateEdge(MUX, [hb.GetInputs()[j], hb.GetInputs()[j + width], fork.GetTarget(1)], [hb.GetOutputs()[j]])
            // Assign the control wire for the next iteration
            currentC = fork.GetTarget(0)
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

external func Mux(width!: Int64 = 1, label!: String = "", elem!: Int64 = -1, name!: String = "", low!: Hypergraph, high!: Hypergraph, sel!: Option<Hypergraph> = None<Hypergraph>){
    if(low.GetN() != width){
        throw BadInputGraphException("Mux", "low", width, low.GetName(), low.GetN())
    }
    if(high.GetN() != width){
        throw BadInputGraphException("Mux", "high", width, high.GetName(), high.GetN())
    }
    let z = match(sel){
        case Some(f) =>
            if(f.GetN() != 1){
                throw BadInputGraphException("Mux", "sel", 1, f.GetName(), f.GetN())
            }
            f
        case $None   => Identity(1)
    }
    let f = Concat([low,high,z])
    Mux(width: width, label: label, elem: elem, name: name, input: f)
}

func BlackBox(label: String, dom: Int64, cod: Int64, wires!: ArrayList<Wire> = ArrayList<Wire>(), input!: Option<Hypergraph> = None<Hypergraph>, name!: String = ""){
    if(dom < 0){
        throw NegativeNumberException("BlackBox", dom)
    }
    if(cod < 0){
        throw NegativeNumberException("BlackBox", cod)
    }
    if(wires.size() == 0){
        for(i in 0..cod){
            wires.add(NewWire())
        }
    } else if(wires.size() != cod){
        throw BadOutputLabelsException("BlackBox", wires.size(), cod)
    }
    let gen = BLACKBOX(Label(label, dom, cod))
    OpMToN(gen, wires: wires, input: input, name: name)
}