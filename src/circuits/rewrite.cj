/**
* rewrite.cj
*
* This file contains the definition of rewrite rules and the rewriter
*/

package circuits

import debug.*

enum EntryPoint { 
    | EXACTLY(Generator)
    | ANY_GATE
    | ANY
}

class RewriteRule {
    private let name : String
    private let entryPoint : EntryPoint
    // Given an edge, can we perform this rewrite rule?
    // If yes, return Some(i), where i is spme numeric payload (depending on rule)
    // If no, returns None
    private let canRewrite : (Edge) -> Option<Int64>
    // Perform the rewrite rule on this edge with a given hypbuilder and payload, returning the next sources to explore
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
            case $ANY_GATE    => e.targets.size() == 1
            case ANY          => true
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
        print("${hb}")
        nexts
    }
}

class Rewriter {
    let rules : ArrayList<RewriteRule>
    init(rules : ArrayList<RewriteRule>){
        this.rules = rules
    }
    func Run(f : Hypergraph) : Hypergraph {
        // Clone the hypergraph to be rewritten
        let f = f.Clone()
        // First resolve any links
        ResolveLinks(f)
        // Run all local optimisations
        RunLocal(f)
        // Isolate the head of the waveform
        let head = IsolateHead(f)
        f.ToGraph()
    }
    func RunLocal(f : HypBuilder){
        let frontier = GetEndpoints(f)
        while(frontier.size() != 0){
            let s = frontier.removeAt(0)
            // We may have removed this source while rewriting other parts of the graph
            if(includes(f.GetSources(), s)){
                RunLocal(f,s)
            }
        }
        f.ToGraph()
    }
    func RunLocal(hb : HypBuilder, s : Source) : Unit {
        Debug("Run", "Rewriting from source ${s.id}")
        match(s.GetLeftPort()){
            case EdgePort(e, i) => {
                let next = ArrayList<Source>()
                // Identity edges 'block' the rewriter, as this will be handled by the unfoldings
                if(!e.IsIdentity()){
                    for(v in e.sources){
                        RunLocal(hb, v)
                    }
                    var rewrote = false
                    for(rule in rules){
                        if(!rewrote){
                            let can = rule.CanRewrite(e)
                            match(can){
                                case Some(j) => {
                                    let nexts = rule.Rewrite(e, hb, j)
                                    next.addAll(nexts)
                                    rewrote = true
                                }
                                case $None   => {}
                            }
                        }
                    }
                    for(v in next){
                        RunLocal(hb, v)
                    }
                }
            }
            case InterfacePort(i) => {}
        }
    }
    /**
     * Isolate the 'head' of a waveform from a larger graph
     * This applies to a circuit of form (f + delay) * v, where v will occur before anything else
     * If we try to unfold with this in place, then we will keep going in circles
     * @param f The hyp builder
     */ 
    func IsolateHead(f : HypBuilder){
        let outputs = f.GetOutputs()
        let valuesDelaysJoins = ArrayList<Edge * Edge * Edge>()
        let newOutputs = ArrayList<Source>()
        var fail = false
        for(s in outputs){
            match(s.GetLeftPort()){
                case EdgePort(e, i) => {
                    if(e.HasGenerator(JOIN)){
                        let leftSource = e.sources[0]
                        let leftArg = leftSource.GetLeftPort()
                        let rightSource = e.sources[1]
                        let rightArg = rightSource.GetLeftPort()
                        let value : Edge
                        let delay : Edge
                        if(IsValue(leftArg) && IsDelay(rightArg)){
                            value = leftSource.GetLeftEdge()
                            delay = rightSource.GetLeftEdge()
                        } else if (IsValue(rightArg) && IsDelay(leftArg)){
                            value = rightSource.GetLeftEdge()
                            delay = leftSource.GetLeftEdge()
                        } else {
                            // The arguments of the join do not have an immediate component and a delayed component
                            return None<ArrayList<Value>>
                        }
                        valuesDelaysJoins.add((value, delay, e))
                        newOutputs.add(delay.sources[0])
                    } else {
                        // This branch does not currently have an instantaneous value
                        // Either more rewrites or an unfolding is required
                        return None<ArrayList<Value>>
                    }
                }
                case InterfacePort(i) => return None<ArrayList<Value>>
            }
        }
        // If we're still here, then we are in the correct form
        let head = ArrayList<Value>()
        f.RemoveOutputs()
        for((v,d,j) in valuesDelaysJoins){
            head.add(v.GetValue())
            f.RemoveEdge(v)
            f.RemoveEdge(d)
            f.RemoveEdge(j)
        }
        f.AddOutputs(newOutputs)
        Some<ArrayList<Value>>(head)
    }
}

external func TestRewrites(f : Hypergraph){
    Info("RewriteAll", "Performing all local optimisations")
    let g = rewriter.Run(f)
    g
}