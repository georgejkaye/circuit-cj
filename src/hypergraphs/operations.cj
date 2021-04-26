package hypergraphs
import core.*

class OutputInputMismatchException <: Exception {
    init(f : Hypergraph, g : Hypergraph){
        print("Outputs of ${f.GetName()} do not match inputs of ${g.GetName()}")
    }
}

func Seq(f : Hypergraph, g : Hypergraph, name!: String = ""){
    
    if(f.GetN() != g.GetM()){
        throw OutputInputMismatchException(f,g)
    }
    
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

class NegativeIdentityException <: Exception {
    init(){
        print("Identities must be positive")
    }
}

func Identity(n : Int64){ Identity(n, ArrayList<String>(n, {x => ""}))}
func Identity(n : Int64, ports: ArrayList<String>, name!: String = ""){
    if(n < 0){
        throw NegativeIdentityException()
    }
    if(ports.size() != n){
        throw BadOutputPortsException()
    }
    let inputs = ArrayList<Target>()
    let outputs = ArrayList<Source>()
    let conns = MapBuilder<Target,Source>()
    for(i in 0..n){
        let t = Target()
        let s = Source(ports.get(i))
        inputs.add(t)
        outputs.add(s)
        conns.add(t,s)
    }
    Hypergraph(name, ArrayList<Edge>(), inputs, outputs, conns.toMap())
}

func Par(f : Hypergraph, g : Hypergraph, name!: String = ""){
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
    Hypergraph(name, newEdges, newInputs, newOutputs, newConns.toMap())
}

func Empty(){ Identity(0) }

func Swap(m : Int64, n : Int64, name!: String = ""){
    let inputs = ArrayList<Target>()
    let outputs = ArrayList<Source>()
    for(i in 0..m+n){
        inputs.add(Target())
        outputs.add(Source())
    }
    let conns = MapBuilder<Target,Source>()
    for(i in 0..m){
        conns.add(inputs.get(i), outputs.get(n+i))
    }
    for(i in 0..n){
        conns.add(inputs.get(m + i), outputs.get(i))
    }
    Hypergraph(name, ArrayList<Edge>(), inputs, outputs, conns.toMap())
}

class NegativeTraceException <: Exception {
    init(){
        print("Cannot trace negative number of wires")
    }
}
class TooMuchTraceException <: Exception {
    init(){
        print("Tried to trace more wires than outputs")
    }
}

func Trace(f : Hypergraph, x : Int64){ Trace("", f, x) }
func Trace(name : String, f : Hypergraph, x : Int64){
    if(x < 0){
        throw NegativeTraceException() 
    }
    if(x > f.GetM() || x > f.GetN()){
        throw TooMuchTraceException()
    }

    let newF = f.Clone()
    let newInputs = newF.GetInputs()
    let newOutputs = newF.GetOutputs()

    let idSources = ArrayList<Source>()
    let idTargets = ArrayList<Target>()

    for(i in 0..x){
        idSources.add(newOutputs.removeAt(0))
        idTargets.add(newInputs.removeAt(0))
    }

    let idEdge = IdentityEdge(idSources, idTargets)
    let newEdges = newF.GetEdges()
    newEdges.add(idEdge)

    Hypergraph(name, newEdges, newInputs, newOutputs, newF.GetConns())
}


external func TestOps(){
    let f = Trace(Seq(Seq(Par(Identity(1), Swap(1,1)), Par(AndGate(), Identity(1))), Par(Fork(), Identity(1))), 1)
    print(DotGraph(f))
}