/**
 * rewrite/rules/apply.cj
 *
 * Functions for dealing with the apply rule.
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite.rules
func GetArgEdges<V, G>(
    e : Edge<V, G>
) : Array<Option<Edge<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    map({
        v : Vertex<V, G> =>
            if(v.GetOutEdges().size == 1) {
                match(v.GetInEdge()) {
                    case None => None<Edge<V, G>>
                    case Some(ec) =>
                        let edge = ec.GetEdge()
                        if(edge.GetLabel().IsArgument()) {
                            Some(edge)
                        } else {
                            None<Edge<V, G>>
                        }
                }
            } else {
                None<Edge<V, G>>
            }
    }, e.GetSources())
}
/**
 * Assuming that the apply preconditions above are met, get the argument edges
 * of a given edge and the values stored within these edges.
 *
 * @param e The edge
 * @return An array of options of the argument edges and an array of options of
 *          the argument values: elements will be None if there is no signal as
 *          an argument or if there is a argument shared between edges (it must
 *          be forked first).
 */
func GetArgs<V, G>(
    e : Edge<V, G>
) : (Array<Option<Edge<V, G>>>, Array<Option<CycleInput<V>>>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let argumentEdges = GetArgEdges(e)
    let argumentValues = map({
            arg : Option<Edge<V, G>> =>
                match(arg) {
                    case None => None<CycleInput<V>>
                    case Some(e) => Some(e.GetLabel().GetCycleInput())
                }
        }, argumentEdges
    )
    (argumentEdges, argumentValues)
}
func GetWaveformArgs<V, G>(
    argumentEdges : Array<Option<Edge<V, G>>>
) : Array<Option<Waveform<V>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    map({
        arg : Option<Edge<V, G>> =>
            match(arg) {
                case None => None<Waveform<V>>
                case Some(e) => Some(e.GetLabel().GetWaveform())
            }
        }, argumentEdges
    )
}
/**
 * Given an array of signals and an apply function, get the output signals
 *
 * @param signals
 * @param applyFn
 * @return The output cycle inputs
 */
func DefiniteApply<V>(
    signals : Array<Signal<V>>,
    applyFn : (Array<Signal<V>>) -> Array<Signal<V>>
) : Array<CycleInput<V>>
    where V <: ValueSymbol<V>
{
    let outputSignals = applyFn(signals)
    map({ s : Signal<V> => DEFINITE(s) }, outputSignals)
}
/**
 * Given a port number, a bit number, and a map from an assignment to signals,
 * get the variable value for this port and bit.
 *
 * @param dependentVariables
 * @param variableApplyFn
 * @param portNo
 * @param bit
 */
func GetVariableValueForPortBit<V>(
    dependentVariables : HashMap<Int64, Variable<V>>,
    variableApplyFn : (HashMap<Int64, Signal<V>>) -> Array<Signal<V>>,
    portNo: Int64, bit : Int64
) : VariableValue<V> where V <: ValueSymbol<V> {
    VariableValue<V>(
        dependentVariables,
        { assg : HashMap<Int64, Signal<V>> =>
            variableApplyFn(assg)[portNo].GetBit(bit)
        }
    )
}
/**
 * Given a variable signal, check to see if it induces exactly one
 * signal; if it does, create a definite cycle input; otherwise create a
 * variable one.
 *
 * @param signal
 * @return Appropriate cycle input
 */
func AssignDefiniteOrVariable<V>(
    signal : VariableSignal<V>
) : CycleInput<V> where V <: ValueSymbol<V> {
    let potentialSignals = signal.GetPotentialSignals()
    if(potentialSignals.size == 1){
        DEFINITE(potentialSignals.iterator().next().getOrThrow())
    } else {
        CycleInput<V>.PARTIAL(signal)
    }
}
/**
 * For a port, get the cycle input it will output based on some dependent
 * variables and an apply function.
 *
 * @param port
 * @param portNo
 * @param dependentVariables
 * @param variableApplyFn
 * @return
 */
func GetCycleInputForPort<V>(
    port : Port, portNo : Int64,
    dependentVariables : HashMap<Int64, Variable<V>>,
    variableApplyFn : (HashMap<Int64, Signal<V>>) -> Array<Signal<V>>
) : CycleInput<V> where V <: ValueSymbol<V> {
    let signal = VariableSignal(
        Array<VariableValue<V>>(port.GetWidth(), {
            bit : Int64 =>
            GetVariableValueForPortBit(
                dependentVariables, variableApplyFn, portNo, bit
            )
        })
    )
    AssignDefiniteOrVariable(signal)
}

/**
 * Given an array of cycle inputs, their dependent variables, and an apply
 * function, get the possible output signals
 *
 * @param partialInputs
 * @param dependentVariables
 * @param applyFn
 * @param outputPorts
 * @return The output cycle inputs
 */
