/**
 * rules.cj
 *
 * This file contains rewrite rules that make up the first part of the operational semantics
 */

package circuits

/* Common preconditions */
func GeneratorAndCondition(e : Edge, gen : Generator, cond : Option<Int64>){
    if(e.HasGenerator(gen)){
        cond
    } else {
        None<Int64>
    }
}

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
func AllNextEdgesAre(e : Edge, gen : Generator){
    if(e.targets.size() == 0){
        return None<Int64>
    }
    for(t in e.targets){
        match(NextEdgeIs(t, gen)){
            case Some(i) => {}
            case $None   => return None<Int64>
        }
    }
    return Some<Int64>(0)
}
func AllPreviousEdgesAre(e : Edge, gen : Generator){
    if(e.sources.size() == 0){
        return None<Int64>
    }
    for(s in e.sources){
        match(PreviousEdgeIs(s, gen)){
            case Some(i) => {}
            case $None   => return None<Int64>
        }
    }
    return Some<Int64>(0)
}
func ConsistentDelays(ss : ArrayList<Source>){
    if(ss.size() != 0){
        let n : Int64
        match(ss[0].GetLeftPort()){
            case EdgePort(e, i) =>
                if(e.IsDelay()){
                    n = e.GetDelay()
                } else {
                    return None<Int64>
                }
            case InterfacePort(i) => return None<Int64>
        }
        for(i in 1..ss.size()){
            match(ss[i].GetLeftPort()){
                case EdgePort(e, j) =>
                    if(!(e.IsDelay() && n == e.GetDelay())){
                        return None<Int64>
                    }
                case InterfacePort(j) => return None<Int64>
            }
        }
        Some<Int64>(n)
    } else {
        None<Int64>
    }
}
func AllInputsAreConsistentWaveforms(e : Edge){
    if(e.sources.size() == 0) {
        return None<Int64>
    }
    let n = match(IsWaveformArg(e.GetSource(0))){
        case Some(w) => w.delay.GetDelay()
        case $None   => return None<Int64>
    }
    for(i in 1..e.sources.size()){
        match(IsWaveformArg(e.sources[i])){
            case Some(w) =>
                if(w.delay.GetDelay() != n){
                    return None<Int64>
                }
            case $None => return None<Int64>
        }
    }
    return Some<Int64>(n)
}

func InputsOutOfPhase(e : Edge){
    if(e.sources.size() == 0){
        return None<Int64>
    }
    var nonValue = false
    for(s in e.sources){
        match(IsWaveformArg(s)){
            case Some(w) =>
                if(w.delay.GetDelay() != 1){
                    return None<Int64>
                }
                nonValue = true
            case $None =>
                match(s.GetLeftPort()){
                    case EdgePort(ep, i) =>
                        if(ep.IsDelay()){
                            if(ep.GetDelay() != 1){
                                return None<Int64>
                            }
                            nonValue = true
                        } else if (!ep.IsValue()){
                            return None<Int64>
                        }
                    case InterfacePort(i) => return None<Int64>
                }
        }
    }
    // No need to stream if it has all values
    if(!nonValue){
        None<Int64>
    } else {
        Some<Int64>(0)
    }
}

/**
 * Check if the sources of an edge all connect to value edges
 * This allows us to reduce gates
 * @param edge The edge
 * @return Some(0) if all the arguments are values, None otherwise)
 */
