/**
 * rules.cj
 *
 * This file contains rewrite rules that make up the first part of the operational semantics
 */

package circuits

/* Common preconditions */
func NextEdgeIs(t : Target, gen : Generator){
    match(t.GetRightPort()){
        case EdgePort(e, i)   => 
            if(e.generator == gen){
                Some<Int64>(0)
            } else {
                None<Int64>
            }
        case InterfacePort(i) => None<Int64>
    }
}
func PreviousEdgeIs(s : Source, gen : Generator){
    match(s.GetLeftPort()){
        case EdgePort(e, i)   => 
            if(e.generator == gen){
                Some<Int64>(0)
            } else {
                None<Int64>
            }
        case InterfacePort(i) => None<Int64>
    }
}

/**
 * Check if the sources of an edge all connect to value edges
 * This allows us to reduce gates
 * @param edge The edge
 * @return Some(0) if all the arguments are values, None otherwise)
 */
func HasValueArguments(edge : Edge){
    for(s in edge.sources){
        match(s.GetLeftPort()){
            case EdgePort(e, i) => if(!IsValue(e.generator)){ return None<Int64> }
            case InterfacePort(i) => return None<Int64>
        }
    }
    return Some<Int64>(0)
}
/**
 * Check if one of the sources of an edge connects to a given value
 * Returns the first occurrence if there are multiple
 * @param edge The edge
 * @return Whether the edge has the value as one of its arguments
 */
