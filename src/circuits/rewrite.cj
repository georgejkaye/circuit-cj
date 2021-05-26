/**
* rewrite.cj
*
* This file contains the definition of rewrite rules and the rewriter
*/

package circuits

import debug.*

class RewriteRule {
    private let name : String
    private let entryPoint : Generator
    // Given an edge, can we perform this rewrite rule?
    private let canRewrite : (Edge) -> Bool
    // Perform the rewrite rule on this edge
    private let rewrite : (Edge, HypBuilder) -> Unit

    init(name : String, entryPoint: Generator, canRewrite : (Edge) -> Bool, rewrite : (Edge, HypBuilder) -> Unit){
        this.name = name
        this.entryPoint = entryPoint
        this.rewrite = rewrite
        this.canRewrite = canRewrite
    }
    func GetName() { name }
    func CanRewrite(e : Edge){
        if(e.generator == entryPoint){
            canRewrite(e)
        } else {
            false
        }
    }
    func Rewrite(e : Edge, hb : HypBuilder){
        Debug("Rewrite", "Rewriting e${e.id} with rule ${name}")
        rewrite(e, hb)
    }
}


class Rewriter {
    let rules : ArrayList<RewriteRule>
    init(rules : ArrayList<RewriteRule>){
        this.rules = rules
    }
    func Run(f : Hypergraph){
        let f = f.Clone()
        f.ToGraph()
    }
    func Run(hb : HypBuilder, e : Edge){
        var rewrote = false
        for(rule in rules){
            if(!rewrote){
                if(rule.CanRewrite(e)){
                    rule.Rewrite(e, hb)
                    rewrote = true
                }
            }
        }
    }
}

external func TestRewrites(f : Hypergraph){
    Info("RewriteAll", "Performing all local optimisations")
    let f = f.Clone()
    for(e in f.GetEdgesWithGenerator(FORK)){
        rewriter.Run(f, e)
    }
    f.ToGraph()
}