func HasValueArguments(edge : Edge){
    if(edge.sources.size() == 0){
        return None<Int64>
    }
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
func HaslinkificValueArgument(edge : Edge, v : Value){
    for(i in 0..edge.sources.size()){
        match(edge.sources[i].GetLeftPort()){
            case EdgePort(e, j) => 
                if(e.HasValue(v)){ 
                    
                    return Some<Int64>(i) }
            case InterfacePort(j) => ()
        }
    }
    return None<Int64>
}
func NthArgumentIsValue(edge : Edge, i : Int64){
    if(i < 0 || i >= edge.sources.size()){
        throw BadDomainException("NthArgumentIsValue", i, edge.sources.size())
    }
    let s = edge.sources[i]
    match(s.GetLeftPort()){
        case EdgePort(e, j) =>
            if(e.IsValue()){
                Some<Int64>(i)
            } else {
                None<Int64>
            }
        case InterfacePort(j) => None<Int64>
    }
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
    hb.AddConn(newEdge.GetTarget(0), edge.GetTarget(0).GetConn())
    hb.RemoveEdge(edge)
    ArrayList<Source>([newEdge.GetTarget(0).GetConn()])
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
    let nexts = ArrayList<Source>()
    for(i in 0..edge.sources.size()){
        if(i != trig){
            let stubEdge = hb.CreateEdge(STUB)
            hb.AddConn(edge.sources[i].GetConn(), stubEdge.GetSource(0))
            nexts.add(stubEdge.GetSource(0))
        } else {
            hb.RemoveEdge(edge.sources[i].GetLeftEdge())
        }
    }
    let newEdge = hb.CreateEdge(VALUE(v))
    hb.AddConn(newEdge.GetTarget(0), edge.GetTarget(0).GetConn())
    hb.RemoveEdge(edge)
    nexts.add(newEdge.GetTarget(0).GetConn())
    nexts
}
/**
 * Replace a gate with a passthrough for all but one of its inputs, which is discarded
 * One of the arguments is assumed to be a value that triggered this rewrite - it will be discarded rather than passed through
 * @param edge The edge
 * @param hb   The hyp builder we are rewriting
 * @param v    The value to replace the gate with
 * @param trig The index of the argument that has triggered this rewrite
 */
func ReplaceGateWithPassthrough(edge : Edge, hb : HypBuilder, trig : Int64) : ArrayList<Source> {
    if(trig < 0 || trig >= edge.sources.size()){
        throw BadDomainException("ReplaceGateWithValueAndStubs", trig, edge.sources.size())
    }
    var j = 0
    let nexts = ArrayList<Source>()
    for(i in 0..edge.sources.size()){
        if(i != trig){
            let nextSource = edge.targets[j].GetConn()
            hb.AddConn(edge.sources[i].GetConn(), nextSource)
            nexts.add(nextSource)
            j++
        } else {
            hb.RemoveEdge(edge.sources[i].GetLeftEdge())
        }
    }
    hb.RemoveEdge(edge)
    nexts
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
    RewriteRule(name, EXACTLY(tt.generator), HasValueArguments, {e : Edge, hb : HypBuilder, payload : Int64 => EvaluateGate(e, hb, tt)})
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
    EnhancedGateRewriteRule(name, EXACTLY(gen), arg, res)
}   
/**
 * Create a rewrite rule for replacing an entry point that has a given argument with a new value
 * The precondition for this rule is that at least one of the inputs must be a value
 * @param name The name of the rewrite rule
 * @param gen  The entry point 
 * @param arg  The argument value that triggers the rewrite rule
 * @param res  The argument to rewrite to
 */
func EnhancedGateRewriteRule(name : String, entryPoint : EntryPoint, arg : Value, res : Value){
    RewriteRule(name, entryPoint, {e : Edge => HaslinkificValueArgument(e, arg)}, {e : Edge, hb : HypBuilder, payload : Int64 => ReplaceGateWithValueAndStubs(e, hb, payload, res)})
}

/**
 * Create a rewrite rule for replacing a gate that has a given argument with just the other arguments
 * The precondition for this rule is that at least one of the inputs must be a value
 * @param name The name of the rewrite rule
 * @param gen  The generator of the gate
 * @param arg  The argument value that triggers the rewrite rule
 */
func PassthroughGateRewriteRule(name : String, gen : Generator, arg : Value){
    RewriteRule(name, EXACTLY(gen), {e : Edge => HaslinkificValueArgument(e, arg)}, {e : Edge, hb : HypBuilder, payload : Int64 => ReplaceGateWithPassthrough(e, hb, payload)})
}

/**
 * Gate evaluation rules 
 */
let joinEval = GateRewriteRule("join", joinTable)
let notEval = GateRewriteRule("NOT eval", notTable)
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
/* If an argument is bottom, the whole gate evaluates to bottom */
let bottomElimination = EnhancedGateRewriteRule("Bottom elimination", GATE, BOTTOM, BOTTOM)

/**
 * Passthrough gate evaluation rules
 */

/* true AND x = x */
let andPassthrough = PassthroughGateRewriteRule("AND true", AND, TRUE)
/* false OR x = x */
let orPassthrough = PassthroughGateRewriteRule("OR false", OR, FALSE)
/* bottom JOIN x = x */
let joinUnit = PassthroughGateRewriteRule("join unit", JOIN, BOTTOM)

/* The indices of the multiplexer inputs */
let muxTrue = 2
let muxFalse = 1
let muxControl = 0
/* Evaluate a multiplexer */
let muxEval = RewriteRule(
    "Mux eval",
    EXACTLY(MUX),
    {e : Edge => NthArgumentIsValue(e, muxControl)},
    {e : Edge, hb : HypBuilder, payload : Int64 =>
        let control = e.GetSource(muxControl).GetLeftEdge()
        let (acc, rej) = match(control.GetValue()){
            case $TRUE => (muxTrue, muxFalse)
            case $FALSE => (muxFalse, muxTrue)
            case _ => (-1,-1)
        }
        // Stub off the discarded input
        let stub = hb.CreateEdge(STUB)
        let stubSource = stub.GetSource(0)
        let outputSource = e.GetTarget(0).GetConn()

        let nextSources = ArrayList<Source>()

        let (trueSource, falseSource) = 
            if(acc != -1){
                if(acc == muxTrue) {
                    (outputSource, stubSource)
                } else {
                    (stubSource, outputSource)
                }
            } else {
                // We need to stub both inputs in this case
                let stub2 = hb.CreateEdge(STUB)
                let stubSource2 = stub.GetSource(0)
                // Cap off the output of the mux
                let bot = hb.CreateEdge(VALUE(BOTTOM))
                hb.AddConn(bot.GetTarget(0), outputSource)
                nextSources.add(outputSource)
                (stubSource, stubSource2)
            }
        // Connect the original inputs appropriately
        hb.AddConn(e.GetSource(muxTrue).GetConn(), trueSource)
        hb.AddConn(e.GetSource(muxFalse).GetConn(), falseSource)
        // Remove the multiplexer edge
        hb.RemoveEdge(e)
        hb.RemoveEdge(control)
        nextSources.addAll([trueSource, falseSource])
        nextSources
    }
)

/** Fork rules */

/** FORK ; stub * id = id */
let forkStubLeft = RewriteRule(
    "Fork-stub left",
    EXACTLY(FORK),
    {e : Edge => NextEdgeIs(e.GetTarget(0), STUB) },
    {e : Edge, hb : HypBuilder, payload : Int64 => 
        let t = e.GetSource(0).GetConn()
        let next = e.GetTarget(1).GetConn()
        hb.AddConn(t, next)
        hb.RemoveEdge(e.GetTarget(0).GetRightEdge())
        hb.RemoveEdge(e)
        ArrayList<Source>([next])
    }
)
/** FORK ; id * stub = id */
let forkStubRight = RewriteRule(
    "Fork-stub right",
    EXACTLY(FORK),
    {e : Edge => NextEdgeIs(e.GetTarget(1), STUB) },
    {e : Edge, hb : HypBuilder, payload : Int64 => 
        let t = e.GetSource(0).GetConn()
        let next = e.GetTarget(0).GetConn()
        hb.AddConn(t, next)
        hb.RemoveEdge(e.GetTarget(1).GetRightEdge())
        hb.RemoveEdge(e)
        ArrayList<Source>([next])
    }
)
/** v ; FORK = v * v */
let forkCopy = RewriteRule(
    "Fork",
    EXACTLY(FORK),
    HasValueArguments,
    {e : Edge, hb : HypBuilder, payload : Int64 =>
        let arg = e.GetSource(0).GetLeftEdge()
        let copy = hb.CreateEdge(VALUE(arg.GetValue()))
        let leftCopy = e.GetTarget(0).GetConn()
        let rightCopy = e.GetTarget(1).GetConn()
        hb.AddConn(arg.GetTarget(0), leftCopy)
        hb.AddConn(copy.GetTarget(0), rightCopy)
        hb.RemoveEdge(e)
        ArrayList<Source>([leftCopy, rightCopy])
    }
)

/** FORK ; JOIN = id */
let forkJoin = RewriteRule(
    "Fork-join",
    EXACTLY(JOIN),
    {e : Edge => 
        let s1 = e.GetSource(0)
        let s2 = e.GetSource(1) 
        let b = match(s1.GetLeftPort()){
            case EdgePort(e1, i) =>
                match(s2.GetLeftPort()){
                    case EdgePort(e2, j) => e1.id == e2.id
                    case _ => false
                }
            case _ => false
        }    
        if(b){
            Some<Int64>(0)
        } else {
            None<Int64>
        }
    },
    {e : Edge, hb: HypBuilder, payload : Int64 =>
        let fork = e.GetSource(0).GetLeftEdge()
        let nextSource = e.GetTarget(0).GetConn()
        hb.AddConn(fork.GetSource(0).GetConn(), nextSource)
        hb.RemoveEdge(e)
        hb.RemoveEdge(fork)
        ArrayList<Source>([nextSource])
    }
)

let joinFork = RewriteRule(
    "Join-fork",
    EXACTLY(FORK),
    {e : Edge => PreviousEdgeIs(e.GetSource(0), JOIN)},
    {e : Edge, hb : HypBuilder, payload : Int64 => 
        let oldJoin = e.GetSource(0).GetLeftEdge()
        let fork1 = hb.CreateEdge(FORK)
        hb.AddConn(oldJoin.GetSource(0).GetConn(), fork1.GetSource(0))
        let fork2 = hb.CreateEdge(FORK)
        hb.AddConn(oldJoin.GetSource(1).GetConn(), fork2.GetSource(0))
        let join1 = hb.CreateEdge(JOIN)
        hb.AddConn(join1.GetTarget(0), e.GetTarget(0).GetConn())
        let join2 = hb.CreateEdge(JOIN)
        hb.AddConn(join2.GetTarget(0), e.GetTarget(1).GetConn())
        hb.AddConn(fork1.GetTarget(0), join1.GetSource(0))
        hb.AddConn(fork1.GetTarget(1), join2.GetSource(0))
        hb.AddConn(fork2.GetTarget(0), join1.GetSource(1))
        hb.AddConn(fork2.GetTarget(1), join2.GetSource(1))
        hb.RemoveEdge(e)
        hb.RemoveEdge(oldJoin)
        ArrayList<Source>([join1.GetTarget(0).GetConn(), join2.GetTarget(0).GetConn()])
    }
)

let timelessness = RewriteRule(
    "Timelessness",
    ANY,
    {e : Edge => ConsistentDelays(e.sources)},
    {e : Edge, hb : HypBuilder, payload : Int64 => 
        let nextSources = ArrayList<Source>()
        for(s in e.sources){
            let del = s.GetLeftEdge()
            hb.AddConn(del.GetSource(0).GetConn(), s)
            hb.RemoveEdge(del)
        }
        for(t in e.targets){
            let newDelay = hb.CreateEdge(DELAY(payload))
            hb.AddConn(newDelay.GetTarget(0), t.GetConn())
            hb.AddConn(t, newDelay.GetSource(0))
            nextSources.add(newDelay.GetSource(0))
        }
        nextSources
    }
)

let propagateStubs = RewriteRule(
    "Stub",
    ANY,
    {e : Edge => AllNextEdgesAre(e, STUB)},
    {e : Edge, hb : HypBuilder, payload : Int64 => 
        let nextSources = ArrayList<Source>()
        for(t in e.targets){
            hb.RemoveEdge(t.GetRightEdge())
        }
        for(s in e.sources){
            let stub = hb.CreateEdge(STUB)
            hb.AddConn(s.GetConn(), stub.GetSource(0))
            nextSources.add(stub.GetSource(0))
        }
        hb.RemoveEdge(e)
        nextSources
    }
)

func PerformStreaming(hb : HypBuilder, e : Edge){
        let nowGate = hb.CreateEdge(e.generator)
        let thenGate = hb.CreateEdge(e.generator)
        for(i in 0..e.sources.size()){
            let s = e.sources[i]
            let join = s.GetLeftEdge()
            let lhsArg = join.GetSource(0).GetLeftEdge()
            let rhsArg = join.GetSource(1).GetLeftEdge()
            let (value, delay) = if(lhsArg.IsValue()){
                (lhsArg, rhsArg)
            } else {
                (rhsArg, lhsArg)
            }
            hb.AddConn(value.GetTarget(0), nowGate.sources[i])
            hb.AddConn(delay.GetSource(0).GetConn(), thenGate.sources[i])
            hb.RemoveEdge(delay)
            hb.RemoveEdge(join)
        } 
        let newDelay = hb.CreateEdge(DELAY(1))
        hb.AddConn(thenGate.GetTarget(0), newDelay.GetSource(0))
        
        let newJoin = hb.CreateEdge(JOIN)
        hb.AddConn(nowGate.GetTarget(0), newJoin.GetSource(0))
        hb.AddConn(newDelay.GetTarget(0), newJoin.GetSource(1))

        let exitSource = e.GetTarget(0).GetConn()
        hb.AddConn(newJoin.GetTarget(0), exitSource)

        hb.RemoveEdge(e)
        ArrayList<Source>([exitSource])
}

let streaming = RewriteRule(
    "Streaming",
    GATE,
    AllInputsAreConsistentWaveforms,
    {e : Edge, hb : HypBuilder, payload : Int64 =>
        PerformStreaming(hb, e)
    }
)

let streamingEnhanced = RewriteRule(
    "Streaming enhanced",
    GATE,
    InputsOutOfPhase,
    {e : Edge, hb : HypBuilder, payload : Int64 =>
        for(s in e.sources){
            match(IsWaveformArg(s)){
                case Some(w) => ()
                case $None =>
                    let bot = hb.CreateEdge(VALUE(BOTTOM))
                    let join = hb.CreateEdge(JOIN)
                    if(s.GetLeftEdge().IsValue()){
                        let delay = hb.CreateEdge(DELAY(1))
                        hb.AddConn(bot.GetTarget(0), delay.GetSource(0))
                        hb.AddConn(delay.GetTarget(0), join.GetSource(1))
                        hb.AddConn(s.GetConn(), join.GetSource(0))
                    } else {
                        hb.AddConn(bot.GetTarget(0), join.GetSource(0))
                        hb.AddConn(s.GetConn(), join.GetSource(1))
                    }
                    hb.AddConn(join.GetTarget(0), s)
            }
        }
        PerformStreaming(hb, e)
    }
)

let disconnect = EnhancedGateRewriteRule("Disconnect", DELAY, BOTTOM, BOTTOM)

let rewriteRules = ArrayList<RewriteRule>([
    propagateStubs,
    bottomElimination,
    forkStubLeft,
    forkStubRight,
    joinUnit,
    forkCopy,
    forkJoin,
    joinFork,
    joinEval,
    notEval,
    andEval,
    orEval,
    nandEval,
    norEval,
    xorEval,
    xnorEval,
    muxEval,
    andEnhanced,
    orEnhanced,
    andPassthrough,
    orPassthrough,
    disconnect,
    timelessness,
    streaming,
    streamingEnhanced
])