/**
 * generators.cj
 *
 * This file contains components that can be used in a circuit
 */

package hypergraphs

/**
 * Create a hypergraph for a given operation
 * @param m         The inputs of the operation
 * @param n         The outputs of the operation
 * @param generator The generator that corresponds to this operation
 * @param input     The hypergraph being input to this operation
 * @param name      The name to give the resulting hypergraph
 * @return A hypergraph corresponding to this operation
 */
func OpMToN(m : Int64, n : Int64, generator : Generator,  input : Hypergraph, labels : ArrayList<String>, name: String){

    let (dom, cod) = match(generator){
        case VALUE(val)        => (0,1)
        case STRUCTURAL(label) => (label.dom, label.cod)
        case GATE(label)       => (label.dom, label.cod)
        case DELAY(dur)        => (1,1)
        case IDENTITY          => (1,1)
        case INLINK(spec)      => (spec.width, 0)
        case OUTLINK(spec)     => (0, spec.width)
    }

    if(m != dom || m < 0){
        throw BadDomainException(m, dom)
    }
    if(n != cod || n < 0){
        throw BadCodomainException(n, cod)
    }
    if(labels.size() != n){
        throw BadOutputLabelsException(labels.size(), n)
    }
    if(input.GetN() != m){
        throw TypeMismatchException(input, m)
    }

    let busMap = MapBuilder<String, Bus>()

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x => 
        let label = labels.get(x)
        if(label == ""){
            Source(Wire())
        } else {
            let bus = match(busMap.toMap().get(label)){
                case Some(bus) => bus
                case $None => {
                    let newBus = Bus(label)
                    busMap.add(label, newBus)
                    newBus
                }
            }
            Source(bus.AddWire())
        }
    })

    let op = Edge(generator, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i in 0..m) {
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }

    let graph = Hypergraph(name, ArrayList<Edge>([op]), inputs, outputs, conns.toMap())
    Seq(input, graph)
}

/**
 * Create a hypergraph for an operation 0 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpZeroToOne(gen : Generator, label : String, name : String){ 
    OpMToN(0,1, gen, Empty(), ArrayList<String>([label]), name) 
}
/**
 * Create a hypergraph for an operation 1 -> 0
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpOneToZero(gen : Generator, input : Hypergraph, name : String){ 
    if(input.GetN() != 1){
        throw TypeMismatchException(input, 1)
    }
    OpMToN(1, 0, gen, input, ArrayList<String>(), name) 
}
/**
 * Create a hypergraph for an operation 1 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpOneToOne(gen : Generator, input : Hypergraph, label : String, name : String){
    if(input.GetN() != 1){
        throw TypeMismatchException(input, 1)
    }
    OpMToN(1, 1, gen, input, ArrayList<String>([label]), name) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, input : Hypergraph, label : String, name : String){ 
    if(input.GetN() != 2){
        throw TypeMismatchException(input, 2)
    }
    OpMToN(2, 1, gen, input, ArrayList<String>([label]), name) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param lhs   The hypergraph that will be the first argument to this operation
 * @param rhs   The hypergraph that will be the second argument to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, lhs : Hypergraph, rhs : Hypergraph, label : String, name : String){
    if(lhs.GetN() != 1){
        throw TypeMismatchException(lhs, 1)
    }
    if(rhs.GetN() != 1){
        throw TypeMismatchException(rhs, 1)
    }
    OpMToN(2, 1, gen, Par(lhs,rhs), ArrayList<String>([label]), name)
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param label The label of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, input : Hypergraph, label : String, name : String){ 
    if(input.GetN() != 3){
        throw TypeMismatchException(input, 3)
    }
    OpMToN(3, 1, gen, input, ArrayList<String>([label]), name) 
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
func OpThreeToOne(gen : Generator, x : Hypergraph, y : Hypergraph, z : Hypergraph, label : String, name : String){
    if(x.GetN() != 1){
        throw TypeMismatchException(x, 1)
    }
    if(y.GetN() != 1){
        throw TypeMismatchException(y, 1)
    }
    if(y.GetN() != 1){
        throw TypeMismatchException(z, 1)
    }
    OpMToN(3, 1, gen, Par([x,y,z]), ArrayList<String>([label]), name)
}
/**
 * Create a hypergraph for an operation 1 -> 2
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param lhs   The name of the first output port
 * @param rhs   The name of the second output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpOneToTwo(gen : Generator, input : Hypergraph, lhs : String, rhs : String, name : String){ 
    if(input.GetN() != 1){
        throw TypeMismatchException(input, 2)
    }
    OpMToN(1,2, gen, input, ArrayList<String>([lhs, rhs]), name) 
}
/**
 * Create a hypergraph for an operation 1 -> 2
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param out   The name of the output bus
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpOneToTwo(gen : Generator, input : Hypergraph, label : String, name : String){ 
    if(input.GetN() != 1){
        throw TypeMismatchException(input, 2)
    }
    OpMToN(1,2, gen, input, ArrayList<String>([label]), name) 
}

/**
 * Create a hypergraph for a bottom value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a bottom value
 */
