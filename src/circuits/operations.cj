/**
 * operations.cj
 *
 * This file contains the definition of hypergraph operations
 */

package circuits

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
external func Seq(f : Hypergraph, g : Hypergraph, name!: String = "") {
    Debug("Seq", "Composing ${f.GetName()} and ${g.GetName()} in sequence")
    SeqBuilder(f.Clone(), g.Clone(), name: name)
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
func SeqBuilder(f : HypBuilder, g : HypBuilder, name!: String = "") : Hypergraph {
    if(f.GetN() != g.GetM()){
        throw TypeMismatchException("Seq", f, g)
    }
    let fouts = map(f.GetOutputs(), {s : Source => s.GetConn()})
    let wires = map(f.GetOutputs(), {s : Source => s.wires})
    f.RemoveOutputs()
    let gins = map(g.GetInputs(), {t : Target => t.GetConn()})
    g.RemoveInputs()
    f.AddNewGraph(g)
    for(i in 0..fouts.size()){
        gins[i].AddWires(wires[i])
        f.AddConn(fouts[i], gins[i])
    }
    f.ToGraph()
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
 * Create an identity hyp builder on n, the unit of sequential composition
 * @param n     The number of identity wires
 * @param label The name of the bus these wires will be part of. Cannot already exist in global state.
 * @param name  The name of the resulting hypergraph
 * @return An identity hyp builder on n
 */
func CreateIdentity(n : Int64, name!: String = "", label!: String = "") : HypBuilder {
    Debug("Identity", "Making identity on ${n}, label='${label}'")
    if(n < 0){
        throw NegativeWireException("Identity")
    }
    let hb = HypBuilder(n, n, label)
    for(i in 0..n){
        hb.AddConn(hb.GetInput(i), hb.GetOutput(i))
    }
    hb
}
/**
 * Create an identity on n, the unit of sequential composition
 * @param n     The number of identity wires
 * @param label The name of the bus these wires will be part of. Cannot already exist in global state.
 * @param name  The name of the resulting hypergraph
 * @return An identity hypergraph on n
 */
external func Identity(n : Int64, name!: String = "", label!: String = "") : Hypergraph {
    let hb = CreateIdentity(n, name: name, label: label)
    hb.ToGraph(name)
}
/**
 * Create an identity on 1, the unit of sequential composition
 * @param label The name of the bus these wires will be part of. Cannot already exist in global state.
 * @param name  The name of the resulting hypergraph
 * @return An identity hypergraph on n
 */
external func Identity(name!: String = "", label!: String = "") : Hypergraph {
    Identity(1, name: name, label: label)
}

/**
 * Compose in parallel hypergraphs f : m -> n and g : p -> q, creating h : m + p -> n + q
 * Clones f and g before composing
 * @param f       The lhs of the composition
 * @param g       The rhs of the composition
 * @param name="" The name of the resulting hypergraph
 * @return The composed hypergraph h = f * g
 */
external func Par(f : Hypergraph, g : Hypergraph, name!: String = "") {
    Debug("Par", "Composing ${f.GetName()} and ${g.GetName()} in parallel")
    ParBuilder(f.Clone(), g.Clone(), name: name)
}
/**
 * Compose in parallel hypergraphs f : m -> n and g : p -> q, creating h : m + p -> n + q
 * Clones f and g before composing
 * @param f       The lhs of the composition
 * @param g       The rhs of the composition
 * @param name="" The name of the resulting hypergraph
 * @return The composed hypergraph h = f * g
 */
func ParBuilder(f : HypBuilder, g : HypBuilder, name!: String = "") : Hypergraph {
    f.AddNewGraph(g)
    f.ToGraph(name)
}
/**
 * Compose in parallel a list of hypergraphs from left to right 
 * @param fs         A list of hypergraphs
 * @param name=""    The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = fs[0] * fs[1] * ... * fs[n-1]
 */
external func Par(fs : ArrayList<Hypergraph>, name!: String = "") : Hypergraph {
    ParBuilder(map(fs, {f : Hypergraph => f.Clone()}))
}
/**
 * Compose in parallel a list of hyp builders from left to right 
 * @param fs         A list of hyp builders
 * @param name=""    The name to give the resulting hypergrah 
 * @return The resulting composed hypergraph h = fs[0] * fs[1] * ... * fs[n-1]
 */
func ParBuilder(fs : ArrayList<HypBuilder>, name!: String = "") : Hypergraph {
    if(fs.size() == 0){
        return Empty()
    }
    let res = fs[0]
    if(fs.size() > 1){
        for(i in 1..fs.size()){
            res.AddNewGraph(fs[i])
        }
    }
    res.ToGraph(name)    
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
    ParBuilder(f, n, name: name)
}
/**
 * Compose multiple copies of a hyp builder in parallel
 * @param f          The hyp builder to compose
 * @param n          The number of times to compose the hyp builder
 * @param name       The name to give the resulting hypergraph 
 * @return The resulting composed hypergraph h = f * f * ... * f
 */
func ParBuilder(f : Hypergraph, n : Int64, name!: String = "") : Hypergraph {
    let fs = ArrayList<HypBuilder>(n, {x => f.Clone(deep: true)})
    ParBuilder(fs, name: name)
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
external func Symmetry(m : Int64, n : Int64, name!: String = "") : Hypergraph {
    Debug("Symmetry", "Creating swap on ${m} and ${n}")
    if(m < 0 || n < 0){
        throw NegativeWireException("Symmetry")
    }
    let hb = HypBuilder(m + n, m + n)
    for(i in 0..m){
        let t = hb.GetInput(i)
        t.SetConn(hb.GetOutput(n + i))
    }
    for(i in 0..n){
        let t = hb.GetInput(m + i)
        t.SetConn(hb.GetOutput(i))
    }
    hb.ToGraph(name)
}
/**
 * A hypergraph that swaps two wires
 * @param name The name of the resulting hypergraph
 */
external func Symmetry(name!: String = "") : Hypergraph {
    Symmetry(1, 1, name: name)
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

    let hb = f.Clone()
    let link = Link(4)
    let outlink = hb.ConnectOutputsToEdge(ArrayList<Int64>(x, {i : Int64 => i}), OUTLINK(link))
    let inlink = hb.ConnectInputsToEdge(ArrayList<Int64>(x, {i : Int64 => i}), INLINK(link)) 
    hb.ToGraph()
}
/**
 * Shorthand for tracing hypergraphs (reflects the Tr^x(f) notation used on paper)
 * @param x The number of wires to trace
 * @param f The hypergraph to trace
 * @return The traced hypergraph
 */
external func Tr(x : Int64, f : Hypergraph){
    Trace(f, x)
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
    GetBuilder(f.Clone(), ArrayList<Int64>([n]), label: label, name: name)
}
/**
 * Transform a hyp builder of type m->n to one of type m->1, preserving the nth 
 * output and stubbing the rest.
 * @param f     The hyp builder
 * @param n     The index of the output to preserve
 * @param label The label to assign the exposed port
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph with only the nth output exposed
 */
func GetBuilder(f : HypBuilder, n : Int64, label! : String = "", name!: String = ""){
    GetBuilder(f, ArrayList<Int64>([n]), label: label, name: name)
}
/**
 * Transform a hypergraph to one with only the given outputs exposed, stubbing the rest.
 * @param f  The hypergraph
 * @param ns The indices of the outputs to preserve
 * @param name The name of the resulting hypergraph
 * @return The hypergraph with only the given outputs exposed
 */
external func Get(f : Hypergraph, ns : ArrayList<Int64>, label!: String = "", name!: String = ""){
    GetBuilder(f.Clone(), ns, label: label, name: name)
}
func GetBuilder(f : HypBuilder, ns : ArrayList<Int64>, label!: String = "", name!: String = ""){
    Debug("Get", "Getting outputs ${PrintList(ns, {n : Int64 => "${n}"})} from ${f.GetName()}")
    for(n in ns){
        if(n < 0 || n > f.GetN()){
            throw BadOutputException("Get", n, f.GetN())
        }
    }
    let drops = ArrayList<Source>(f.GetOutputs())
    for(n in ns){
        drops.removeIf({s : Source => s == f.GetOutputs()[n]})
    }
    for(d in drops){
        f.ConnectOutputToEdge(d, STUB)
    }
    f.ToGraph()
}
/**
 * Transform a hypergraph to one with only the given bus exposed, stubbing the rest.
 * @param f    The hypergraph
 * @param s    The name of the bus to expose
 * @param name The name of the resulting hypergraph
 * @return The hypergraph with only the given bus exposed
 */
external func Get(f : Hypergraph, bus : String, name!: String = ""){
    Debug("Get", "Getting bus ${bus} from ${f.GetName()}")
    GetBuilder(f.Clone(), bus, name: name)
}
func GetBuilder(f : HypBuilder, bus : String, name!: String = ""){
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
    Extract(f.Clone(), ArrayList<String>(buses), name: name)
}
func Get(f : HypBuilder, buses : List<String>, name!: String = ""){
    Extract(f, ArrayList<String>(buses), name: name)
}
/**
 * Drop the nth output of a hypergraph, stubbing it while preserving the others
 * @param f     The hypergraph
 * @param buses The index of the output to stub
 * @param name  The name of the resulting hypergraph
 * @return The hypergraph with only the given bus exposed
 */
external func Drop(f : Hypergraph, n : Int64, name!: String = ""){
    Debug("Drop", "Dropping ${n}th port from ${f.GetName()} : ${f.GetM()} -> ${f.GetN()}")
    if(n < 0 || n >= f.GetN()){
        throw TypeMismatchException("Drop", f, n)
    }
    // Initialise a builder with a clone of f
    let hb = f.Clone()
    // Get the output to drop
    let s = hb.GetOutputs()[n]
    // Connect this output to a stub
    hb.ConnectOutputsToEdge(ArrayList<Int64>([n]), STUB)
    hb.ToGraph()
}
/**
 * Drop all the outputs after a given index
 * @param f The hypergraph
 * @param n The output (inclusive) from where to start dropping
 * @return The hypergraph with all the outputs 8..n dropped
 */
external func DropFrom(f : Hypergraph, n : Int64){
    Debug("DropFrom", "Dropping ports ${n}-${f.GetN()-1} from ${f.GetName()} : ${f.GetM()} -> ${f.GetN()}")
    if(n < 0 || n >= f.GetN()){
        throw TypeMismatchException("DropFrom", f, n)
    }
    let hb = f.Clone()
    for(i in n..f.GetN()){
        hb.ConnectOutputToEdge(n, STUB)
    }
    hb.ToGraph()
}
/**
 * Drop all the outputs until a given index
 * @param f The hypergraph
 * @param n The output (exclusive) until when the outputs are dropped
 * @return The hypergraph with all the outputs 0..n dropped
 */
external func DropUntil(f : Hypergraph, n : Int64){
    Debug("DropFrom", "Dropping ports 0-${n-1} from ${f.GetName()} : ${f.GetM()} -> ${f.GetN()}")
    if(n < 0 || n >= f.GetN()){
        throw TypeMismatchException("DropUntil", f, n)
    }
    let hb = f.Clone()
    for(i in 0..n){
        hb.ConnectOutputToEdge(0, STUB)
    }
    hb.ToGraph()

}