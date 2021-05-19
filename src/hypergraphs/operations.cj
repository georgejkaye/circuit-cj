/**
 * operations.cj
 *
 * This file contains the definition of hypergraph operations
 */

package hypergraphs

import debug.*

/**
 * Sequentially compose hypergraphs f : m -> n and g : n -> p, creating h : m -> p
 * Throws TypeMismatchException if outputs of f != inputs of g
 * Clones f and g before composing
 * @param f       The lhs of the composition
 * @param g       The rhs of the composition
 * @param name="" The name of the resulting hypergraph
 * @return The composed hypergraph h = f . g
 */
external func Seq(f : Hypergraph, g : Hypergraph, name!: String = "") : Hypergraph {
    Debug("Seq", "Composing ${f.GetName()} and ${g.GetName()} in sequence")
    if(f.GetN() != g.GetM()){
        throw TypeMismatchException("Seq", f,g)
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

    let newInputs = newF.GetInputs()
    let newOutputs = newG.GetOutputs() 

    Hypergraph(name, newEdges, newInputs, newOutputs, newConns)
}

/**
 * Sequentially compose a list of hypergraphs from left to right 
 * @param fs A list of hypergraphs
 * @return The resulting composed hypergraph h = fs[0] . fs[1] . ... . fs[n-1]
 */
external func Seq(fs : ArrayList<Hypergraph>, name!: String = "") : Hypergraph {
    if(fs.size() == 0){
        Empty()
    }
    var res = fs[0]
    for(i in 1..fs.size() - 1){
        res = Seq(res, fs[i])
    }
    Seq(res, fs[fs.size() - 1], name: name)
}
/**
 * Sequentially compose a list of hypergraphs from left to right 
 * @param fs A list of hypergraphs
 * @return The resulting composed hypergraph h = fs[0] . fs[1] . ... . fs[n-1]
 */
external func Seq(fs : List<Hypergraph>, name!: String = "") {
    Seq(ArrayList<Hypergraph>(fs), name: name)
}

/**
 * Create an identity on n, the unit of sequential composition
 * @param n     The number of identity wires
 * @param label The name of the bus these wires will be part of. Cannot already exist in global state.
 * @param name  The name of the resulting hypergraph
 * @return An identity hypergraph on n
 */
external func Identity(n : Int64, name!: String = "", output!: String = "") : Hypergraph {
    Debug("Identity", "Making identity on ${n}, output='${output}'")
    if(n < 0){
        throw NegativeWireException("Identity")
    }
    let bus = NewBus(output)
    let newInputs = ArrayList<Target>()
    let newOutputs = ArrayList<Source>()
    let conns = MapBuilder<Target,Source>()
    for(i in 0..n){
        let t = Target()
        let s = Source(NewWire(bus, i))
        newInputs.add(t)
        newOutputs.add(s)
        conns.add(t,s)
    }
    Hypergraph(name, ArrayList<Edge>(), newInputs, newOutputs, conns)
}

/**
 * Compose in parallel hypergraphs f : m -> n and g : p -> q, creating h : m + p -> n + q
 * Clones f and g before composing
 * @param f       The lhs of the composition
 * @param g       The rhs of the composition
 * @param name="" The name of the resulting hypergraph
 * @return The composed hypergraph h = f * g
 */
external func Par(f : Hypergraph, g : Hypergraph, name!: String = "") : Hypergraph {
    Debug("Par", "Composing ${f.GetName()} and ${g.GetName()} in parallel")
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
    Hypergraph(name, newEdges, newInputs, newOutputs, newConns)
}
/**
 * Compose in parallel a list of hypergraphs from left to right 
 * @param fs         A list of hypergraphs
 * @param name=""    The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = fs[0] * fs[1] * ... * fs[n-1]
 */
external func Par(fs : ArrayList<Hypergraph>, name!: String = "") : Hypergraph {
    if(fs.size() == 0){
        return Empty()
    }
    if(fs.size() == 1){
        return fs[0]
    }
    var res = fs[0]
    for(i in 1..fs.size() - 1){
        res = Par(res, fs[i])
    }
    Par(res, fs[fs.size()-1], name: name)
}
/**
 * Compose in parallel a list of hypergraphs from left to right 
 * @param fs         A list of hypergraphs
 * @param name=""    The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = fs[0] * fs[1] * ... * fs[n-1]
 */
external func Par(fs : List<Hypergraph>, name!: String = "") : Hypergraph {
    Par(ArrayList<Hypergraph>(fs), name: name)
}
/**
 * Compose multiple copies of a hypergraph in parallel
 * @param f          The hypergraph to compose
 * @param n          The number of times to compose the hypergraph
 * @param name       The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = f * f * ... * f
 */
external func Par(f : Hypergraph, n : Int64, name!: String = "") : Hypergraph {
    Debug("Par", "Composing ${n} copies of '${f.GetName()}' in parallel")
    let fs = ArrayList<Hypergraph>(n, {x => f})
    Par(fs, name: name)
}

/** 
 * The empty hypergraph, the unit of parallel composition
 * @param name="" The name to give the resulting hypergraph
 */
external func Empty(name!: String = "") : Hypergraph { 
    Identity(0, name: name) 
}

/**
 * A swap hypergraph on m and n, that swaps over the first m inputs with the last n inputs
 * @param m The first argument of the swap
 * @param n The second argument of the swap
 * @param name="" The name of the resulting hypergraph
 */
external func Swap(m : Int64, n : Int64, name!: String = "") : Hypergraph {
    Debug("Swap", "Creating swap on ${m} and ${n}")
    if(m < 0 || n < 0){
        throw NegativeWireException("Swap")
    }
    let newInputs = ArrayList<Target>()
    let newOutputs = ArrayList<Source>()
    for(i in 0..m+n){
        newInputs.add(Target())
        newOutputs.add(Source())
    }
    let conns = MapBuilder<Target,Source>()
    for(i in 0..m){
        conns.add(newInputs.get(i), newOutputs.get(n+i))
    }
    for(i in 0..n){
        conns.add(newInputs.get(m + i), newOutputs.get(i))
    }
    Hypergraph(name, [], newInputs, newOutputs, conns)
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
external func Trace(f : Hypergraph, x : Int64, name!: String = ""){
    Debug("Trace", "Tracing ${f.GetName()} with ${x} wires")
    if(x < 0){
        throw NegativeTraceException("Trace") 
    }
    if(x > f.GetM() || x > f.GetN()){
        throw TooMuchTraceException("Trace")
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
    Hypergraph(name, newEdges, newInputs, newOutputs, newF.GetConnsR())
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
external func Get(f : Hypergraph, n : Int64, label! : String = "", name!: String = ""){
    Get(f, ArrayList<Int64>([n]), label: label, name: name)
}
/**
 * Transform a hypergraph to one with only the given outputs exposed, stubbing the rest.
 * @param f  The hypergraph
 * @param ns The indices of the outputs to preserve
 * @param name The name of the resulting hypergraph
 * @return The hypergraph with only the given outputs exposed
 */
external func Get(f : Hypergraph, ns : ArrayList<Int64>, label!: String = "", name!: String = ""){
    for(n in ns){
        if(n < 0 || n > f.GetN()){
            throw BadOutputException("Get", n, f.GetN())
        }
    }
    let newF = f.Clone()
    let newEdges = newF.GetEdges()
    let newOutputs = ArrayList<Source>()
    for(i in 0..f.GetN()){
        let v = newF.GetOutputs()[i]
        if(!includes(ns, i)){
            let stub = Edge(STUB, [v], [])
            newEdges.add(stub)
        } else {
            newOutputs.add(v)
        }
    }
    Hypergraph(newEdges, newF.GetInputs(), newOutputs, newF.GetConnsR())
}
/**
 * Transform a hypergraph to one with only the given bus exposed, stubbing the rest.
 * @param f  The hypergraph
 * @param s The name of the bus to expose
 * @param name The name of the resulting hypergraph
 * @return The hypergraph with only the given bus exposed
 */
external func Get(f : Hypergraph, bus : String, name!: String = ""){
    Debug("Get", "Getting bus ${bus} from ${f.GetName()}")
    Extract(f, ArrayList<String>([bus]), name: name)
}
/**
 * Transform a hypergraph to one with only the given buses exposed, stubbing the rest.
 * @param f     The hypergraph
 * @param buses The list of the bus names to expose
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph with only the given bus exposed
 */
external func Get(f : Hypergraph, buses : List<String>, name!: String = ""){
    Debug("Get", "getting buses from ${f.GetName()}")
    Extract(f, ArrayList<String>(buses), name: name)
}
/**
 * Drop the nth output of a hypergraph, stubbing it while preserving the others
 * @param f     The hypergraph
 * @param buses The index of the output to stub
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph with only the given bus exposed
 */
external func Drop(f : Hypergraph, n : Int64,
 name!: String = ""){
    Debug("Drop", "Dropping ${n}th port from ${f.GetName()} : ${f.GetM()} -> ${f.GetN()}")
    if(n < 0 || n >= f.GetN()){
        throw TypeMismatchException("Drop", f, n)
    }
    // Initialise a builder with a clone of f
    let hb = f.Clone()
    // Get the output to drop
    let s = hb.GetOutputs()[n]
    // Connect this output to a stub
    hb.ConnectOutputs(ArrayList<Int64>([n]), STUB)
    hb.ToGraph()
}