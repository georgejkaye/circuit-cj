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

func OpMToN(m : Int64, n : Int64, generator : Generator, ports : ArrayList<String>, name: String){

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

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x => Source(ports.get(x))})

    let op = Edge(generator, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i in 0..m) {
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }

    let graph = Hypergraph(name, ArrayList<Edge>([op]), inputs, outputs, conns.toMap())
    graph
}

func OpZeroToOne(gen : Generator, out : String, name : String){ OpMToN(0,1, gen, ArrayList<String>([out]), name) }
func OpOneToZero(gen : Generator, name : String){ OpMToN(1, 0, gen, ArrayList<String>(), name) }
func OpOneToOne(gen : Generator, out : String, name : String){ OpMToN(1, 1, gen, ArrayList<String>([out]), name) }
func OpTwoToOne(gen : Generator, out : String, name : String){ OpMToN(2, 1, gen, ArrayList<String>([out]), name) }
func OpThreeToOne(gen : Generator, out : String, name : String){ OpMToN(3, 1, gen, ArrayList<String>([out]), name) }
func OpOneToTwo(gen : Generator, lhs : String, rhs : String, name : String){ OpMToN(1,2, gen, ArrayList<String>([lhs,rhs]), name) }

func Fork(lhs!: String = "", rhs!: String = "", name!: String = "") { OpOneToTwo(FORK, lhs, rhs, name) }
func Join(output!: String = "", name!: String = ""){ OpTwoToOne(JOIN, output, name) }
func Stub(name!: String = ""){ OpOneToZero(STUB, name) }

func NotGate(output!: String = "", name!: String = "") { OpOneToOne(NOT, output, name) }

func AndGate(output!: String = "", name!: String = "") { OpTwoToOne(AND, output, name) }
func OrGate(output!: String = "", name!: String = "") { OpTwoToOne(OR, output, name) }
func XorGate(output!: String = "", name!: String = "") { OpTwoToOne(XOR, output, name) }

func NandGate(output!: String = "", name!: String = "") { OpTwoToOne(NAND, output, name) }
func NorGate(output!: String = "", name!: String = "") { OpTwoToOne(NOR, output, name) }
func XnorGate(output!: String = "", name!: String = "") { OpTwoToOne(XNOR, output, name) }

func Delay(n : Int64, output!: String = "", name!: String = "") { OpOneToOne(DELAY(n), output, name) }

func InLink(spec : LinkSpec, name!:String = "") { OpOneToZero(INLINK(spec), name) }
func OutLink(spec : LinkSpec, output!: String, name!:String = "") { OpZeroToOne(INLINK(spec), output, name) }

external func TestComponents() {
    let graph = AndGate(output: "out")
    print("${graph}\n")
    DotGraph(graph)
    return 0
}