/**
 * generators.cj
 *
 * This file contains components that can be used in a circuit
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
func OpMToN(m : Int64, n : Int64, generator : Generator, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>, input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {

    Debug("OpMToN - ${generator}", "Creating operation, labels = ${LabelsOptToString(labels)}")

    let (dom, cod) = match(generator){
        case VALUE(val)        => (0,1)
        case STRUCTURAL(label) => (label.dom, label.cod)
        case GATE(label)       => (label.dom, label.cod)
        case DELAY(dur)        => (1,1)
        case $IDENTITY          => (1,1)
        case INLINK(spec)      => (0, spec.width)
        case OUTLINK(spec)     => (spec.width, 0)
    }
    if(m != dom || m < 0){
        throw BadDomainException("OpMToN - ${generator}", m, dom)
    }
    if(n != cod || n < 0){
        throw BadCodomainException("OpMToN - ${generator}", n, cod)
    }

    match(labels){
        case $None => {}
        case Some(ls) => {
            if(ls.size() != n){
                    throw BadOutputLabelsException("OpMToN - ${generator}", ls.size(), n)
            }
        }
    }
    match(input){
        case $None => {}
        case Some(f) => {
            if(f.GetN() != m){
                throw BadInputException("OpMToN - ${generator}", "input", m, f.GetName(), f.GetN())
            }
        }
    }
    

    let busMap = MapBuilder<String, Bus>()

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x => Source()})

    let op = Edge(generator, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i in 0..m) {
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }
    let labelledOutputs = match(labels){
        case Some(ls) => AddBusesToOutputs(ls, outputs)
        case $None    => outputs
    }
    let f = Hypergraph(name, ArrayList<Edge>([op]), inputs, labelledOutputs, conns.toMap())
    match(input){
        case Some(g) => Seq(g, f)
        case $None   => f
    }
}

func OpMToZero(m : Int64, gen : Generator, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    OpMToN(m, 0, gen, name: name, input: input)
}

func OpMToOne(m : Int64, gen : Generator, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    label == "" ? OpMToN(m, 1, gen, name: name, input: input) : OpMToN(m, 1, gen, name: name, labels: ArrayList<String>([label]), input: input)
}

func OpMToTwo(m : Int64, gen : Generator, lhs!: String = "", rhs!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    lhs == "" && rhs == "" ? OpMToN(m, 1, gen, name: name, input: input) : OpMToN(m, 1, gen, name: name, labels: ArrayList<String>([lhs, rhs]), input: input)
}

/**
 * Create a hypergraph for an operation 0 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpZeroToOne(gen : Generator, label!: String = "", name!: String = ""){ 
    OpMToOne(0, gen, label: label, name: name) 
}
/**
 * Create a hypergraph for an operation 1 -> 0
 * @param gen   The generator that corresponds to this operation
 * @param name  The name of the resulting hypergraph
 * @param input The optional input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToZero(gen : Generator, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToZero(1, gen, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 1 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToOne(gen : Generator, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    OpMToOne(1, gen, label: label, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToOne(2, gen, label: label, name: name, input: input) 
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
func OpTwoToOne(gen : Generator, label!: String = "", name!: String = "", lhs!: Option<Hypergraph>, rhs!: Option<Hypergraph>){
    let lhs = match(lhs){
        case Some(f) => f
        case $None   => Identity(1)
    }
    let rhs = match(rhs){
        case Some(f) => f
        case $None   => Identity(1)
    }
    OpMToOne(2, gen, label: label, name: name, input: Output([lhs,rhs]))
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToOne(3, gen, label: label, name: name, input: input) 
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
func OpThreeToOne(gen : Generator, label!: String = "", name!: String = "", x!: Option<Hypergraph>, y!: Option<Hypergraph>, z!: Option<Hypergraph>){
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
    OpMToOne(3, gen, label: label, name: name, input: Output([x,y,z]))
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
func OpOneToTwo(gen : Generator, lhs!: String = "", rhs!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToTwo(1, gen, lhs: lhs, rhs: rhs, name: name, input: input) 
}
/**
 * Create a hypergraph for an operation 1 -> 2
 * @param gen   The generator that corresponds to this operation
 * @param out   The name of the output bus
 * @param name  The name of the resulting hypergraph
 * @param input The hypergraph that will be input to this operation
 * @return The hypergraph corresponding to this operation
 */