external func Bottom(port!: String = "", name!: String = "") { 
    OpZeroToOne(VALUE(BOTTOM), port, name) 
}
/**
 * Create a hypergraph for a top value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a top value
 */
external func Top(port!: String = "", name!: String = ""){
    OpZeroToOne(VALUE(TOP), port, name)
}
/**
 * Create a hypergraph for a true value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a true value
 */
external func True(port!: String = "", name!: String = "") { 
    OpZeroToOne(VALUE(TRUE), port, name) 
}
/**
 * Create a hypergraph for a false value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a false value
 */
external func False(port!: String = "", name!: String = ""){
    OpZeroToOne(VALUE(FALSE), port, name)
}

/**
 * Create a hypergraph for a fork
 * @param input=Identity(1) The input to the fork
 * @param lhs=""            The name of the first output port
 * @param rhs=""            The name of the second output port
 * @param name=""           The name of the resulting hypergraph
 * @return A hypergraph for a fork
 */
external func Fork(input!: Hypergraph = Identity(1), lhs!: String = "", rhs!: String = "", name!: String = "") { 
    OpOneToTwo(FORK, input, lhs, rhs, name) 
}
/**
 * Create a hypergraph for a join
 * @param input=Identity(2) The input to the join
 * @param port=""           The name of the output port
 * @param name=""           The name of the resulting hypergraph
 * @return A hypergraph for a join
 */
external func Join(input!: Hypergraph = Identity(2), port!: String = "", name!: String = ""){ 
    OpTwoToOne(JOIN, input, port, name) 
}
/**
 * Create a hypergraph for a join
 * @param lhs        The first input to the join
 * @param rhs        The second input to the join
 * @param port=""    The name of the output port
 * @param name=""    The name of the resulting hypergraph
 * @return A hypergraph for a join
 */
external func Join(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){
    OpTwoToOne(JOIN, lhs, rhs, port, name)
}
/**
 * Create a hypergraph for a stub
 * @param input=Identity(1) The input to the stub
 * @param port=""           The name of the output port
 * @param name=""           The name of the resulting hypergraph
 * @return A hypergraph for a stub
 */
external func Stub(input!: Hypergraph = Identity(1), name!: String = ""){ 
    OpOneToZero(STUB, input, name) 
}

/**
 * Create a copy hypergraph n -> 2n
 * @param n The number of wires to copy
 * @return The copy hypergraph
 */
func CreateCopy(n : Int64) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(n == 0){
        Empty()
    } else {
        Seq(Par(CreateCopy(n-1), Fork()), Par(ArrayList<Hypergraph>([Identity(n-1), Swap(n-1,1), Identity(1)])))
    }
}

/**
 * Create a copy hypergraph n -> 2n
 * @param n     The number of wires to copy
 * @param input The input to the copy
 * @param labels The labels of the output ports
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a copy
 */
