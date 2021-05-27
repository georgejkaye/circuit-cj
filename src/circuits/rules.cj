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


func HasValueArguments(edge : Edge){
    for(s in edge.sources){
        match(s.GetLeftPort()){
            case EdgePort(e, i) => if(!IsValue(e.generator)){ return false }
            case InterfacePort(i) => return false
        }
    }
    return true
}

func ReplaceGateWithValue(edge : Edge, hb : HypBuilder, v : Value){
    for(s in edge.sources){
        hb.RemoveEdge(s.GetLeftEdge())
    }
    let newEdge = hb.CreateEdge(VALUE(v))
    hb.AddConn(newEdge.targets[0], edge.targets[0].GetConn())
    hb.RemoveEdge(edge)
}

func EvaluateGate(edge : Edge, hb : HypBuilder, tt : TruthTable){
    let v = tt.Eval(map(edge.sources, {s : Source => s.GetLeftEdge().GetValue()}))
    ReplaceGateWithValue(edge, hb, v)
}

class TruthTable {
    let dom : Int64
    let table : (ArrayList<Value>) -> Value
    init(dom : Int64, table : (ArrayList<Value>) -> Value) {
        this.dom = dom
        this.table = table
    }
    func Eval(args : ArrayList<Value>){
        if(args.size() != dom){
            throw BadDomainException("Eval", args.size(), dom)
        }
        table(args)
    }
}

let andTable = TruthTable(
    2,
    {args : ArrayList<Value> => 
        match(args[0]){
            case $TOP    => TOP
            case $BOTTOM => BOTTOM
            case $TRUE   => args[1]
            case $FALSE  => match(args[1]){
                case $TOP    => TOP
                case $BOTTOM => BOTTOM
                case _       => FALSE
            }
        }
    }
)

let andEval = RewriteRule(
    "And",
    AND,
    HasValueArguments,
    {e : Edge, hb : HypBuilder => EvaluateGate(e, hb, andTable)}
)


let rewriteRules = ArrayList<RewriteRule>([
    forkStubLeft,
    forkStubRight,
    andEval
])
let rewriter = Rewriter(rewriteRules)