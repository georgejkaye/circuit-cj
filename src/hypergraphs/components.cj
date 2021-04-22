package hypergraphs
import core.*

class BadOutputPortsException <: Exception {}
class BadDomainException <: Exception {}
class BadCodomainException <: Exception {}

func OpMToN(m : Int64, n : Int64, label : Label, ports : ArrayList<String>){

    if(m != label.dom){
        throw BadDomainException()
    }
    if(n != label.cod){
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

func AndGate(out : String) { OpMToN(2,1,AND,ArrayList<String>([out])) }

external func Test() {
    let graph = AndGate("out")
    print("${graph}")
    return 0
}