external func Copy(n : Int64, input!: Hypergraph = Identity(n), labels!: ArrayList<String> = ArrayList<String>(2 * n, {x => ""}), name!: Option<String> = None<String>){
    if(labels.size() != n * 2) {
        throw BadOutputLabelsException(labels.size(), n * 2)
    }
    Seq(input, CreateCopy(n), labels: labels, name: name)
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
external func Copy(n : Int64, input!: Hypergraph = Identity(n), labelLHS!:String, labelRHS!:String, name!: Option<String> = None<String>){
    Copy(n, input: input, labels: ArrayList<String>(2 * n, {x : Int64 => x < n ? labelLHS : labelRHS}), name: name)
}

/**
 * Create an erase hypergraph n -> 0
 * @param n The number of wires to erase
 * @return A hypergraph for an erase
 */
func CreateErase(n : Int64) : Hypergraph {
    if(n == 0){
        Empty()
    } else {
        Par(Stub(), CreateErase(n-1))
    }
}

/**
 * Create an erase hypergraph n -> 0
 * @param n     The number of wires to copy
 * @param input The input to the erase
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a erase
 */
external func Erase(n : Int64, input!: Hypergraph = Identity(n), name!: String = ""){
    Seq(input, CreateErase(n), name: name)
}

/**
 * Create a merge hypergraph 2n -> n
 * @param n The number of wires to copy
 * @return The copy hypergraph
 */
external func CreateMerge(n : Int64) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(n == 0){
        Empty()
    } else {
        Seq(Par(ArrayList<Hypergraph>([Identity(n-1), Swap(n-1,1), Identity(1)])), Par(Merge(n-1), Join()))
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
external func Merge(n : Int64, input!: Hypergraph = Identity(n), labels!: ArrayList<String> = ArrayList<String>(n, {x => ""}), name!: String = ""){
    if(labels.size() != n) {
        throw BadOutputLabelsException(labels.size(), n)
    }
    Seq(input, CreateMerge(n), labels: labels, name: name)
}

/**
 * Create a merge hypergraph 2n -> n
 * @param n      The number of wires to merge
 * @param input  The input to the merge
 * @param label  The label of the output ports
 * @param name   The name of the resulting hypergraph
 * @return A hypergraph for a merge
 */
external func Merge(n : Int64, input!: Hypergraph = Identity(n), label!: String, name!: String = ""){
    Merge(n, input: input, labels: ArrayList<String>(n, {x : Int64 => label}), name: name)
}

/**
 * Create an init hypergraph 0 -> n
 * @param n The number of wires to init
 * @return A hypergraph for an init
 */
external func CreateInit(n : Int64) : Hypergraph {
    if(n == 0){
        Empty()
    } else {
        Par(Bottom(), Init(n-1))
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
external func Init(n : Int64, input!: Hypergraph = Identity(n), labels!: ArrayList<String> = ArrayList<String>(n, {x => ""}), name!: String = ""){
    Seq(input, CreateInit(n), name: name)
}

external func NotGate(input!: Hypergraph = Identity(1), label!: String = "", name!: String = "") { OpOneToOne(NOT, input, label, name) }

external func AndGate(input!: Hypergraph = Identity(2), label!: String = "", name!: String = "") { OpTwoToOne(AND, input, label, name) }
external func AndGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(AND, lhs, rhs, label, name) }

external func OrGate(input!: Hypergraph = Identity(2), label!: String = "", name!: String = "") { OpTwoToOne(OR, input, label, name) }
external func OrGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(OR, lhs, rhs, label, name) }

external func XorGate(input!: Hypergraph = Identity(2), label!: String = "", name!: String = "") { OpTwoToOne(XOR, input, label, name) }
external func XorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(XOR, lhs, rhs, label, name) }

external func NandGate(input!: Hypergraph = Identity(2), label!: String = "", name!: String = "") { OpTwoToOne(NAND, input, label, name) }
external func NandGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(NAND, lhs, rhs, label, name) }

external func NorGate(input!: Hypergraph = Identity(2), label!: String = "", name!: String = "") { OpTwoToOne(NOR, input, label, name) }
external func NorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(NOR, lhs, rhs, label, name) }

external func XnorGate(input!: Hypergraph = Identity(2), label!: String = "", name!: String = "") { OpTwoToOne(XNOR, input, label, name) }
external func XnorGate(lhs!: Hypergraph, rhs!: Hypergraph, label!: String = "", name!: String = ""){ OpTwoToOne(XNOR, lhs, rhs, label, name) }

external func Delay(n : Int64, input!: Hypergraph = Identity(1), label!: String = "", name!: String = "") { OpOneToOne(DELAY(n), input, label, name) }

external func InLink(spec : LinkSpec, input!: Hypergraph = Identity(spec.width), name!:String = "") { OpOneToZero(INLINK(spec), input, name) }
external func OutLink(spec : LinkSpec, label!: String, name!:String = "") { OpZeroToOne(INLINK(spec), label, name) }

/**
 * Create an input to the graph with associated handles
 * @param out The name of the bus
 * @param width The width of the bus
 * @return The input circuit
 */
external func Input(label!: String, width!: Int64 = 1){
    if(width < 1){
        throw NegativeWireException()
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
external func Output(fs : ArrayList<Hypergraph>, name!: Option<String> = None<String>){
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
external func Output(fs : List<Hypergraph>, name!: Option<String> = None<String>){
    Output(ArrayList<Hypergraph>(fs), name: name)
}

external func TestComponents() {
    let a = AndGate(label: "hello")
    let b = NotGate(label: "Not")
    let c = Seq(a, b)
    print(DotGraph(c))
    return 0
}

