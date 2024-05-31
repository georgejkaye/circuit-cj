/**
 * rewrite/rules/shortcut.cj
 *
 * Functions for 'shortcut' rules: rules that can be triggered if a certain
 * input to an edge holds a property.
 */
package rewrite.rules
/**
 * Check if a specific argument to an edge is a signal in which all the elements
 * are a specific value.
 *
 * @param v The value to check for
 * @param e The edge
 * @param i The index of the source to check the argument of
 * @return Whether the specific argument is all this value
 */
func ArgumentIsAllUnsharedValue<V, G>(v : V, e : Edge<V, G>, i : Int64) : Bool
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let sourceVertex = e.GetSource(i)
    if(sourceVertex.GetOutEdges().size > 1) {
        false
    } else {
        match(sourceVertex.GetInEdge()){
            case None => false
            case Some(e) => e.GetEdge().GetLabel().IsAllValue(v)
        }
    }
}
/**
 * Check if all the arguments to an edge are signals in which all the elements
 * are a specific value.
 *
 * @param v The value to check for
 * @param e The edge
 * @return Whether all arguments are this value
 */
func ArgumentsAreAllUnsharedValue<V, G>(v : V, e : Edge<V, G>) : Bool
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Need to explicitly check for the zero case because otherwise it will
    // return true which is not desired
    if(e.GetArity() > 0) {
        for(i in 0..e.GetArity()) {
            if(!ArgumentIsAllUnsharedValue(v, e, i)) {
                return false
            }
        }
        true
    } else {
        false
    }
}
/**
 * Given an edge with two sources where one is a signal, remove this signal and
 * the gate and replace it with an identity on the other source
 *
 * @param e The edge
 * @param i The index of the argument to remove
 * @param f The interfaced graph we are rewriting in
 * @return Hash sets for next elements and removed elements
 */
func PerformPassthroughRewrite<V, G>(
    e : Edge<V, G>, i : Int64, f : InterfacedHypergraph<V, G>
) : HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // Get the argument edge to remove
    let arg = e.NextEdgeLeft(i).getOrThrow().GetEdge()
    // Compute the index of the gate that will become the passthrough identity
    let otherIndex = if (i == 0) { 1 } else { 0 }
    // Track the source and target we will merge to get the identity
    let source = e.GetSource(otherIndex)
    let target = e.GetTarget(i)
    // Remove the gate edge
    RemoveEdge(e, f)
    // Remove the argument edge
    RemoveEdge(arg, f)
    // Remove each target from this edge, as it is becoming an identity
    for(v in arg.GetTargets()) {
        RemoveVertex(v, f)
    }
    // Merge the dangling source and target
    source.MergeVertex(target)
    // We don't need to add anything to the frontier because
    HashSet<TraversalElement<V, G>>()
}
/**
 * Get the rewrite rule for unitality of the join, i.e. if a join has all
 * bottoms as one argument, then it can be replaced with an identity.
 *
 * @param signature
 * @param i The index of the join to be all bottoms
 * @param str The modifier to give the name of this rule
 * @return The join unit rule
 */
public func GetJoinUnitRule<V, G>(
    signature : Signature<V, G>,
    i : Int64,
    str : String
) : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
        RewriteRule<V, G>(
        "join-unit-${str}",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ArgumentIsAllUnsharedValue(signature.GetBottom(), e, i)){
                    None
                } else {
                    Some(PerformPassthroughRewrite(e, i, f))
                }
        }
    )
}
/**
 * Get the rewrite rule for left unitality of the join, i.e. if the left
 * argument of a join is all bottoms, then it can be replaced with an identity.
 *
 * @param signature
 * @return The join left unitality rule
 */
public func GetJoinUnitLeftRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    GetJoinUnitRule(signature, 0, "l")
}
/**
 * Get the rewrite rule for right unitality of the join, i.e. if the right
 * argument of a join is all bottoms, then it can be replaced with an identity.
 *
 * @param signature
 * @return The join right unitality rule
 */
public func GetJoinUnitRightRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    GetJoinUnitRule(signature, 1, "r")
}
func WaveformIsAllTrigger<V>(w : Waveform<V>, desired : Signal<V>) : Bool
    where V <: ValueSymbol<V>
{
    fold_left(
        { acc : Bool, ci : CycleInput<V> => acc && match(ci) {
            case DEFINITE(s) => s == desired
            case PARTIAL(s) =>
                if(s.GetPotentialSignals().size == 1) {
                    let iter = s.GetPotentialSignals().iterator()
                    iter.next().getOrThrow() == desired
                } else {
                    false
                }
            }
        }, true, w.GetSignals()
    )
}
/**
 * Check whether a given source of an edge connects to a signal edge with given
 * values that is not shared between multiple edges.
 *
 * @param e The edge
 * @param i The source index
 * @param desired The desired values in the signal
 * @return Some(signal edge, vertex) if conditions met, None otherwise
 */
func ArgumentIsUnsharedTrigger<V, G>(
    e : Edge<V, G>, i : Int64, desired : Signal<V>
) : Option<(Edge<V, G>, Vertex<V, G>, Bool)>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let vertex = e.GetSource(i)
    if(vertex.GetOutEdges().size == 1) {
        match(vertex.GetInEdge()) {
            case None => None
            case Some(ec) =>
                let edge = ec.GetEdge()
                let label = edge.GetLabel()
                if(label.IsInfiniteWaveform()) {
                    let wf = label.GetWaveform()
                    if(WaveformIsAllTrigger(wf, desired)) {
                        Some((edge, vertex, true))
                    } else {
                        None
                    }
                } else if(!label.IsSignal() ||
                    label.GetValueArray() != desired.GetValues()
                ) {
                    None
                } else {
                    Some((edge, vertex, false))
                }
        }
    } else {
        None
    }
}
/**
 * Given an annihilator and an edge that is being annihilated, remove it from
 * the out edges of the given vertex, and add the in edges of this vertex to
 * a traversal set.
 *
 * @param set
 * @param ann
 * @param e The edge being annihilated
 * @param v
 * @param i The index this vertex occupies in the sources of e
 */