func OpOneToTwo(gen : Generator, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpMToTwo(1, gen, lhs: label, rhs: label, name: name, input: input) 
}

/**
 * Create a hypergraph for a bottom value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a bottom value
 */
external func Bottom(label!: String = "") { 
    OpZeroToOne(VALUE(BOTTOM), label: label, name: "Bottom") 
}
/**
 * Create a hypergraph for a top value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a top value
 */
external func Top(label!: String = ""){
    OpZeroToOne(VALUE(TOP), label: label, name: "Top")
}
/**
 * Create a hypergraph for a true value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a true value
 */
external func True(label!: String = "") { 
    OpZeroToOne(VALUE(TRUE), label: label, name: "True") 
}
/**
 * Create a hypergraph for a false value
 * @param label="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a false value
 */
external func False(label!: String = ""){
    OpZeroToOne(VALUE(FALSE), label: label, name: "False")
}

/**
 * Create a hypergraph for a fork
 * @param input=None   The input to the fork
 * @param lhs=""       The name of the first output port
 * @param rhs=""       The name of the second output port
 * @param name=""      The name of the resulting hypergraph
 * @return A hypergraph for a fork
 */
external func Fork(input!: Option<Hypergraph> = None<Hypergraph>, lhs!: String = "", rhs!: String = "") { 
    OpOneToTwo(FORK, lhs: lhs, rhs: rhs, name: "Fork", input: input) 
}
/**
 * Create a hypergraph for a join
 * @param input=None The input to the join
 * @param port=""    The name of the output port
 * @param name=""    The name of the resulting hypergraph
 * @return A hypergraph for a join
 */
external func Join(label!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>){ 
    OpTwoToOne(JOIN, label: label, name: "Join", input: input) 
}
/**
 * Create a hypergraph for a join
 * @param lhs        The first input to the join
 * @param rhs        The second input to the join
 * @param port=""    The name of the output port
 * @param name=""    The name of the resulting hypergraph
 * @return A hypergraph for a join
 */
