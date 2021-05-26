/**
 * rules.cj
 *
 * This file contains rewrite rules that make up the first part of the operational semantics
 */

package circuits

/* Common preconditions */
func NextEdgeIs(t : Target, gen : Generator){
    match(t.GetRightPort()){
        case EdgePort(e, i)   => e.generator == gen
        case InterfacePort(i) => false
    }
}

let forkStubLeft = RewriteRule(
    "Fork-stub left",
    FORK,
    {e : Edge => NextEdgeIs(e.targets[0], STUB) },
    {e : Edge, hb : HypBuilder => 
        hb.AddConn(e.sources[0].GetConn(), e.targets[1].GetConn())
        hb.RemoveEdge(e.targets[0].GetRightEdge())
        hb.RemoveEdge(e)
    }
)
let forkStubRight = RewriteRule(
    "Fork-stub right",
    FORK,
    {e : Edge => NextEdgeIs(e.targets[1], STUB) },
    {e : Edge, hb : HypBuilder => 
        hb.AddConn(e.sources[0].GetConn(), e.targets[0].GetConn())
        hb.RemoveEdge(e.targets[1].GetRightEdge())
        hb.RemoveEdge(e)
    }
)


let rewriteRules = ArrayList<RewriteRule>([
    forkStubLeft,
    forkStubRight
])
let rewriter = Rewriter(rewriteRules)