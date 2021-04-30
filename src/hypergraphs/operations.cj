/**
 * operations.cj
 *
 * This file contains the definition of hypergraph operations
 */

package hypergraphs

func AddBusesToOutputs(labels: ArrayList<String>, outputs: ArrayList<Source>){
    let buses = ArrayList<Bus>()
    for(i in 0..labels.size()){
        let port = labels[i]
        if(port != "") { 
            let bus = match(GetBus(port, buses)){
                case $None => {
                        let bus = Bus(port)
                        buses.add(bus)
                        bus
                }
                case Some(b) => {
                    b
                }
            }
            outputs[i].AddWire(bus.AddWire())
        }
    }
    outputs
}

/**
 * Sequentially compose hypergraphs f : m -> n and g : n -> p, creating h : m -> p
 * Throws TypeMismatchException if outputs of f != inputs of g
 * Clones f and g before composing
 * @param f       The lhs of the composition
 * @param g       The rhs of the composition
 * @param name="" The name of the resulting hypergraph
 * @return The composed hypergraph h = f . g
 */
external func Seq(f : Hypergraph, g : Hypergraph, labels!: ArrayList<String> = ArrayList<String>(g.GetN(), {x => ""}), name!: Option<String> = None<String>) : Hypergraph {
    
    if(f.GetN() != g.GetM()){
        throw TypeMismatchException(f,g)
    }
    
    let newF = f.Clone()
    let newG = g.Clone()

    let newEdges = ArrayList<Edge>()
    newEdges.addAll(newF.GetEdges())
    newEdges.addAll(newG.GetEdges())

    let newConns = MapBuilder<Target,Source>()
    for(t in newF.GetTargets()){
        let s = newF.GetConnR(t)
        let s2 = match(newF.GetEdge(newF.GetConnR(t))){
            case EdgePort(e, n) => s
            case InterfacePort(n) => {
                let newv = newG.GetConnR(newG.GetInputs().get(n))
                newv.AddWires(s.wires)
                newv
            }
        }
        newConns.add(t,s2)
    }
    for(t in newG.GetTargets()){
        newConns.add(t,newG.GetConnR(t))
    }
    Hypergraph(name, newEdges, newF.GetInputs(), AddBusesToOutputs(labels, newG.GetOutputs()), newConns.toMap())
}

/**
 * Sequentially compose a list of hypergraphs from left to right 
 * @param fs A list of hypergraphs
 * @return The resulting composed hypergraph h = fs[0] . fs[1] . ... . fs[n-1]
 */
external func Seq(fs : ArrayList<Hypergraph>, labels!: ArrayList<String> = ArrayList<String>(fs.get(fs.size() - 1).GetN(), {x => ""}), name!: Option<String> = None<String>) : Hypergraph {
    if(fs.size() == 0){
        Empty()
    }
    var res = fs[0]
    for(i in 1..fs.size() - 1){
        res = Seq(res, fs[i])
    }
    Seq(res, fs[fs.size() - 1], labels: labels, name: name)
}
/**
 * Sequentially compose a list of hypergraphs from left to right 
 * @param fs A list of hypergraphs
 * @return The resulting composed hypergraph h = fs[0] . fs[1] . ... . fs[n-1]
 */
external func Seq(fs : List<Hypergraph>, labels!: ArrayList<String> = ArrayList<String>(fs.get(fs.size() - 1).GetN(), {x => ""}), name!: Option<String> = None<String>) {
    Seq(ArrayList<Hypergraph>(fs), labels: labels, name: name)
}

/**
 * Create an identity on n, the unit of sequential composition
 * @param n The number of identity wires
 * @return An identity hypergraph on n
 */
external func Identity(n : Int64) : Hypergraph { 
    Identity(n, labels: ArrayList<String>(n, {x : Int64 => ""}))
}
/**
 * Create an identity on n, the unit of sequential composition
 * @param n    The number of identity wires
 * @param port The name to give the resulting bus 
 * @param name The name of the resulting hypergraph
 * @return An identity hypergraph on n
 */