external func Join(lhs!: Option<Hypergraph>, rhs!: Option<Hypergraph>, label!: String = ""){
    OpTwoToOne(JOIN, label: label, name: "Join", lhs: lhs, rhs: rhs)
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
func CreateCopy(n : Int64, labels!: Option<ArrayList<String>> = None<ArrayList<String>>) : Hypergraph {
    if(n < 0){
        throw NegativeWireException("CreateCopy")
    }
    match(labels){
        case $None    => {}
        case Some(ls) => {
            if(ls.size() != 2 * n){
                throw BadOutputLabelsException("CreateCopy", ls.size(), 2 * n)
            }
        }
    }
    if(n == 0){
        Empty()
    } else {
        let c1 = Par(CreateCopy(n-1), Fork())
        let c2 = Par([Identity(n-1), Swap(n-1,1), Identity(1)])
        match(labels){
            case Some(ls) => Seq(c1,c2, name: "Copy ${n}", labels: ls)
            case $None    => Seq(c1,c2, name: "Copy ${n}")
        }
    }
}
/**
 * Create a copy hypergraph n -> 2n
 * @param n     The number of wires to copy
 * @param labels The labels of the output ports
 * @param name  The name of the resulting hypergraph
 * @param input The input to the copy
 * @return A hypergraph for a copy
 */
external func Copy(n : Int64, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>, input!: Option<Hypergraph> = None<Hypergraph>){
    match(input){
        case Some(f) => {
            let copy = CreateCopy(n)
            Seq(f, copy, name: name, labels: labels)
        }
        case $None   => {
            let copy = CreateCopy(n, labels: labels)
            copy
        }
    }
}
/**
 * Create a copy hypergraph n -> 2n
 * @param n     The number of wires to copy
 * @param input The input to the copy
 * @param lhs   The labels of the lhs copy ports
 * @param rhs   The labels of the rhs copy ports
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a copy
 */
external func Copy(n : Int64, name!: String = "", labelLHS!:String, labelRHS!:String, input!: Option<Hypergraph> = None<Hypergraph>){
    Copy(n, input: input, labels: ArrayList<String>(2 * n, {x : Int64 => x < n ? labelLHS : labelRHS}), name: name)
}
/**
 * Create an erase hypergraph n -> 0
 * @param n The number of wires to erase
 * @return A hypergraph for an erase
 */
func CreateErase(n : Int64, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>) : Hypergraph {
    if(n == 0){
        Empty(name: name)
    } else {
        let erase = CreateErase(n-1, name: name)
        match(labels){
            case Some(ls) => Par(Stub(), erase, name: name, labels: labels)
            case $None    => Par(Stub(), erase, name: name)
        }
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
external func CreateMerge(n : Int64, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>) : Hypergraph {
    if(n < 0){
        throw NegativeWireException("CreateMerge")
    }
    match(labels){
        case $None    => {}
        case Some(ls) => {
            if(ls.size() != n) {
                throw BadOutputLabelsException("CreateMerge", ls.size(), n)
            }
        }
    }
    if(n == 0){
        Empty(name: name)
    } else {
        let m1 = Par([Identity(n-1), Swap(n-1,1), Identity(1)])
        let m2 = Par(Merge(n-1), Join())
        match(labels){
            case Some(ls) => Seq(m1, m2, labels: ls, name: name)
            case $None    => Seq(m1, m2, name: name)
        }
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
external func Merge(n : Int64, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>, input!: Option<Hypergraph> = None<Hypergraph>){
    match(input){
        case Some(f) => {
            if(f.GetN() != 2 * n){
                    throw BadInputException("Merge", "input", 2 * n, f.GetName(), f.GetN())
            }
        }
        case $None   => {}
    }
    let merge = CreateMerge(n, name: name, labels: labels)
    match(input){
        case Some(f) => Seq(f, merge, name: name)
        case $None   => merge
    }
}
/**
 * Create a merge hypergraph 2n -> n
 * @param n      The number of wires to merge
 * @param input  The input to the merge
 * @param label  The label of the output ports
 * @param name   The name of the resulting hypergraph
 * @return A hypergraph for a merge
 */
external func Merge(n : Int64, label!: String, name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    Merge(n, input: input, labels: ArrayList<String>(n, {x : Int64 => label}), name: name)
}

/**
 * Create an init hypergraph 0 -> n
 * @param n The number of wires to init
 * @return A hypergraph for an init
 */
external func CreateInit(n : Int64, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>) : Hypergraph {
    if(n == 0){
        Empty(name: name)
    } else {
        let ini = Init(n-1)
        match(labels){
            case Some(ls) => Par(Bottom(), ini, name: name, labels: ls)
            case $None    => Par(Bottom(), ini, name: name)
        }
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
external func Init(n : Int64, name!: String = "", labels!: Option<ArrayList<String>> = None<ArrayList<String>>, input!: Option<Hypergraph> = None<Hypergraph>){
    let ini = CreateInit(n, labels: labels, name: name)
    match(input){
        case Some(f) => Seq(f, ini, name: name)
        case $None   => ini
    }
}

external func NotGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpOneToOne(NOT, label: label, name: name, input: input) }

external func AndGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpTwoToOne(AND, label: label, name: name, input: input) }
external func AndGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(AND, label: label, name: name, lhs: lhs, rhs: rhs) }

external func OrGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpTwoToOne(OR, label: label, name: name, input: input) }
external func OrGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(OR, label: label, name: name, lhs: lhs, rhs: rhs) }

external func XorGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpTwoToOne(XOR, label: label, name: name, input: input) }
external func XorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(XOR, label: label, name: name, lhs: lhs, rhs: rhs) }