public func VariableApply<V>(
    partialInputs : Array<CycleInput<V>>,
    dependentVariables : HashMap<Int64, Variable<V>>,
    applyFn : (Array<Signal<V>>) -> Array<Signal<V>>,
    outputPorts : Array<Port>
) : Array<CycleInput<V>>
    where V <: ValueSymbol<V>
{
    let dependentVariableArray = dependentVariables.toArray()
    // Get the function from an assignment of the dependent variables to
    // the output signals created for this assignment
    let variableApplyFn = {
        assignment : HashMap<Int64, Signal<V>> =>
            applyFn(
                map({ partialInput : CycleInput<V> =>
                    GetSignalForAssignment(assignment, partialInput)
                }, partialInputs)
            )
    }
    mapi(
        { p : Port, portNo : Int64 => GetCycleInputForPort(
            p, portNo, dependentVariables, variableApplyFn
        )}, outputPorts
    )
}
/**
 * Given an array of cycle inputs and an apply function, get all the potential
 * cycle inputs that could be produced by the function.
 *
 * @param partialInputs
 * @param applyFn
 * @param outputPorts
 * @return The array of possible outputs for each output port
 */
public func GetPotentialOutputs<V>(
    partialInputs : Array<CycleInput<V>>,
    applyFn : (Array<Signal<V>>) -> Array<Signal<V>>,
    outputPorts : Array<Port>
) : Array<CycleInput<V>> where V <: ValueSymbol<V> {
    let dependentVariables = HashMap<Int64, Variable<V>>()
    for(input in partialInputs){
        match(input){
            case DEFINITE(_) => ()
            case PARTIAL(s) =>
                dependentVariables.putAll(s.GetDependentVariables())
        }
    }
    // If there are no dependent variables, this signal is fixed
    if(dependentVariables.size == 0) {
        DefiniteApply(map(GetDefinite<V>, partialInputs), applyFn)
    } else {
        VariableApply(partialInputs, dependentVariables, applyFn, outputPorts)
    }
}
func GetValueOutputEdge<V, G>(
    f : InterfacedHypergraph<V, G>, outputs : Array<CycleInput<V>>
) : Array<(Label<V, G>, Option<InterfacedHypergraph<V, G>>)>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
// Create a new value or signal edge for each of the output values
    map({
        output : CycleInput<V> =>
            match(output) {
                case DEFINITE(signal) =>
                    if(signal.GetWidth() == 1) {(
                        Label<V, G>.VALUE(signal.GetBit(0)),
                        None<InterfacedHypergraph<V, G>>
                    )} else {(
                        Label<V, G>.SIGNAL(signal),
                        Some(MakeSignal<V, G>(signal))
                    )}
                case PARTIAL(pi) =>
                    (Label<V, G>.PARTIAL(pi), None<InterfacedHypergraph<V, G>>)
        }
    }, outputs)
}
/**
 * Replace this edge and its arguments with some output cycle input edges.
 *
 * @param f
 * @param e
 * @param args
 * @param outputs
 */
func ReplaceGateWithOutputs<V, G>(
    f : InterfacedHypergraph<V, G>, e : Edge<V, G>,
    args : Array<Option<Edge<V, G>>>,
    outputs : Array<(Label<V, G>, Option<InterfacedHypergraph<V, G>>)>
) : HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let nextEdges = HashSet<TraversalElement<V, G>>()
    // Each argument edge must be discarded
    for(arg in args) {
        let actualArg = arg.getOrThrow()
        RemoveEdge(actualArg, f)
    }
    // Remove the gate edge
    RemoveEdge(e, f)
    // Each source of the gate edge must be discarded
    for(v in e.GetSources()) {
        RemoveVertex(v, f)
    }
    forEach<(Label<V, G>, Option<InterfacedHypergraph<V, G>>)>(
        { lf, i : Int64 =>
            let (label, subgraph) = lf
            let target = e.GetTarget(i)
            let newEdge = Edge(
                label, Array<Vertex<V, G>>(), [target],
                subgraph, Some(f.GetGraph())
            )
            nextEdges.put(EDGE(newEdge))
        }, outputs
    )
    nextEdges
}
func gcd(a : Int64, b : Int64) : Int64 {
    if(a == 0) {
        b
    } else if (b == 0) {
        a
    } else {
        let quotient = a / b
        let remainder = a % b
        gcd(quotient, remainder)
    }
}
func lcm(a : Int64, b : Int64) : Int64 {
    (a * b) / gcd(a, b)
}
func GetJointWaveform<V>(ws : Array<Waveform<V>>) : Array<Array<CycleInput<V>>>
    where V <: ValueSymbol<V>
{
    let wsLcm = fold_left({ acc, cur => lcm(acc, cur.GetLength())}, ws[0].GetLength(), ws)
    Array<Array<CycleInput<V>>>(wsLcm, {i =>
        map({ w : Waveform<V> => w.GetSignalAtTick(i, true)}, ws)
    })
}
/**
 * Execute the apply rule for a given apply function and edge.
 * The apply rule takes the arguments of a primitive and, if they are all
 * (potentially variable) signals, replaces the edge with the (potentially
 * variable) output of the apply function.
 *
 * @param applyFn
 * @param e
 * @param f
 */