external func Identity(n : Int64, label!: String, name!: Option<String> = None<String>) : Hypergraph {
    Identity(n, labels: ArrayList<String>(n, {x : Int64 => label}))
}
/**
 * Create an identity on n, the unit of sequential composition
 * @param n    The number of identity wires
 * @param labels A list of wires to assign to the hypergraph 
 * @param name The name of the resulting hypergraph
 * @return An identity hypergraph on n
 */
external func Identity(n : Int64, labels!: ArrayList<String>, name!: Option<String> = None<String>) : Hypergraph {
    if(n < 0){
        throw NegativeWireException()
    }
    if(labels.size() != n){
        throw BadOutputLabelsException(labels.size(), n)
    }
    let inputs = ArrayList<Target>()
    let outputs = ArrayList<Source>()
    let conns = MapBuilder<Target,Source>()
    for(i in 0..n){
        let t = Target()
        let s = Source()
        inputs.add(t)
        outputs.add(s)
        conns.add(t,s)
    }
    Hypergraph(name, ArrayList<Edge>(), inputs, AddBusesToOutputs(labels, outputs), conns.toMap())
}

/**
 * Compose in parallel hypergraphs f : m -> n and g : p -> q, creating h : m + p -> n + q
 * Clones f and g before composing
 * @param f       The lhs of the composition
 * @param g       The rhs of the composition
 * @param name="" The name of the resulting hypergraph
 * @return The composed hypergraph h = f * g
 */
external func Par(f : Hypergraph, g : Hypergraph, labels!: ArrayList<String> = ArrayList<String>(f.GetN() + g.GetN(), {x => ""}), name!: Option<String> = None<String>) : Hypergraph {
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
        newConns.add(v, newF.GetConnR(v))
    }
    for(v in newG.GetTargets()){
        newConns.add(v, newG.GetConnR(v))
    }
    Hypergraph(name, newEdges, newInputs, AddBusesToOutputs(labels, newOutputs), newConns.toMap())
}
/**
 * Compose in parallel a list of hypergraphs from left to right 
 * @param fs         A list of hypergraphs
 * @param labels={""} A list of labels for the resulting hypergraph
 * @param name=""    The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = fs[0] * fs[1] * ... * fs[n-1]
 */
external func Par(fs : ArrayList<Hypergraph>, 
                  labels!: ArrayList<String> = ArrayList<String>(GetListOutputs(fs), {x => ""}), 
                  name!: Option<String> = None<String>) : Hypergraph {
    if(fs.size() == 0){
        Empty()
    }
    var res = fs[0]
    for(i in 1..fs.size() - 1){
        res = Par(res, fs[i])
    }
    Par(res, fs[fs.size()-1], name: name, labels: labels)
}
/**
 * Compose in parallel a list of hypergraphs from left to right 
 * @param fs         A list of hypergraphs
 * @param labels={""} A list of labels for the resulting hypergraph
 * @param name=""    The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = fs[0] * fs[1] * ... * fs[n-1]
 */
external func Par(fs : List<Hypergraph>, 
                  labels!: ArrayList<String> = ArrayList<String>(GetListOutputs(fs), {x => ""}), 
                  name!: Option<String> = None<String>) : Hypergraph {
    Par(ArrayList<Hypergraph>(fs), labels: labels, name: name)
}
/**
 * Compose multiple copies of a hypergraph in parallel
 * @param f          The hypergraph to compose
 * @param n          The number of times to compose the hypergraph
 * @param labels={""} A list of labels for the resulting hypergraph
 * @param name=""    The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = f * f * ... * f
 */
external func Par(f : Hypergraph, n : Int64, 
                  labels!: ArrayList<String> = ArrayList<String>(f.GetN() * n, {x => ""}), 
                  name!: Option<String> = None<String>) : Hypergraph {
    let fs = ArrayList<Hypergraph>(n, {x => f})
    Par(fs, labels: labels, name: name)
}

