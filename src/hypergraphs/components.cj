package hypergraphs
import core.*

class BadOutputPortsException <: Exception {}
class BadDomainException <: Exception {}
class BadCodomainException <: Exception {}

func OpMToN(m : Int64, n : Int64, label : Label, ports : ArrayList<String>){

    if(m != label.dom || m < 0){
        throw BadDomainException()
    }
    if(n != label.cod || n < 0){
        throw BadCodomainException()
    }
    if(ports.size() != n){
        throw BadOutputPortsException()
    }

    let inputs = ArrayList<Target>(m, {x => Target()})
    let sources = ArrayList<Source>(m, {x => Source()})
    let targets = ArrayList<Target>(n, {x => Target()})
    let outputs = ArrayList<Source>(n, {x => Source(ports.get(x))})

    let op = RegularEdge(label, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i in 0..m) {
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }

    let graph = Hypergraph(#{op}, inputs, outputs, conns.toMap())
    graph
}

func OpMToN(m : Int64, n : Int64, label : Label){ OpMToN(m,n,label,ArrayList<String>(n,{x => ""})) }

func OpOneToOne(label : Label, ports : ArrayList<String>){ OpMToN(1, 1, label, ports) }
func OpTwoToOne(label : Label, ports : ArrayList<String>){ OpMToN(2, 1, label, ports) }
func OpThreeToOne(label : Label, ports : ArrayList<String>){ OpMToN(3, 1, label, ports) }

func AndGate(out : String) { OpTwoToOne(AND, ArrayList<String>([out])) }
func NotGate(out : String) { OpOneToOne(NOT, ArrayList<String>([out])) }

external func TestComponents() {
    let graph = AndGate("out")
    print("${graph}\n")
    DotGraph(graph)
    return 0
}