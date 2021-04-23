package hypergraphs
import core.*

func Seq(f : Hypergraph, g : Hypergraph){
    let newF = f.Clone()
    let newG = g.Clone()

    let newEdges = ArrayList<Edge>()
    newEdges.addAll(newF.GetEdges())
    newEdges.addAll(newG.GetEdges())

    let newConns = MapBuilder<Target,Source>()
    for(t in newF.GetTargets()){
        let s = newF.GetConn(t)
        let s2 = match(newF.GetEdge(newF.GetConn(t))){
            case .EdgePort(e, n) => s
            case .InterfacePort(n) => {
                let newv = newG.GetConn(newG.GetInputs().get(n))
                newv.AddNames(s.names)
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

func Par(f : Hypergraph, g : Hypergraph){
    let newF = f.Clone()
    let newG = g.Clone()

    let newEdges = ArrayList<Edge>()
    newEdges.addAll(newF.GetEdges())
    newEdges.addAll(newG.GetEdges())

    let newInputs = ArrayList<Target>()
    newInputs.addAll(newF.GetInputs())
    newInputs.addAll(newG.GetInputs())

    let newOutputs = ArrayList<Source>()
    newOutputs.addAll(newF.GetOutputs())
    newOutputs.addAll(newG.GetOutputs())

    let newConns = MapBuilder<Target,Source>()
    for(v in newF.GetTargets()){
        newConns.add(v, newF.GetConn(v))
    }
    for(v in newG.GetTargets()){
        newConns.add(v, newG.GetConn(v))
    }
    Hypergraph(newEdges, newInputs, newOutputs, newConns.toMap())
}

external func TestOps(){
    let f = AndGate("and")
    let g = NotGate("not")    
    let h = Seq(f,g)
    print(DotGraph(h))
    print("\n\n")
    let k = Par(f,g)
    print(DotGraph(k))
    print("\n\n")
}