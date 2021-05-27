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
        let t = e.sources[0].GetConn()
        hb.AddConn(t, e.targets[1].GetConn())
        hb.RemoveEdge(e.targets[0].GetRightEdge())
        hb.RemoveEdge(e)
    }
)
let forkStubRight = RewriteRule(
    "Fork-stub right",
    FORK,
    {e : Edge => NextEdgeIs(e.targets[1], STUB) },
    {e : Edge, hb : HypBuilder => 
        let t = e.sources[0].GetConn()
        hb.AddConn(t, e.targets[0].GetConn())
        hb.RemoveEdge(e.targets[1].GetRightEdge())
        hb.RemoveEdge(e)
    }
)

let forkCopy = RewriteRule(
    "Fork",
    FORK,
    HasValueArguments,
    {e : Edge, hb : HypBuilder =>
        let arg = e.sources[0].GetLeftEdge()
        let copy = hb.CreateEdge(VALUE(arg.GetValue()))
        hb.AddConn(arg.targets[0], e.targets[0].GetConn())
        hb.AddConn(copy.targets[0], e.targets[1].GetConn())
        hb.RemoveEdge(e)
    }
)


/**
 * Check if the sources of an edge all connect to value edges
 * This allows us to reduce gates
 * @param edge The edge
 * @return Whether the argu
 */
func HasValueArguments(edge : Edge){
    for(s in edge.sources){
        match(s.GetLeftPort()){
            case EdgePort(e, i) => if(!IsValue(e.generator)){ return false }
            case InterfacePort(i) => return false
        }
    }
    return true
}
/**
 * Replace a gate edge with the value obtained from applying its arguments
 * @param edge The edge
 * @param hb   The hyp builder we are rewriting
 * @param v    The result of applying the gate's arguments
 */
func ReplaceGateWithValue(edge : Edge, hb : HypBuilder, v : Value){
    for(s in edge.sources){
        hb.RemoveEdge(s.GetLeftEdge())
    }
    let newEdge = hb.CreateEdge(VALUE(v))
    hb.AddConn(newEdge.targets[0], edge.targets[0].GetConn())
    hb.RemoveEdge(edge)
}
/**
 * Assuming that all its arguments are values, replaces a gate edge with the result
 * of applying it to its arguments
 * @param edge The edge
 * @param hb   The hyp builder we are rewriting
 * @param tt   The truth table to use to compute the result
 */
func EvaluateGate(edge : Edge, hb : HypBuilder, tt : TruthTable){
    let v = tt.Eval(map(edge.sources, {s : Source => s.GetLeftEdge().GetValue()}))
    ReplaceGateWithValue(edge, hb, v)
}
/**
 * Create a rewrite rule for evaluating a gate with a given truth table
 * The precondition for this rule is that the inputs must all be values
 * @param name The name of the rewrite rule
 * @param truthTable The truth table associated with this gate
 */
func GateRewriteRule(name : String, tt : TruthTable){
    RewriteRule(name, tt.generator, HasValueArguments, {e : Edge, hb : HypBuilder => EvaluateGate(e, hb, tt)})
}

let andEval = GateRewriteRule("AND eval", andTable)
let orEval = GateRewriteRule("OR eval", orTable)
let nandEval = GateRewriteRule("NAND eval", nandTable)
let norEval = GateRewriteRule("NOR eval", norTable)
let xorEval = GateRewriteRule("XOR eval", xorTable)
let xnorEval = GateRewriteRule("XNOR eval", andTable)


let rewriteRules = ArrayList<RewriteRule>([
    forkStubLeft,
    forkStubRight,
    forkCopy,
    andEval,
    orEval,
    nandEval,
    norEval,
    xorEval,
    xnorEval
])
let rewriter = Rewriter(rewriteRules)