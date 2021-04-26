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

func OpMToN(m : Int64, n : Int64, kind : MorphismKind, ports : ArrayList<String>, name: String){

    let (dom, cod) = match(kind){
        case .STRUCTURAL(label) => (label.dom, label.cod)
        case .GATE(label)       => (label.dom, label.cod)
        case .DELAY(dur)        => (1,1)
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

    let op = RegularEdge(kind, sources, targets)

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

func OpOneToOne(kind : MorphismKind, out : String, name : String){ OpMToN(1, 1, kind, ArrayList<String>([out]), name) }
func OpTwoToOne(kind : MorphismKind, out : String, name : String){ OpMToN(2, 1, kind, ArrayList<String>([out]), name) }
func OpThreeToOne(kind : MorphismKind, out : String, name : String){ OpMToN(3, 1, kind, ArrayList<String>([out]), name) }
func OpOneToTwo(kind : MorphismKind, lhs : String, rhs : String, name : String){ OpMToN(1,2, kind, ArrayList<String>([lhs,rhs]), name) }

func Fork(lhs!: String = "", rhs!: String = "", name!: String = "") { OpOneToTwo(FORK, lhs, rhs, name) }
func AndGate(output!: String = "", name!: String = "") { OpTwoToOne(AND, output, name) }
func NotGate(output!: String = "", name!: String = "") { OpOneToOne(NOT, output, name) }

external func TestComponents() {
    let graph = AndGate(output: "out")
    print("${graph}\n")
    DotGraph(graph)
    return 0
}