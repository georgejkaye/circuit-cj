package hypergraphs
// import core.*

class NegativeWireException <: Exception {
    init(){
        print("Number of wires cannot be negative")
    }
}

class OutputInputMismatchException <: Exception {
    init(f : Hypergraph, g : Hypergraph){
        print("Outputs of '${f.GetName()}' (${f.GetN()}) do not match inputs of '${g.GetName()}' (${g.GetM()})")
    }
}

class BadOutputException <: Exception {
    init(f : Hypergraph, n : Int64){
        //print("Hypergraph ${f.GetName()} only has ${f.getN()} outputs, ${n} attempted")
    }
}

class PortNotFoundException <: Exception {
    init(f : Hypergraph, s : String){
        print("Hypergraph '${f.GetName()}' does not have a port named '${s}'")
    }
}

func Seq(f : Hypergraph, g : Hypergraph, name!: String = "") : Hypergraph {
    
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
            case EdgePort(e, n) => s
            case InterfacePort(n) => {
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

func Seq(fs : ArrayList<Hypergraph>) : Hypergraph {
    if(fs.size() == 0){
        Empty()
    }
    var res = fs[0]
    for(i in 1..fs.size()){
        res = Seq(res, fs[i])
    }
    res
}

func Seq(fs : List<Hypergraph>) : Hypergraph {
    Seq(ArrayList<Hypergraph>(fs))
}

func Identity(n : Int64) : Hypergraph { 
    Identity(n, ArrayList<Option<WireName>>(n, {x => None<WireName>}))
}
func Identity(n : Int64, ports: ArrayList<Option<WireName>>, name!: String = "") : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(ports.size() != n){
        throw BadOutputPortsException()
    }
    let inputs = ArrayList<Target>()
    let outputs = ArrayList<Source>()
    let conns = MapBuilder<Target,Source>()
    for(i in 0..n){
        let t = Target()
        let s = match(ports.get(i)){
            case Some(w) => Source(w)
            case $None    => Source()
        }
        inputs.add(t)
        outputs.add(s)
        conns.add(t,s)
    }
    Hypergraph(name, ArrayList<Edge>(), inputs, outputs, conns.toMap())
}

func Par(f : Hypergraph, g : Hypergraph, name!: String = "") : Hypergraph {
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

func Par(fs : ArrayList<Hypergraph>) : Hypergraph {
    if(fs.size() == 0){
        Empty()
    }
    var res = fs[0]
    for(i in 1..fs.size()){
        res = Par(res, fs[i])
    }
    res
}

func Par(f : Hypergraph, n : Int64) : Hypergraph {
    let fs = ArrayList<Hypergraph>(n, {x => f})
    Par(fs)
}

func Empty() : Hypergraph { Identity(0) }

func Swap(m : Int64, n : Int64, name!: String = "") : Hypergraph {
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

    let idEdge = Edge(IDENTITY, idSources, idTargets)
    let newEdges = newF.GetEdges()
    newEdges.add(idEdge)

    Hypergraph(name, newEdges, newInputs, newOutputs, newF.GetConns())
}

/**
 * Transform a hypergraph of type m->n to one of type m->1, preserving the nth 
 * output and stubbing the rest.
 * @param f The hypergraph
 * @param n The index of the output to preserve
 */
func Get(f : Hypergraph, n : Int64){
    if(n < 0){
        throw BadOutputException(f, n)
    }
    Seq(f, Par(ArrayList<Hypergraph>([Erase(n),Identity(1),Erase(f.GetN() - n - 1)])))    
}

func Get(f : Hypergraph, ns : ArrayList<Int64>){
    var stubs = Empty()
    for(i in 0..f.GetN()){
        var found = false
        for(n in ns){
            if (n == i){
                stubs = Par(stubs, Identity(1))
                found = true
                break
            }
        }
        if(!found){
            stubs = Par(stubs, Stub())
        }
    }
    Seq(f, stubs)
}

func Get(f : Hypergraph, s : String){
    let outputs = f.GetOutputs()
    let ns = ArrayList<Int64>()
    for(i in 0..outputs.size()){
        for(name in outputs[i].names){
            if(name.name == s){
                ns.add(i)
            }
        }
    }
    if(ns.size() == 0){
        throw PortNotFoundException(f, s)
    } 
    Get(f, ns)
}

external func TestOps(){
    let and = AndGate(output: "and", name: "and")
    //let and2 = Par(and, and)  

    //let not = NotGate(output: "not")

    //let fork = Fork()  
    //let g = Seq(NotGate(), Seq(Fork(), and))

    //let trace = Trace(Seq(AndGate(), Fork()), 4)

    print(DotGraph(and))
}