external func NandGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpTwoToOne(NAND, label: label, name: name, input: input) }
external func NandGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(NAND, label: label, name: name, lhs: lhs, rhs: rhs) }

external func NorGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpTwoToOne(NOR, label: label, name: name, input: input) }
external func NorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(NOR, label: label, name: name, lhs: lhs, rhs: rhs) }

external func XnorGate(label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpTwoToOne(XNOR, label: label, name: name, input: input) }
external func XnorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(XNOR, label: label, name: name, lhs: lhs, rhs: rhs) }

external func Delay(n : Int64, label!: String = "", name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) { OpOneToOne(DELAY(n), label: label, name: name, input: input) }

external func Register(width!: Int64, initial!: Int64, input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    match(input){
        case Some(f) => {
            if(f.GetN() != width){
                  throw BadInputException("Register", "input", width, f.GetName(), f.GetN())
            }
        }
        case $None => {}
    } 
    let initialValue = SignedValueFromInt(initial, width: width)
    let delays = Par(Delay(1), width)
    print("del\n")
    let merge = Merge(width)
    print("merge\n")
    let reg = Seq(Par(initialValue, delays), merge)
    match(input){
        case Some(f) => Seq(f, reg)
        case $None   => reg
    }
}

external func OutLink(spec!: LinkSpec, name!:String = "", input!: Option<Hypergraph> = None<Hypergraph>) { 
    OpMToZero(spec.width, OUTLINK(spec), name: name, input: input) 
}
external func InLink(spec!: LinkSpec, label!: String = "", name!:String = "") { 
    let labels : Option<ArrayList<String>> = ArrayList<String>(spec.width, {x : Int64 => label})
    OpMToN(0, spec.width, INLINK(spec), labels: labels, name: name) 
}

/**
 * Create an input to the graph with associated handles
 * @param out The name of the bus
 * @param width The width of the bus
 * @return The input circuit
 */
external func Input(label!: String, width!: Int64 = 1){
    if(width < 1){
        throw NegativeWireException("Input")
    }
    Identity(width, label: label)
}

/**
 * Combine a list of hypergraphs into a single hypergraph, ensuring that any shared wires are
 * shared in the resulting hypergraph. The order of the outputs is determined by the 
 * order the hypergraphs are given in
 * @param fs   The list of hypergraphs
 * @param name The name of the resulting hypergraph
 */
external func Output(fs : ArrayList<Hypergraph>, name!: String = ""){
    var f = fs[0]
    var encounteredWires = ArrayList<Wire>(f.GetWires())
    for(i in 1..fs.size()){
        var g = fs[i]
        let visited = ArrayList<Edge>()
        let frontier = ArrayList<Source>(g.GetOutputs())
        while(frontier.size() != 0){
            let v = frontier.removeAt(0)
            for(w in v.wires){
                if(includes(encounteredWires, w)){
                    g = RemoveLeft(g, w)
                } else {
                    encounteredWires.add(w)
                }
            }
        }
        f = Inject(f, g, name: name)
    }
    f
}
/**
 * Combine a list of hypergraphs into a single hypergraph, ensuring that any shared wires are
 * shared in the resulting hypergraph. The order of the outputs is determined by the 
 * order the hypergraphs are given in
 * @param fs   The list of hypergraphs
 * @param name The name of the resulting hypergraph
 */
external func Output(fs : List<Hypergraph>, name!: String = ""){
    Output(ArrayList<Hypergraph>(fs), name: name)
}

external func TestComponents() {
    //let a = AndGate(label: "hello")
    //let b = NotGate(label: "Not")
    //let c = Seq(a, b)
    //print(DotGraph(c))
    return 0
}

