/**
* rewrite.cj
*
* This file contains the definition of rewrite rules and the rewriter
*/

package circuits

import debug.*

enum EntryPoint { 
    | EXACTLY(Generator)
    | GATE
    | DELAY
    | ANY
}

class RewriteRule {
    private let name : String
    private let entryPoint : EntryPoint
    // Given an edge, can we perform this rewrite rule?
    // If yes, return Some(i), where i is spme numeric payload (depending on rule)
    // If no, returns None
    private let canRewrite : (Edge) -> Option<Int64>
    // Perform the rewrite rule on this edge with a given hypf and payload, returning the next sources to explore
    private let rewrite : (Edge, HypBuilder, Int64) -> ArrayList<Source>
    init(name : String, entryPoint: EntryPoint, canRewrite : (Edge) -> Option<Int64>, rewrite : (Edge, HypBuilder, Int64) -> ArrayList<Source>){
        this.name = name
        this.entryPoint = entryPoint
        this.rewrite = rewrite
        this.canRewrite = canRewrite
    }
    func GetName() { name }
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

func IsWaveform(s : Source){
    match(PortToGenerator(s.GetLeftPort(), JOIN)){
        case Some((e, i)) =>
            let lhsArg = e.sources[0]
            let rhsArg = e.sources[1]
            IsValue(lhsArg.GetLeftPort()) && IsDelay(rhsArg.GetLeftPort())
        case $None => false
    }
}

class Rewriter {
    private let rules : ArrayList<RewriteRule> = rewriteRules
    private let f : HypBuilder
    private var rewrites = 0
    init(f : Hypergraph){
        this.f = f.Clone()
        ResolveLinks(this.f)
    }
    func GetGraph(){
        f.ToGraph()
    }
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
        // If we have one, reattach the head
        while(heads.size() != 0){
            ReattachHead(heads.removeAt(heads.size() - 1))
        }
    }
    func RunLocal(){
        let frontier = GetEndpoints(f)
        while(frontier.size() != 0){
            let s = frontier.removeAt(0)
            // We may have removed this source while rewriting other parts of the graph
            if(includes(f.GetSources(), s)){
                RunLocal(s)
            }
        }
    }
    func RunLocal(s : Source) : Unit {
        var rewrote = false
        match(s.GetLeftPort()){
            case EdgePort(e, i) =>
                if(includes(f.GetEdges(), e)){
                    let next = ArrayList<Source>()
                    // Identity edges 'block' the rewriter, as this will be handled by the unfoldings
                    if(!e.IsIdentity()){
                        for(v in e.sources){
                            RunLocal(v)
                        }
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
                            if(v.HasConn()){
                                RunLocal(v)
                            }
                        }
                    }
                }
            case InterfacePort(i) => ()
        }
    }
    /**
     * Isolate the 'head' of a waveform from a larger graph
     * This applies to a circuit of form (f + delay) * v, where v will occur before anything else
     * If we try to unfold with this in place, then we will keep going in circles
     * @param f The hyp f
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
            f.ConnectPortToOutputs(w.delay.sources[0].GetLeftPort())
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
            { e : Edge => outgoingSources.add(e.sources[0]) }
        )
        // We make a copy of the graph (the unfolding)
        let g = f.ToGraph().Clone()
        let danglingSources = ArrayList<Source>()
        let identitiesToDelete = ArrayList<Edge>()
        g.ForEachEdgeWithProperty(
            { e : Edge => e.IsDelay() || e.IsIdentity() },
            { e : Edge =>
                let stub = g.CreateEdge(STUB)
                g.AddConn(e.sources[0].GetConn(), stub.sources[0])
                if(e.IsIdentity()){
                    identitiesToDelete.add(e)
                }
                danglingSources.add(e.sources[0])
            }
        )
        f.ConnectEachOutputToEdge(STUB)
        // Add the copy to the original 
        f.AddNewGraph(g)
        // Hook up the dangling vertices
        for(i in 0..outgoingSources.size()){
            let s = outgoingSources[i]
            let fork = f.CreateEdge(FORK)
            f.AddConn(s.GetConn(), fork.sources[0])
            f.AddConn(fork.targets[0], s)
            f.AddConn(fork.targets[1], danglingSources[i])
        }
        for(i in 0..g.GetInputs().size()){
            let fork = f.CreateEdge(FORK)
            f.AddConn(fork.targets[0], f.GetInput(i).GetConn())
            f.AddConn(f.GetInput(i), fork.sources[0])
            f.AddConn(fork.targets[1], g.GetInput(i).GetConn())
            f.RemoveInput(g.GetInputs().size())
        }
        for(e in identitiesToDelete){
            f.AddConn(e.sources[0].GetConn(), e.targets[0].GetConn())
            f.RemoveEdge(e)
        }
    }
    func ReattachHead(head : ArrayList<Waveform>){
        Debug("ReattachHead", "Adding any immediate values")
        for(i in 0..head.size()){
            let w = head[i]
            f.AddConn(f.GetOutput(i).GetConn(), w.delay.sources[0])
            f.AddConn(head[i].join.targets[0], f.GetOutput(i))
            f.AddEdge(w.delay)
            f.AddEdge(w.join)
            f.AddEdge(w.value)
        }
    }
}