func RemoveEdgeAndAddStubs<V, G>(
    set : HashSet<TraversalElement<V, G>>, ann : Annihilator<V, G>,
    f : InterfacedHypergraph<V, G>, e : Edge<V, G>, v : Vertex<V, G>, i : Int64
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    v.RemoveOutEdge(e)
    if(i != ann.index) {
        // We need to stub off this input to the annihilated edge
        match(v.GetInEdge()) {
            case None => ()
            case Some(ec) =>
                let _ = set.put(EDGE(ec.GetEdge()))
        }
    } else {
        // If this is the annihilating edge then it can all be discarded
        RemoveVertex(v, f)
    }
}
/**
 * Get an annihiliation rule, where a particular input to a gate forces its
 * output to be a particular signal regardless of the other inputs.
 *
 * @param ann The annihilator to make a rule for
 * @return The annihilation rewrite rule
 */
public func GetAnnihiliationRule<V, G>(
    ann : Annihilator<V, G>
) : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "annihilate-${ann.gate.GetName()}-${ann.index}-${ann.input}",
        PRIMITIVE,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // Check this is the right gate
            if(e.GetLabel().GetPrimitive() != ann.gate){
                None
            } else {
                // Check the value at the annihiliation index
                match(ArgumentIsUnsharedTrigger(e, ann.index, ann.input)) {
                    case None => None
                    case Some((signalEdge, vertex, isWaveform)) =>
                        let nextElements = HashSet<TraversalElement<V, G>>()
                        // Remove the annihilating edge
                        RemoveEdge(signalEdge, f)
                        // Remove the gate edge
                        RemoveEdge(e, f)
                        // Remove the connections from the other inputs
                        forEach(
                            { v : Vertex<V, G>, i : Int64 =>
                                RemoveEdgeAndAddStubs(
                                    nextElements, ann, f, e, v, i
                                )
                            }, e.GetSources()
                        )
                        // Create the annihilated outputs
                        let targets = e.GetTargets()
                        forEach<Signal<V>>({
                            s : Signal<V>, i : Int64 =>
                                let resultEdge = if(isWaveform) {
                                    let waveform = Waveform(s)
                                    let subgraph = MakeInfiniteWaveform<V, G>(
                                        waveform: waveform
                                    )
                                    Edge(
                                        Label<V, G>.INFINITE_WAVEFORM(waveform),
                                        Array<Vertex<V, G>>(), [targets[i]],
                                        subgraph, f.GetGraph()
                                    )
                                } else {
                                    MakeValueOrSignal(
                                    s, [targets[i]], f.GetGraph()
                                    )
                                }
                                nextElements.put(EDGE(resultEdge))
                        }, ann.output)
                        Some(nextElements)
                }
            }
        }
    )
}
/**
 * Given an edge, and identifier index and a current index, connect up the
 * indexth sources and target of the edge if they are not the identifier index.
 *
 * @param set
 * @param e
 * @param identifierIndex
 * @param currentIndex
 */
func ConnectIdentifiedWires<V, G>(
    set : HashSet<TraversalElement<V, G>>, e : Edge<V, G>,
    identifierIndex : Int64, currentIndex : Int64
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let actualIndex = if(currentIndex < identifierIndex) {
        currentIndex
    } else {
        currentIndex + 1
    }
    let source = e.GetSource(actualIndex)
    let target = e.GetTarget(currentIndex)
    source.MergeVertex(target)
    if(currentIndex != identifierIndex) {
        let nextElement = match(source.GetInEdge()) {
            case None => VERTEX(source)
            case Some(ec) => EDGE(ec.GetEdge())
        }
        set.put(nextElement)
    }
}
/**
 * Get an identitfier rule, where a particular input to a gate forces the gate
 * to act as the identity regardless of the value of the other inputs.
 *
 * @param ann The identifier to make a rule for
 * @return The identifier rewrite rule
 */
public func GetIdentifierRule<V, G>(
    ide : Identifier<V, G>
) : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "identifier-${ide.gate.GetName()}-${ide.index}-${ide.input}",
        PRIMITIVE,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // Check this is the right gate
            if(e.GetLabel().GetPrimitive() != ide.gate){
                None
            } else {
                let index = ide.index
                match(ArgumentIsUnsharedTrigger(e, index, ide.input)) {
                    case None => None
                    case Some((signalEdge, vertex, isWaveform)) =>
                        let nextElements = HashSet<TraversalElement<V, G>>()
                        // Remove the gate edge
                        RemoveEdge(e, f)
                        // Remove the trigger edge and vertex
                        RemoveEdge(signalEdge, f)
                        RemoveVertex(vertex, f)
                        // Put the other vertices as the next elements,
                        // as they will become the identity
                        forEach({
                            i : Int64 =>
                                ConnectIdentifiedWires(
                                    nextElements, e, index, i
                                )
                        }, end: e.GetCoarity())
                        Some(nextElements)
                }
            }
        }
    )
}