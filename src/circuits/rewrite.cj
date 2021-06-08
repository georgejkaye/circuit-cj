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
        let f = ResolveLinks(f.Clone())
        let frontier = GetEndpoints(f)
        while(frontier.size() != 0){
            let s = frontier.removeAt(0)
            // We may have removed this source while rewriting other parts of the graph
            if(includes(f.GetSources(), s)){
                Run(f,s)
            }
        }
        f.ToGraph()
    }
    func Run(hb : HypBuilder, s : Source) : Unit {
        Debug("Run", "Rewriting from source ${s.id}")
        match(s.GetLeftPort()){
            case EdgePort(e, i) => {
                let next = ArrayList<Source>()
                if(!e.IsIdentity()){
                    for(v in e.sources){
                        Run(hb, v)
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
                        Run(hb, v)
                    }
                }
            }
            case InterfacePort(i) => {}
        }
    }
}

external func TestRewrites(f : Hypergraph){
    Info("RewriteAll", "Performing all local optimisations")
    let g = rewriter.Run(f)
    g
}