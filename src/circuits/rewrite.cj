/**
* rewrite.cj
*
* This file contains the definition of rewrite rules and the rewriter
*/

package circuits

import debug.*

/**
 * Conditions that can trigger the activation of rewrites 
 * If an edge satisfies the trigger, it will be checked for rewriting potential
 * If there is potential, the rewrite will be performed
 */
enum EntryPoint { 
    | EXACTLY(Generator)  // Trigger for a given generator 
    | GATE                // Trigger for all gates
    | DELAY               // Trigger for a delay
    | ANY                 // Trigger for any edge
}

class RewriteRule {
    /**
     * The name of this rewrite rule
     */
    private let name : String
    /**
     * The entry point that will trigger this rewrite rule 
     */
    private let entryPoint : EntryPoint
    /**
     * Given an edge, can we perform this rewrite rule?
     * If yes, return Some(i), where i is spme numeric payload (depending on rule)
     * If no, returns None
     */
    private let canRewrite : (Edge) -> Option<Int64>
    /**
     * Perform the rewrite rule on this edge with a given hypf and payload, returning the next sources to explore
     */
    private let rewrite : (Edge, HypBuilder, Int64) -> ArrayList<Source>
    init(name : String, entryPoint: EntryPoint, canRewrite : (Edge) -> Option<Int64>, rewrite : (Edge, HypBuilder, Int64) -> ArrayList<Source>){
        this.name = name
        this.entryPoint = entryPoint
        this.rewrite = rewrite
        this.canRewrite = canRewrite
    }
    /**
     * Get the name of this rewrite rule
     */
    func GetName() { name }
    /**
     * Check if this rewrite rule can be performed for a given edge
     * @param e The edge to check for rewriting potential
     */
    func CanRewrite(e : Edge){
        let b = match(entryPoint){
            case EXACTLY(gen) => e.generator == gen
            case $GATE        => e.IsGate()
            case $DELAY       => e.IsDelay()
            case $ANY         => true
        }
        if(b){
            canRewrite(e)
        } else {
            None<Int64>
        }
    }
    /**
     * Perform a rewrite with this rewrite rule
     * Assumes that CanRewrite has returned true
     * @param e The edge to rewrite
     * @param hb The hyp builder the edge belongs to
     * @param payload Additional information provided by CanRewrite
     */
    func Rewrite(e : Edge, hb : HypBuilder, payload : Int64){
        Debug("Rewrite", "Rewriting e${e.id} with rule ${name}")
        let nexts = rewrite(e, hb, payload)
        let (b, wf) = hb.IsWellFormed()
        if(!b){
            throw BadHypergraphException(hb, wf)
        }
        nexts
    }
}
/**
 * Is a given source target the output of a waveform?
 * For this to be the case, it must be connected to a join edge on the right
 * that joins a delay and a value together
 * @param s The source vertex
 */
func IsWaveform(s : Source){
    match(PortToGenerator(s.GetLeftPort(), JOIN)){
        case Some((e, i)) =>
            let lhsArg = e.GetSource(0)
            let rhsArg = e.GetSource(1)
            IsValue(lhsArg.GetLeftPort()) && IsDelay(rhsArg.GetLeftPort())
        case $None => false
    }
}

