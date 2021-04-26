package hypergraphs
import core.*

class BadOutputPortsException <: Exception {}
class BadDomainException <: Exception {}
class BadCodomainException <: Exception {}

func OpMToN(name : String, m : Int64, n : Int64, kind : MorphismKind, ports : ArrayList<String>){

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

func OpMToN(m : Int64, n : Int64, kind : MorphismKind){ OpMToN("", m,n,kind,ArrayList<String>(n,{x => ""})) }
func OpMToN(m : Int64, n : Int64, kind : MorphismKind, ports : ArrayList<String>){ OpMToN("", m,n,kind,ports) }

func OpOneToOne(kind : MorphismKind, ports : ArrayList<String>){ OpMToN(1, 1, kind, ports) }
func OpTwoToOne(kind : MorphismKind, ports : ArrayList<String>){ OpMToN(2, 1, kind, ports) }
func OpThreeToOne(kind : MorphismKind, ports : ArrayList<String>){ OpMToN(3, 1, kind, ports) }

func AndGate(out : String) { OpTwoToOne(AND, ArrayList<String>([out])) }
func NotGate(out : String) { OpOneToOne(NOT, ArrayList<String>([out])) }

external func TestComponents() {
    let graph = AndGate("out")
    print("${graph}\n")
    DotGraph(graph)
    return 0
}