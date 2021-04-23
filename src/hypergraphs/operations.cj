package hypergraphs
import core.*

func Seq(f : Hypergraph, g : Hypergraph){
    
    let newF = f.Clone()
    let newG = g.Clone()

    print("${newF}\n\n")
    print("${newG}\n\n")

    var newEdges = ArrayList<Edge>()
    newEdges.addAll(newF.GetEdges())
    newEdges.addAll(newG.GetEdges())

    var newConns = MapBuilder<Target,Source>()
    for(t in newF.GetTargets()){
        let s = newF.GetConn(t)
        let s2 = match(newF.GetEdge(newF.GetConn(t))){
            case .EdgePort(e, n) => s
            case .InterfacePort(n) => {
                let newv = newG.GetConn(newG.GetInputs().get(n))
                newv.AddNames(s.name)
                newv
            }
        }
        newConns.add(t,s2)
    }
    for(t in newG.GetTargets()){
        newConns.add(t,newG.GetConn(t))
    }
    Hypergraph(newEdges, newF.GetInputs(), newG.GetOutputs(), newConns.toMap())
}

external func TestOps(){
    let g = NotGate("not")
    print("${g}\n\n")
    let f = AndGate("and")
    print("${f}\n\n")
    let h = Seq(f,g)
    print("${h}")
    print(DotGraph(h))
}