/** 
 * The empty hypergraph, the unit of parallel composition
 * @param name="" The name to give the resulting hypergraph
 */
external func Empty(name!: Option<String> = None<String>) : Hypergraph { Identity(0, labels: ArrayList<String>(), name: name) }

/**
 * A swap hypergraph on m and n, that swaps over the first m inputs with the last n inputs
 * @param m The first argument of the swap
 * @param n The second argument of the swap
 * @param name="" The name of the resulting hypergraph
 */
external func Swap(m : Int64, n : Int64, labels!: ArrayList<String> = ArrayList<String>(m + n, {x => ""}), name!: Option<String> = None<String>) : Hypergraph {
    if(m < 0 || n < 0){
        throw NegativeWireException()
    }
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
    Hypergraph(name, ArrayList<Edge>(), inputs, AddBusesToOutputs(labels, outputs), conns.toMap())
}

/**
 * Trace a hypergraph f : x + m -> x + n to create Tr^x(f) : m -> n
 * Creates a copy of f
 * Throws NegativeTraceException if x < 0
 * Throws TooMuchTraceException if x is greater than the inputs or outputs of f
 * @param f The hypergraph to trace
 * @param x The number of wires to trace
 * @param name="" The name of the resulting hypergraph
 * @return The traced hypergraph
 */ 
external func Trace(f : Hypergraph, x : Int64, labels!: ArrayList<String> = ArrayList<String>(max(f.GetM() - x, 0), {x => ""}), name!: Option<String> = None<String>){
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
    Hypergraph(name, newEdges, newInputs, AddBusesToOutputs(labels, newOutputs), newF.GetConnsR())
}

/**
 * Transform a hypergraph of type m->n to one of type m->1, preserving the nth 
 * output and stubbing the rest.
 * @param f     The hypergraph
 * @param n     The index of the output to preserve
 * @param label The label to assign the exposed port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph with only the nth output exposed
 */
external func Get(f : Hypergraph, n : Int64, port! : String = "", name!: Option<String> = None<String>){
    if(n < 0){
        throw TypeMismatchException(f, n)
    }
    let stubs = Par([Erase(n),Identity(1),Erase(f.GetN() - n - 1)]) 
    Seq(f, stubs, labels: ArrayList<String>([port]), name: name)    
}
/**
 * Transform a hypergraph to one with only the given outputs exposed, stubbing the rest.
 * @param f  The hypergraph
 * @param ns The indices of the outputs to preserve
 * @param name The name of the resulting hypergraph
 * @return The hypergraph with only the given outputs exposed
 */
external func Get(f : Hypergraph, ns : ArrayList<Int64>, name!: Option<String> = None<String>){
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
    Seq(f, stubs, name: name)
}
/**
 * Transform a hypergraph to one with only the given bus exposed, stubbing the rest.
 * @param f  The hypergraph
 * @param s The name of the bus to expose
 * @param name The name of the resulting hypergraph
 * @return The hypergraph with only the given bus exposed
 */
external func Get(f : Hypergraph, s : String, name!: Option<String> = None<String>){
    let outputs = f.GetOutputs()
    let ns = ArrayList<Int64>()
    for(i in 0..outputs.size()){
        for(wire in outputs[i].wires){
            match(wire.bus.name){
                case Some(text) => if(text == s) { ns.add(i) }
                case $None      => {}
            }
        }
    }
    if(ns.size() == 0){
        throw PortNotFoundException(f, s)
    } 
    Get(f, ns, name: name)
}

external func TestOps(){
    //let and = AndGate(port: "and")
    //let and2 = Par(and, and)  
    //let not = NotGate(port: "not")

    //let not = NotGate(output: "not")

    //let fork = Fork()  
    //let g = Seq(NotGate(), Seq(Fork(), and))

    //let trace = Trace(Seq(AndGate(), Fork()), 4)

    //print(DotGraph(Seq(and, not)))
}