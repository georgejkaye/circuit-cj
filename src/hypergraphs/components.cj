package hypergraphs

import hypergraphs.*
import labels.*

class BadOutputPortsException <: Exception {}
class BadDomainException <: Exception {}
class BadCodomainException <: Exception {}

func OpMToN(m : UInt64, n : UInt64, label : Label, ports : ArrayList<String>){

    if(m != label.dom){
        throw BadDomainException()
    }
    if(n != label.cod){
        throw BadCodomainException()
    }

    //print("${outputs.size()}")

    //if(outputs.size() != n){
    //    throw BadOutputPortsException()
   // }

    let inputs = ArrayList<Target>(Int64(m), {x => Target()})
    let sources = ArrayList<Source>(Int64(m), {x => Source()})
    let targets = ArrayList<Target>(Int64(n), {x => Target()})
    let outputs = ArrayList<Source>(Int64(n), {x => Source(ports.get(x))})

    let op = RegularEdge(label, sources, targets)

    let conns = MapBuilder<Target, Source>()
    for (i : Int64 in 0..m) {
        conns.add(inputs.get(i), sources.get(i))
    }
    for (i : Int64 in 0..n) {
        conns.add(targets.get(i), outputs.get(i))
    }

    let graph = Hypergraph(#{op}, inputs, outputs, conns.toMap())
    print(graph.ToString())
}
//func OpMToN(m : UInt64, n : UInt64, label : Label){ OpMToN(m,n,label,ArrayList<String>(n,"")) }

func AndGate(out : String) { OpMToN(2,1,AND,ArrayList<String>([out])) }

external func Test() {
    AndGate("out")
    return 0
}