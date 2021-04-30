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
func OpMToN(m : Int64, n : Int64, generator : Generator,  input : Hypergraph, ports : ArrayList<String>, name: String){

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
    if(ports.size() != n){
        throw BadOutputPortsException(ports.size(), n)
    }
    if(input.GetN() != m){
        throw TypeMismatchException(input, m)
    }

    let busMap = MapBuilder<String, Bus>()

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x => 
        let port = ports.get(x)
        if(port == ""){
            Source(Wire())
        } else {
            let bus = match(busMap.toMap().get(port)){
                case Some(bus) => bus
                case $None => {
                    let newBus = Bus(port)
                    busMap.add(port, newBus)
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
 * @param gen  The generator that corresponds to this operation
 * @param out  The name of the output port
 * @param name The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpZeroToOne(gen : Generator, out : String, name : String){ 
    OpMToN(0,1, gen, Empty(), ArrayList<String>([out]), name) 
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
 * @param out   The name of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpOneToOne(gen : Generator, input : Hypergraph, out : String, name : String){
    if(input.GetN() != 1){
        throw TypeMismatchException(input, 1)
    }
    OpMToN(1, 1, gen, input, ArrayList<String>([out]), name) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param out   The name of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, input : Hypergraph, out : String, name : String){ 
    if(input.GetN() != 2){
        throw TypeMismatchException(input, 2)
    }
    OpMToN(2, 1, gen, input, ArrayList<String>([out]), name) 
}
/**
 * Create a hypergraph for an operation 2 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param lhs   The hypergraph that will be the first argument to this operation
 * @param rhs   The hypergraph that will be the second argument to this operation
 * @param out   The name of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpTwoToOne(gen : Generator, lhs : Hypergraph, rhs : Hypergraph, out : String, name : String){
    if(lhs.GetN() != 1){
        throw TypeMismatchException(lhs, 1)
    }
    if(rhs.GetN() != 1){
        throw TypeMismatchException(rhs, 1)
    }
    OpMToN(2, 1, gen, Par(lhs,rhs), ArrayList<String>([out]), name)
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param input The hypergraph that will be input to this operation
 * @param out   The name of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, input : Hypergraph, out : String, name : String){ 
    if(input.GetN() != 3){
        throw TypeMismatchException(input, 3)
    }
    OpMToN(3, 1, gen, input, ArrayList<String>([out]), name) 
}
/**
 * Create a hypergraph for an operation 3 -> 1
 * @param gen   The generator that corresponds to this operation
 * @param x     The hypergraph that will be the first argument to this operation
 * @param y     The hypergraph that will be the second argument to this operation
 * @param z     The hypergraph that will be the third argument to this operation
 * @param out   The name of the output port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph corresponding to this operation
 */
func OpThreeToOne(gen : Generator, x : Hypergraph, y : Hypergraph, z : Hypergraph, out : String, name : String){
    if(x.GetN() != 1){
        throw TypeMismatchException(x, 1)
    }
    if(y.GetN() != 1){
        throw TypeMismatchException(y, 1)
    }
    if(y.GetN() != 1){
        throw TypeMismatchException(z, 1)
    }
    OpMToN(3, 1, gen, Par([x,y,z]), ArrayList<String>([out]), name)
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
func OpOneToTwo(gen : Generator, input : Hypergraph, out : String, name : String){ 
    if(input.GetN() != 1){
        throw TypeMismatchException(input, 2)
    }
    OpMToN(1,2, gen, input, ArrayList<String>([out]), name) 
}

/**
 * Create a hypergraph for a bottom value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a bottom value
 */
func Bottom(port!: String = "", name!: String = "") { 
    OpZeroToOne(VALUE(BOTTOM), port, name) 
}
/**
 * Create a hypergraph for a top value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a top value
 */
func Top(port!: String = "", name!: String = ""){
    OpZeroToOne(VALUE(TOP), port, name)
}
/**
 * Create a hypergraph for a true value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a true value
 */
func True(port!: String = "", name!: String = "") { 
    OpZeroToOne(VALUE(TRUE), port, name) 
}
/**
 * Create a hypergraph for a false value
 * @param port="" The name of the output port
 * @param name="" The name of the resulting hypergraph
 * @return A hypergraph for a false value
 */
func False(port!: String = "", name!: String = ""){
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
 * @param ports The names of the output ports 
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a copy
 */
external func Copy(n : Int64, input!: Hypergraph = Identity(n), ports!: ArrayList<String> = ArrayList<String>(2 * n, {x => ""}), name!: String = ""){
    if(ports.size() != n * 2) {
        throw BadOutputPortsException(ports.size(), n * 2)
    }
    var circ = Seq(input, CreateCopy(n), ports: ports, name: name)
    //circ.NameOutputs(ports)
    circ
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
    var circ = Seq(input, CreateErase(n), name: name)
    circ
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
 * @param n     The number of wires to merge
 * @param input The input to the merge
 * @param ports The names of the output ports 
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a merge
 */
external func Merge(n : Int64, input!: Hypergraph = Identity(n), ports!: ArrayList<String> = ArrayList<String>(n, {x => ""}), name!: String = ""){
    if(ports.size() != n) {
        throw BadOutputPortsException(ports.size(), n)
    }
    var circ = Seq(input, CreateMerge(n), ports: ports, name: name)
    //circ.NameOutputs(ports)
    circ
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
 * @param n     The number of wires to init
 * @param input The input to the erase
 * @param ports The name of the output ports
 * @param name  The name of the resulting hypergraph
 * @return A hypergraph for a erase
 */
external func Init(n : Int64, input!: Hypergraph = Identity(n), ports!: ArrayList<String> = ArrayList<String>(n, {x => ""}), name!: String = ""){
    var circ = Seq(input, CreateInit(n), name: name)
    //circ.NameOutputs(ports)
    circ
}

external func NotGate(input!: Hypergraph = Identity(1), port!: String = "", name!: String = "") { OpOneToOne(NOT, input, port, name) }

external func AndGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(AND, input, port, name) }
external func AndGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(AND, lhs, rhs, port, name) }

external func OrGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(OR, input, port, name) }
external func OrGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(OR, lhs, rhs, port, name) }

external func XorGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(XOR, input, port, name) }
external func XorGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(XOR, lhs, rhs, port, name) }

external func NandGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(NAND, input, port, name) }
external func NandGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(NAND, lhs, rhs, port, name) }

external func NorGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(NOR, input, port, name) }
external func NorGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(NOR, lhs, rhs, port, name) }

external func XnorGate(input!: Hypergraph = Identity(2), port!: String = "", name!: String = "") { OpTwoToOne(XNOR, input, port, name) }
external func XnorGate(lhs!: Hypergraph, rhs!: Hypergraph, port!: String = "", name!: String = ""){ OpTwoToOne(XNOR, lhs, rhs, port, name) }

external func Delay(n : Int64, input!: Hypergraph = Identity(1), port!: String = "", name!: String = "") { OpOneToOne(DELAY(n), input, port, name) }

external func InLink(spec : LinkSpec, input!: Hypergraph = Identity(spec.width), name!:String = "") { OpOneToZero(INLINK(spec), input, name) }
external func OutLink(spec : LinkSpec, port!: String, name!:String = "") { OpZeroToOne(INLINK(spec), port, name) }


external func Input(port!: String, width!: Int64 = 1){
    if(width < 1){
        throw NegativeWireException()
    }
    Identity(width, port: port)
}

external func TestComponents() {
    let n = 3
    let fs : ArrayList<Hypergraph> = ArrayList<Hypergraph>([Copy(n), Par(Erase(n), Identity(n)), Par(Identity(n), Init(n)), Merge(n)])
    let graph = Seq(fs)
    print(DotGraph(graph))
    return 0
}