func HasSpecificValueArgument(edge : Edge, v : Value){
    for(i in 0..edge.sources.size()){
        match(edge.sources[i].GetLeftPort()){
            case EdgePort(e, j) => if(e.HasValue(v)){ return Some<Int64>(i) }
            case InterfacePort(j) => {}
        }
    }
    return None<Int64>
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
 * Replace a gate with the value obtained by some calculation, and stub its inputs
 * One of the arguments is assumed to be a value that triggered this rewrite - it will be discarded rather than stubbed
 * @param edge The edge
 * @param hb   The hyp builder we are rewriting
 * @param v    The value to replace the gate with
 * @param trig The index of the argument that has triggered this rewrite
 */
func ReplaceGateWithValueAndStubs(edge : Edge, hb : HypBuilder, trig : Int64, v : Value){
    if(trig < 0 || trig >= edge.sources.size()){
        throw BadDomainException("ReplaceGateWithValueAndStubs", trig, edge.sources.size())
    }
    for(i in 0..edge.sources.size()){
        if(i != trig){
            let stubEdge = hb.CreateEdgeFromExisting(STUB, [edge.sources[i]])
        } else {
            hb.RemoveEdge(edge.sources[i].GetLeftEdge())
        }
    }
    let newEdge = hb.CreateEdge(VALUE(v))
    hb.AddConn(newEdge.targets[0], edge.targets[0].GetConn())
    hb.RemoveEdge(edge)
}
/**
 * Replace a gate with a passthrough for all but one of its inputs, which is discarded
 * One of the arguments is assumed to be a value that triggered this rewrite - it will be discarded rather than passed through
 * @param edge The edge
 * @param hb   The hyp builder we are rewriting
 * @param v    The value to replace the gate with
 * @param trig The index of the argument that has triggered this rewrite
 */
func ReplaceGateWithPassthrough(edge : Edge, hb : HypBuilder, trig : Int64){
    if(trig < 0 || trig >= edge.sources.size()){
        throw BadDomainException("ReplaceGateWithValueAndStubs", trig, edge.sources.size())
    }
    var j = 0
    for(i in 0..edge.sources.size()){
        if(i != trig){
            hb.AddConn(edge.sources[i].GetConn(), edge.targets[j].GetConn())
            j++
        } else {
            hb.RemoveEdge(edge.sources[i].GetLeftEdge())
        }
    }
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
    RewriteRule(name, tt.generator, HasValueArguments, {e : Edge, hb : HypBuilder, i : Int64 => EvaluateGate(e, hb, tt)})
}
/**
 * Create a rewrite rule for replacing a gate that has a given argument with a new value
 * The precondition for this rule is that at least one of the inputs must be a value
 * @param name The name of the rewrite rule
 * @param gen  The generator of the gate
 * @param arg  The argument value that triggers the rewrite rule
 * @param res  The argument to rewrite to
 */
func EnhancedGateRewriteRule(name : String, gen : Generator, arg : Value, res : Value){
    RewriteRule(name, gen, {e : Edge => HasSpecificValueArgument(e, arg)}, {e : Edge, hb : HypBuilder, i : Int64 => ReplaceGateWithValueAndStubs(e, hb, i, res)})
}
/**
 * Create a rewrite rule for replacing a gate that has a given argument with just the other arguments
 * The precondition for this rule is that at least one of the inputs must be a value
 * @param name The name of the rewrite rule
 * @param gen  The generator of the gate
 * @param arg  The argument value that triggers the rewrite rule
 */
func PassthroughGateRewriteRule(name : String, gen : Generator, arg : Value){
    RewriteRule(name, gen, {e : Edge => HasSpecificValueArgument(e, arg)}, {e : Edge, hb : HypBuilder, i : Int64 => ReplaceGateWithPassthrough(e, hb, i)})
}

/**
 * Gate evaluation rules 
 */
let joinEval = GateRewriteRule("join", joinTable)
let andEval = GateRewriteRule("AND eval", andTable)
let orEval = GateRewriteRule("OR eval", orTable)
let nandEval = GateRewriteRule("NAND eval", nandTable)
let norEval = GateRewriteRule("NOR eval", norTable)
let xorEval = GateRewriteRule("XOR eval", xorTable)
let xnorEval = GateRewriteRule("XNOR eval", andTable)

/**
 * Enhanced gate evaluation rules
 */

/* false AND x = false */
let andEnhanced = EnhancedGateRewriteRule("AND false", AND, FALSE, FALSE)
/* true AND x = true */
let orEnhanced = EnhancedGateRewriteRule("OR true", OR, TRUE, TRUE)

/**
 * Passthrough gate evaluation rules
 */

/* true AND x = x */
let andPassthrough = PassthroughGateRewriteRule("AND true", AND, TRUE)
/* false OR x = x */
let orPassthrough = PassthroughGateRewriteRule("OR false", OR, FALSE)
/* bottom JOIN x = x */
let joinUnit = PassthroughGateRewriteRule("join unit", JOIN, BOTTOM)

/** Fork rules */

/** FORK ; stub * id = id */
let forkStubLeft = RewriteRule(
    "Fork-stub left",
    FORK,
    {e : Edge => NextEdgeIs(e.targets[0], STUB) },
    {e : Edge, hb : HypBuilder, i : Int64 => 
        let t = e.sources[0].GetConn()
        hb.AddConn(t, e.targets[1].GetConn())
        hb.RemoveEdge(e.targets[0].GetRightEdge())
        hb.RemoveEdge(e)
    }
)
/** FORK ; id * stub = id */
let forkStubRight = RewriteRule(
    "Fork-stub right",
    FORK,
    {e : Edge => NextEdgeIs(e.targets[1], STUB) },
    {e : Edge, hb : HypBuilder, i : Int64 => 
        let t = e.sources[0].GetConn()
        hb.AddConn(t, e.targets[0].GetConn())
        hb.RemoveEdge(e.targets[1].GetRightEdge())
        hb.RemoveEdge(e)
    }
)
/** v ; FORK = v * v */
let forkCopy = RewriteRule(
    "Fork",
    FORK,
    HasValueArguments,
    {e : Edge, hb : HypBuilder, i : Int64 =>
        let arg = e.sources[0].GetLeftEdge()
        let copy = hb.CreateEdge(VALUE(arg.GetValue()))
        hb.AddConn(arg.targets[0], e.targets[0].GetConn())
        hb.AddConn(copy.targets[0], e.targets[1].GetConn())
        hb.RemoveEdge(e)
    }
)

/** FORK ; JOIN = id */
let forkJoin = RewriteRule(
    "Fork-join",
    JOIN,
    {e : Edge => 
        let s1 = e.sources[0]
        let s2 = e.sources[1] 
        let b = match(s1.GetLeftPort()){
            case EdgePort(e1, i) => {
                match(s2.GetLeftPort()){
                    case EdgePort(e2, j) => e1.id == e2.id
                    case _ => false
                }
            }
            case _ => false
        }    
        if(b){
            Some<Int64>(0)
        } else {
            None<Int64>
        }
    },
    {e : Edge, hb: HypBuilder, i : Int64 =>
        let fork = e.sources[0].GetLeftEdge()
        hb.AddConn(fork.sources[0].GetConn(), e.targets[0].GetConn())
        hb.RemoveEdge(e)
        hb.RemoveEdge(fork)
    }
)

let joinFork = RewriteRule(
    "Join-fork",
    FORK,
    {e : Edge => PreviousEdgeIs(e.sources[0], JOIN)},
    {e : Edge, hb : HypBuilder, i : Int64 => 
        let oldJoin = e.sources[0].GetLeftEdge()
        print("eee\n")
        let fork1 = hb.CreateEdgeFromExisting(FORK, [oldJoin.sources[0]])
        let fork2 = hb.CreateEdgeFromExisting(FORK, [oldJoin.sources[1]])
        let join1 = hb.CreateEdgeFromExisting(JOIN, [e.targets[0]])
        let join2 = hb.CreateEdgeFromExisting(JOIN, [e.targets[1]])
        print("hello\n")
        hb.AddConn(fork1.targets[0], join1.sources[0])
        hb.AddConn(fork1.targets[1], join2.sources[0])
        hb.AddConn(fork2.targets[0], join1.sources[1])
        hb.AddConn(fork2.targets[1], join2.sources[1])
        hb.RemoveEdge(e)
        hb.RemoveEdge(oldJoin)
    }
)

let rewriteRules = ArrayList<RewriteRule>([
    forkStubLeft,
    forkStubRight,
    joinUnit,
    forkCopy,
    forkJoin,
    joinFork,
    joinEval,
    andEval,
    orEval,
    nandEval,
    norEval,
    xorEval,
    xnorEval,
    andEnhanced,
    orEnhanced,
    andPassthrough,
    orPassthrough
])
let rewriter = Rewriter(rewriteRules)