func ExecuteApplyValueRule<V, G>(
    applyFn : (Array<Signal<V>>) -> Array<Signal<V>>,
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>,
    argumentEdges : Array<Option<Edge<V, G>>>
) : Option<HashSet<TraversalElement<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // If one of the edges or signals is None, this will abort rule application
    try {
        let partialInputs = map(
            { oe : Option<Edge<V, G>> =>
                oe.getOrThrow().GetLabel().GetCycleInput()
            }, argumentEdges
        )
        let potentialOutputs = GetPotentialOutputs(
            partialInputs, applyFn, e.GetOutputPorts()
        )
        let outputEdgeDetails = GetValueOutputEdge(f, potentialOutputs)
        let nextEdges = ReplaceGateWithOutputs<V, G>(
            f, e, argumentEdges, outputEdgeDetails
        )
        Some(nextEdges)
    } catch (e : NoneValueException) {
        None
    }
}
func ExecuteApplyInfiniteWaveformRule<V, G>(
    applyFn: (Array<Signal<V>>) -> Array<Signal<V>>,
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>,
    argumentEdges : Array<Option<Edge<V, G>>>
) : Option<HashSet<TraversalElement<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let argumentWaveforms = GetWaveformArgs(argumentEdges)
    try {
        let inputsPerTick = GetJointWaveform(map({ wopt => wopt.getOrThrow() }, argumentWaveforms))
        let outputs = map(
            { inputs : Array<CycleInput<V>> => GetPotentialOutputs(inputs, applyFn, e.GetOutputPorts()) },
            inputsPerTick
        )
        let potentialWaveforms = map({ output => Waveform(output) }, outputs)
        let edgeDetails = map(
            { wave : Waveform<V> =>
                (Label<V, G>.INFINITE_WAVEFORM(wave), Some(MakeInfiniteWaveform<V, G>(waveform: wave)))
            }, potentialWaveforms
        )
        let nextEdges = ReplaceGateWithOutputs<V, G>(
            f, e, argumentEdges, edgeDetails
        )
        nextEdges
    } catch (e : NoneValueException) {
        None
    }
}
func ArgumentsAreAllCycleInputs<V, G>(args : Array<Option<Edge<V, G>>>) : Bool
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    fold_left({ acc, cur => acc && match(cur) {
        case None => false
        case Some(e) => e.GetLabel().IsCycleInput()
    }}, true, args)
}
func ArgumentsAreAllInfiniteWaveforms<V, G>(args : Array<Option<Edge<V, G>>>) : Bool
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    fold_left({ acc, cur =>
        acc && match(cur) {
            case None => false
            case Some(e) => e.GetLabel().IsInfiniteWaveform()
    }}, true, args)
}
func ExecuteApplyRule<V, G>(
    applyFn: (Array<Signal<V>>) -> Array<Signal<V>>,
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>
) : Option<HashSet<TraversalElement<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let argumentEdges = GetArgEdges(e)
    if(ArgumentsAreAllCycleInputs(argumentEdges)) {
        ExecuteApplyValueRule(applyFn, e, f, argumentEdges)
    } else if (ArgumentsAreAllInfiniteWaveforms(argumentEdges)) {
        ExecuteApplyInfiniteWaveformRule(applyFn, e, f, argumentEdges)
    } else {
        None
    }
}
/**
 * Get the rewrite rule for joining two values or signals together, using the
 * join operation in the signature lattice.
 *
 * @param signature
 * @return The join rewrite rule
 */
public func GetJoinRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "join",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                ExecuteApplyRule<V, G>(
                    { vss : Array<Signal<V>> =>
                            [signature.Join(vss[0], vss[1])]
                    }, e, f
                )
        }
    )
}
/**
 * Get the rewrite rule for applying a gate to some arguments, using the
 * corresponding function in a signature.
 *
 * @param signature
 * @return The apply rewrite rule
 */
public func GetPrimitiveRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "primitive",
        PRIMITIVE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let prim = e.GetLabel().GetPrimitive()
                let function = signature.GetGate(prim)
                ExecuteApplyRule<V, G>(function , e, f)
        }
    )
}
/**
 * Get the bottom rule, i.e. any edge applied to all bottoms is just buttoms.
 *
 * @param signature
 * @return The bottom rule
 */
public func GetBottomRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "bottom",
        ANY,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            if(!ArgumentsAreAllUnsharedValue(signature.GetBottom(), e)){
                None
            } else {
                let (argumentEdges, argumentValues) = GetArgs(e)
                // Get appropriate width bottoms for each target of the edge
                let bottoms = Array<CycleInput<V>>(e.GetCoarity()){
                    i : Int64 =>
                        DEFINITE(Signal(signature.GetBottom(), e.GetTarget(i).GetWidth()))
                }
                let edgeDetails = GetValueOutputEdge(f, bottoms)
                ReplaceGateWithOutputs<V, G>(
                    f, e, argumentEdges, edgeDetails
                )
            }
        }
    )
}