class Rewriter {
    /**
     * The list of rules that this rewriter will consider when performing rewriting
     * By default this is the list linkified in rules.cj
     */
    private let rules : ArrayList<RewriteRule> = rewriteRules
    /**
     * The hyp builder that is being rewritten
     * This will be modified during rewriting
     */
    private let f : HypBuilder
    private var rewrites = 0
    init(f : Hypergraph){
        this.f = f.Clone()
        ResolveLinks(this.f)
    }
    /**
     * Clone the graph in this rewriter, unresolve the links
     * and return it
     */
    func GetGraph(){
        let g = f.ToGraph().Clone()
        UnresolveLinks(g)
        g.ToGraph()
    }
    /**
     * Run a cycle of the rewriting system
     */
    func RunCycle() {
        // Isolate the head(s) of the waveform
        let heads = ArrayList<ArrayList<Waveform>>()
        var i = 0
        while(f.IsProductive()){
            heads.add(DetachHead())
            i++
        }
        // Perform any available redexes
        RunLocal()
        // Unfold the rest of the circuit
        Unfold()  
        // Tidy up the resulting circuit
        RunLocal() 
        // There may be loops that are inaccessible from the outputs
        TidyUpGraph()
        // If we have one, reattach the head
        while(heads.size() != 0){
            ReattachHead(heads.removeAt(heads.size() - 1))
        }
    }
    /**
     * Perform all local reductions in the graph, traversing from the endpoints (outputs and edges with 0 inputs)
     */
    func RunLocal(){
        let frontier = GetEndpoints(f)
        while(frontier.size() != 0){
            let s = frontier.removeAt(0)
            RunLocal(s)
        }
    }
    /**
     * Perform all local reductions from a given source vertex
     * @param s The source vertex to traverse from
     */
    func RunLocal(s : Source) : Unit {
        // We may have removed this source while rewriting other parts of the graph
        if(includes(f.GetSources(), s) && s.HasConn()){
            var rewrote = false
            match(s.GetLeftPort()){
                case EdgePort(e, i) =>
                    let next = ArrayList<Source>()
                    // Identity edges 'block' the rewriter, as this will be handled by the unfoldings
                    // However we sometimes can rewrite them, like if they're just stubbed
                    if(!e.IsIdentity()){
                        for(v in e.sources){
                            RunLocal(v)
                        }
                    }
                    // We may have removed this edge while rewriting the children
                    if(includes(f.GetEdges(), e)){
                        for(rule in rules){
                            if(!rewrote){
                                let can = rule.CanRewrite(e)
                                match(can){
                                    case Some(j) =>
                                        let nexts = rule.Rewrite(e, f, j)
                                        rewrites++
                                        next.addAll(nexts)
                                        rewrote = true
                                    case $None   => ()
                                }
                            }
                        }
                        for(v in next){
                            RunLocal(v)
                        }
                    }
                case InterfacePort(i) => ()
            }
        }
    }
    /**
     * Isolate the 'head' of a waveform from a larger graph
     * This applies to a circuit of form (f + delay) * v, where v will occur before anything else
     * If we try to unfold with this in place, then we will keep going in circles
     */ 
    func DetachHead(){
        Debug("DetachHead", "Checking for immediate values")
        let outputs = f.GetOutputs()
        let waveforms = ArrayList<Waveform>()
        let newOutputs = ArrayList<Source>()
        for(s in outputs){
            match(s.GetLeftPort()){
                case EdgePort(e, i) =>
                    match(IsWaveform(e)){
                        case Some(w) => waveforms.add(w)
                        case $None => throw NonProductiveException("DetachHead", f)
                    }
                case InterfacePort(i) => throw NonProductiveException("DetachHead", f)
            }
        }
        // If we're still here, then we are in the correct form
        let head = ArrayList<Edge>()
        f.RemoveOutputs()
        for(w in waveforms){
            f.RemoveEdge(w.value)
            f.RemoveEdge(w.delay)
            f.RemoveEdge(w.join)
            f.ConnectPortToOutputs(w.delay.GetSource(0).GetLeftPort())
        }
        waveforms
    }
    /**
     * Perform one unfolding of a hypergraph, which corresponds to one clock cycle
     * First the 'global trace delay form' is established: this is a simple case of identifying the delay and identity edges
     * @param f The hyp f to unfold
     */ 
    func Unfold(){
        Debug("Unfold", "Performing unfolding")
        // Identify Trace-delay form
        let outgoingSources = ArrayList<Source>()
        f.ForEachEdgeWithProperty(
            { e : Edge => e.IsDelay() || e.IsIdentity() },
            { e : Edge => outgoingSources.add(e.GetSource(0)) }
        )
        // We make a copy of the graph (the unfolding)
        // This is a deep copy as it represents an actual physical copy of the circuit
        let g = f.ToGraph().Clone(deep: true)
        let danglingSources = ArrayList<Source>()
        let identitiesToDelete = ArrayList<Edge>()
        g.ForEachEdgeWithProperty(
            { e : Edge => e.IsDelay() || e.IsIdentity() },
            { e : Edge =>
                let stub = g.CreateEdge(STUB)
                g.AddConn(e.GetSource(0).GetConn(), stub.GetSource(0))
                if(e.IsIdentity()){
                    identitiesToDelete.add(e)
                }
                danglingSources.add(e.GetSource(0))
            }
        )
        f.ConnectEachOutputToEdge(STUB)
        // Add the copy to the original 
        f.AddNewGraph(g)
        // Hook up the dangling vertices
        for(i in 0..outgoingSources.size()){
            let s = outgoingSources[i]
            let fork = f.CreateEdge(FORK)
            f.AddConn(s.GetConn(), fork.GetSource(0))
            f.AddConn(fork.GetTarget(0), s)
            f.AddConn(fork.GetTarget(1), danglingSources[i])
        }
        for(i in 0..g.GetInputs().size()){
            let fork = f.CreateEdge(FORK)
            f.AddConn(fork.GetTarget(0), f.GetInput(i).GetConn())
            f.AddConn(f.GetInput(i), fork.GetSource(0))
            f.AddConn(fork.GetTarget(1), g.GetInput(i).GetConn())
            f.RemoveInput(g.GetInputs().size())
        }
        for(e in identitiesToDelete){
            f.AddConn(e.GetSource(0).GetConn(), e.GetTarget(0).GetConn())
            f.RemoveEdge(e)
        }
    }
    /**
     * Reattach a list of waveform heads to the graph
     * @param head The list of waveform heads to reattach
     */
    func ReattachHead(head : ArrayList<Waveform>){
        Debug("ReattachHead", "Adding any immediate values")
        for(i in 0..head.size()){
            let w = head[i]
            f.AddConn(f.GetOutput(i).GetConn(), w.delay.GetSource(0))
            f.AddConn(head[i].join.GetTarget(0), f.GetOutput(i))
            f.AddEdge(w.delay)
            f.AddEdge(w.join)
            f.AddEdge(w.value)
        }
    }
    /**
     * Perform some tidy up operations that cannot be done by the rewriter
     * a) Remove any self loops that are inaccessible from the outputs
     */
    func TidyUpGraph(){
        let idEdges = f.GetAllIdentityEdges()
        let removedEdges = ArrayList<Edge>()
        for(id in idEdges){
            if(!PathToOutputs(id)){
                // Traverse leftwards from the id edge and delete as we go
                // Importantly, this will eliminate any loops
                TraverseLeft(id.GetSource(0).GetConn(), 
                    {e : Edge, t : Target => 
                        if(e.IsIdentity()){
                            false
                        } else {
                            removedEdges.add(e)
                            true
                        }
                    }, 
                    {t : Target, i : Int64 => }
                )
                removedEdges.add(id)
            }
        }
        f.RemoveEdges(removedEdges)
    }
}