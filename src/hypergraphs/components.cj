package hypergraphs
import core.*

class BadOutputPortsException <: Exception {
    init(){
        print("Length of output ports list is not the same as the number of outputs")
    }
}
class BadDomainException <: Exception {
    init(){
        print("Number of inputs does not match the domain of the label")
    }
}
class BadCodomainException <: Exception {
    init(){
        print("Number of outputs does not match the codomain of the label")
    }
}
class BadPrecException <: Exception {
    init(){
        print("Number of outputs of input circuit does not match the inputs of the operation")
    }
}

func OpMToN(m : Int64, n : Int64, generator : Generator,  input : Hypergraph, ports : ArrayList<String>, name: String){

    let (dom, cod) = match(generator){
        case .VALUE(val)        => (0,1)
        case .STRUCTURAL(label) => (label.dom, label.cod)
        case .GATE(label)       => (label.dom, label.cod)
        case .DELAY(dur)        => (1,1)
        case .IDENTITY          => (1,1)
        case .INLINK(spec)      => (spec.width, 0)
        case .OUTLINK(spec)     => (0, spec.width)
    }

    if(m != dom || m < 0){
        throw BadDomainException()
    }
    if(n != cod || n < 0){
        throw BadCodomainException()
    }
    if(ports.size() != n){
        throw BadOutputPortsException()
    }
    if(input.GetN() != m){
        throw BadPrecException()
    }

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x =>
        let port = ports.get(x)
        port == "" ? Source() : Source(ports.get(x))})

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

func OpZeroToOne(gen : Generator, out : String, name : String){ OpMToN(0,1, gen, Empty(), ArrayList<String>([out]), name) }
func OpOneToZero(gen : Generator, input : Hypergraph, name : String){ OpMToN(1, 0, gen, input, ArrayList<String>(), name) }
func OpOneToOne(gen : Generator, input : Hypergraph, out : String, name : String){ OpMToN(1, 1, gen, input, ArrayList<String>([out]), name) }
func OpTwoToOne(gen : Generator, input : Hypergraph, out : String, name : String){ OpMToN(2, 1, gen, input, ArrayList<String>([out]), name) }
func OpThreeToOne(gen : Generator, input : Hypergraph, out : String, name : String){ OpMToN(3, 1, gen, input, ArrayList<String>([out]), name) }
func OpOneToTwo(gen : Generator, input : Hypergraph, lhs : String, rhs : String, name : String){ OpMToN(1,2, gen, input, ArrayList<String>([lhs,rhs]), name) }

func Bottom(output!: String = "", name!: String = "") { OpZeroToOne(VALUE(BOTTOM), output, name) }

func Fork(input!: Hypergraph = Identity(1), lhs!: String = "", rhs!: String = "", name!: String = "") { OpOneToTwo(FORK, input, lhs, rhs, name) }
func Join(input!: Hypergraph = Identity(2), output!: String = "", name!: String = ""){ OpTwoToOne(JOIN, input,  output, name) }
func Stub(input!: Hypergraph = Identity(1), name!: String = ""){ OpOneToZero(STUB, input, name) }

// TODO currently copy(3) segfaults because the map blows the stack
func Copy(n : Int64) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(n == 0){
        Empty()
    } else {
        Seq(Par(Copy(n-1), Fork()), Par(ArrayList([Identity(n-1), Swap(n-1,1), Identity(1)])))
    }
}

func Erase(n : Int64) : Hypergraph {
    if(n == 0){
        Empty()
    } else {
        Par(Stub(), Erase(n-1))
    }
}

func Merge(n : Int64) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(n == 0){
        Empty()
    } else {
        Seq(Par(ArrayList([Identity(n-1), Swap(n-1,1), Identity(1)])), Par(Merge(n-1), Join()))
    }
}

func Init(n : Int64) : Hypergraph {
    if(n == 0){
        Empty()
    } else {
        Par(Bottom(), Init(n-1))
    }
}

func NotGate(input!: Hypergraph = Identity(1), output!: String = "", name!: String = "") { OpOneToOne(NOT, input, output, name) }

func AndGate(input!: Hypergraph = Identity(2), output!: String = "", name!: String = "") { OpTwoToOne(AND, input, output, name) }
func OrGate(input!: Hypergraph = Identity(2), output!: String = "", name!: String = "") { OpTwoToOne(OR, input, output, name) }
func XorGate(input!: Hypergraph = Identity(2), output!: String = "", name!: String = "") { OpTwoToOne(XOR, input, output, name) }

func NandGate(input!: Hypergraph = Identity(2), output!: String = "", name!: String = "") { OpTwoToOne(NAND, input, output, name) }
func NorGate(input!: Hypergraph = Identity(2), output!: String = "", name!: String = "") { OpTwoToOne(NOR, input, output, name) }
func XnorGate(input!: Hypergraph = Identity(2), output!: String = "", name!: String = "") { OpTwoToOne(XNOR, input, output, name) }

func Delay(n : Int64, input!: Hypergraph = Identity(1), output!: String = "", name!: String = "") { OpOneToOne(DELAY(n), input, output, name) }

func InLink(spec : LinkSpec, input!: Hypergraph = Identity(spec.width), name!:String = "") { OpOneToZero(INLINK(spec), input, name) }
func OutLink(spec : LinkSpec, output!: String, name!:String = "") { OpZeroToOne(INLINK(spec), output, name) }

external func TestComponents() {
    let n = 3
    let fs : ArrayList<Hypergraph> = ArrayList<Hypergraph>([Copy(n), Par(Erase(n), Identity(n)), Par(Identity(n), Init(n)), Merge(n)])
    let graph = Seq(fs)
    print(DotGraph(graph))
    return 0
}