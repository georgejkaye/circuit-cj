/**
 * rewrite/rule.cj
 *
 * Contains the definition of rewrite rules
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
from std import collection.ArrayList
import components.*
import utils.*
/**
 * Entry point to a rewrite rule: the category of label that triggers
 * a rewrite attempt
 */
public enum EntryPoint {
    | VALUE | PRIMITIVE | NJOIN | ENHANCED | SUBGRAPH | ANY | BUNDLE | BLACKBOX
}
/**
 * A rewrite rule consists of a name, an 'entry point' which is the class of
 * label that this rewrite potentially applies to, and the actual rewrite:
 * a function that takes an edge and graph, and either returns None if the
 * rewrite cannot be applied, or two hashsets specifying the next elements to
 * traverse and the elements removed by the rewrite.
 */
public struct RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public RewriteRule(
        let name : String,
        let entryPoint : EntryPoint,
        let rewrite :  (Edge<V, G>, InterfacedHypergraph<V, G>)
                        -> Option<(
                            HashSet<TraversalElement<V, G>>,
                            HashSet<TraversalElement<V, G>>
                        )>
    ){}
    /**
     * Check if this rewrite can potentially be applied to a particular edge.
     * This does not mean the rule can actually be applied, but that the edge
     * has the class of label that this rewrite applies to.
     *
     * @param e The edge to check against
     * @return Whether the edge label is of a class the rewrite applies to
     */
    public func CanRewrite(
        e : Edge<V, G>
    ) : Bool {
        let label = e.GetLabel()
        match(this.entryPoint) {
            case ANY => true
            case VALUE => label.IsSignal()
            case PRIMITIVE => label.IsPrimitive()
            case NJOIN => label.IsJoin()
            case ENHANCED => label.IsEnhanced()
            case SUBGRAPH => label.IsComposite()
            case BUNDLE => label.IsBundler()
            case BLACKBOX => label.IsBlackBox()
        }
    }
    /**
     * @return The name of this rewrite
     */
    public func GetName() : String {
        this.name
    }
    /**
     * Attempt to perform this rewrite on an edge, assuming that it is of
     * the correct class (i.e. CanRewrite has returned true). Returns None
     * if the rewrite cannot be applied, or returns two hash sets for the next
     * elements to be traversed and the removed elements if successful.
     *
     * @param e The edge
     * @param f The interfaced graph to be rewriting in
     * @return None if unsuccessful, or (Next elements, Removed elements) if
     *           sucessful
     */
    public func Rewrite(
        e : Edge<V, G>,
        f : InterfacedHypergraph<V, G>
    ) : Option<(
        HashSet<TraversalElement<V, G>>,
        HashSet<TraversalElement<V, G>>
    )> {
        this.rewrite(e, f)
    }
}
/**
 * Perform actions associated with removing an edge during a rewrite: removes
 * the edge from the graph and puts it in a set of removed elements.
 *
 * @param e The edge
 * @param f The graph
 * @param removedElements
 */
func RemoveEdge<V, G>(
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>,
    removedElements : HashSet<TraversalElement<V, G>>
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    f.RemoveEdge(e)
    removedElements.put(EDGE(e))
}
/**
 * Perform actions associated with removing an vertex during a rewrite: removes
 * the vertex from the graph and puts it in a set of removed elements.
 *
 * @param v The vertex
 * @param f The graph
 * @param removedElements
 */
func RemoveVertex<V, G>(
    v : Vertex<V, G>, f : InterfacedHypergraph<V, G>,
    removedElements : HashSet<TraversalElement<V, G>>
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    f.RemoveVertex(v)
    removedElements.put(VERTEX(v))
}
/**
 * Check if the targets of an edge have the same number of outedges, so we
 * can apply a fork-like rule.
 *
 * @param e
 * @param f The interfaced owner
 * @return Whether the fork condition is satisfied
 */
func ForkCondition<V, G>(
    e : Edge<V, G>,
    f : InterfacedHypergraph<V, G>
) : Bool
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    if(e.GetCoarity() > 0){
        let firstTarget = e.GetTarget(0)
        let outboundTentacles = firstTarget.GetOutTentacles(f)
        if(outboundTentacles < 2) {
            return false
        }
        for(i in 1..e.GetCoarity()) {
            let currentTarget = e.GetTarget(i)
            if(outboundTentacles != currentTarget.GetOutTentacles(f)) {
                return false
            }
        }
        true
    } else {
        false
    }
}
/**
 * Given an edge with some target vertices that fork a given number of times,
 * propagate this edge across the vertices so that the edge is copied.
 *
 * @param e The edge to propagate
 * @param outTentacles An array of arrays where outTentacles[i][j] defines the
             (single) outgoing tentacle of the jth target vertex of the ith copy
* @return The hash set of next elements and removed elements
*/
func PropagateAcrossFork<V, G>(
    e : Edge<V, G>,
    f : InterfacedHypergraph<V, G>,
    outTentacles : Array<Array<Option<TentacleType<V, G>>>>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let nextElements = HashSet<TraversalElement<V, G>>()
    // We use the original edge as one of the copies to reduce redundant
    // creation of edges. This edge also retains the original target vertices.
    nextElements.put(EDGE(e))
    for(i in 1..outTentacles.size) {
        // Get the out tentacles for this copy
        let targetDestinations = outTentacles[i]
        // Make the targets for this edge
        let newTargets = map({
            v : Vertex<V, G> => f.GetGraph().AddNewVertex(v.GetWidth())
        }, e.GetTargets())
        // Make the edge copy: it forks the original sources rather than targets
        let edgeCopy = Edge(
            e.GetLabel(), e.GetSources(),newTargets,
            e.GetSubgraph(), e.GetGraph()
        )
        nextElements.put(EDGE(edgeCopy))
        // Send tentacles to each target vertex
        for(i in 0..targetDestinations.size) {
            let td = targetDestinations[i]
            let targetVertex = newTargets[i].GetVertex()
            match(td){
                case None => ()
                case Some(tt) =>
                    match(tt) {
                        case EDGE_TENTACLE(ec) =>
                            ec.GetEdge().SetSource(ec.GetIndex(), targetVertex)
                        case INTERFACE_TENTACLE(f, i) =>
                            f.ReplaceOutput(i, targetVertex)
                    }
            }
        }
    }
    (nextElements, HashSet())
}
/**
 * Get an array of out tentacles from a given target of an edge, in an
 * arbitrary order
 *
 * @param f The interfaced hypergraph we are rewriting in
 * @param e The edge
 * @param i The index of the target
 * @return The array of outgoing tentacles, in an arbitrary order
 */
func GetOutgoingTentacles<V, G>(
    f : InterfacedHypergraph<V, G>,
    e : Edge<V, G>,
    i : Int64
) : Array<TentacleType<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let tentacleTargets = ArrayList<TentacleType<V, G>>()
    // Values always have precisely one target
    let target = e.GetTarget(0)
    for(ec in target.GetOutEdges()) {
        tentacleTargets.append(EDGE_TENTACLE(ec))
    }
    for(it in f.GetOutputPositions(target)) {
        tentacleTargets.append(INTERFACE_TENTACLE(f, it))
    }
    tentacleTargets.toArray()
}
/**
 * Get the rewrite rule for copying values across a fork, i.e. a vertex with
 * multiple out tentacles.
 *
 * @return The fork rewrite rule
 */
func GetForkRule<V, G>() : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "fork",
        VALUE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            if(!ForkCondition(e, f)){
                None
            } else {
                let tentacleTargets = GetOutgoingTentacles(f, e, 0)
                let tentacleTargetsPerEdge = map(
                    { tt : TentacleType<V, G> => [Some(tt)] },
                    tentacleTargets
                )
                Some(PropagateAcrossFork(e, f, tentacleTargetsPerEdge))
            }
        }
    )
}
/**
 * Check that the edges to the left of an edge are all values or signals.
 *
 * @param e The edge
 * @param f The interfaced graph we are rewriting in
 * @return If the apply preconditions are met
 */
func ApplyPreconditions<V, G>(e : Edge<V, G>) : Bool
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let sources = e.GetSources()
    // Check that none of the values are forked
    // If they are, we need to fork them first!
    for (v in sources) {
        if(v.GetOutEdges().size != 1){
            return false
        }
    }
    // Check arguments are all values
    for(v in sources) {
        match(v.GetInEdge()){
            case None => return false
            case Some(ec) =>
                if(!ec.GetEdge().GetLabel().IsSignal()) {
                    return false
                }
        }
    }
    return true
}
/**
 * Assuming that the apply preconditions above are met, get the argument edges
 * of a given edge and the values stored within these edges.
 *
 * @param e The edge
 * @return An array of the argument edges and an array of the argument values
 */
func GetArgs<V, G>(
    e : Edge<V, G>
) : (Array<Option<Edge<V, G>>>, Array<Option<Array<V>>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let argumentEdges = map({
            v : Vertex<V, G> =>
                match(v.GetInEdge()) {
                    case None => None<Edge<V, G>>
                    case Some(ec) =>
                        let edge = ec.GetEdge()
                        if(edge.GetLabel().IsSignal()) {
                            Some(edge)
                        } else {
                            None<Edge<V, G>>
                        }
                }
        }, e.GetSources()
    )
    let argumentValues = map({
            arg : Option<Edge<V, G>> =>
                match(arg) {
                    case None => None<Array<V>>
                    case Some(e) => e.GetLabel().GetValueArray()
                }
        }, argumentEdges
    )
    (argumentEdges, argumentValues)
}
/**
 * Given an array of value symbols, create a value edge if the array has length
 * 1 or a signal edge edge with appropriate subgraph otherwise.
 *
 * @param vs
 * @param targets The targets the new edge will have
 * @param owner
 * @return the new edge
 */
func MakeValueOrSignal<V, G>(
    vs : Array<V>,
    targets : Array<Vertex<V, G>>,
    owner : Hypergraph<V, G>
) : Edge<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let (label, graph) = if(vs.size == 1) {
        (Label<V, G>.VALUE(vs[0]), None<InterfacedHypergraph<V, G>>)
    } else {
        let signal = Signal(vs)
        (Label<V, G>.SIGNAL(signal), Some(MakeSignal<V, G>(signal)))
    }
    Edge(label, Array<Vertex<V, G>>(), targets, graph, owner)
}
/**
 * Given an edge, its argument edges and an array of array of output values,
 * replace it with edges corresponding to each signal
 *
 * @param signature
 * @param f The graph we are rewriting in
 * @param e The edge to replace
 * @param results
    The array of array of values corresponding to the result of computation
 * @return A pair of hash sets (next elements, removed elements)
 */
 func ReplaceGateWithOutputs<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    e : Edge<V, G>,
    args : Array<Option<Edge<V, G>>>,
    results : Array<Array<V>>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let nextEdges = HashSet<TraversalElement<V, G>>()
    let removedEdges = HashSet<TraversalElement<V, G>>()
    // Each argument edge must be discarded
    for(arg in args) {
        let actualArg = arg.getOrThrow()
        RemoveEdge(actualArg, f, removedEdges)
    }
    // Remove the gate edge
    RemoveEdge(e, f, removedEdges)
    // Each source of the gate edge must be discarded
    for(v in e.GetSources()) {
        RemoveVertex(v, f, removedEdges)
    }
    // Create a new value or signal edge for each of the output values
    for(i in 0..results.size) {
        let result = results[i]
        // Get a value or signal label accordingly
        let signalLabel = GetSignalLabel<V, G>(result)
        // Get the subgraph corresponding to the signal, or None if it has
        // size 1 (it is a raw value)
        let signalGraph = MakeSignal<V, G>(Signal(result))
        // Create the edge using the remaining target of the original edge
        let target = e.GetTarget(i)
        let newEdge = Edge(
            signalLabel, Array<Vertex<V, G>>(), [target],
            Some(signalGraph), Some(f.GetGraph())
        )
        nextEdges.put(EDGE(newEdge))
    }
    (nextEdges, removedEdges)
}
/**
 * Get the rewrite rule for applying a gate to some arguments, using the
 * corresponding function in a signature.
 *
 * @param signature
 * @return The apply rewrite rule
 */
func GetApplyRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "apply",
        PRIMITIVE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ApplyPreconditions(e)){
                    None
                } else {
                    // This edge is guaranteed to be a primitive
                    // by the rewrite precondition
                    let prim = e.GetLabel().GetPrimitive()
                    // Get the corresponding function from the signature
                    let function = signature.GetGate(prim)
                    // Get the arguments to the gate
                    let (argumentEdges, argumentValues) = GetArgs(e)
                    let actualArgumentValues = map(
                        { vs : Option<Array<V>> => vs.getOrThrow() },
                        argumentValues
                    )
                    // Compute the outputs of the gate and replace accordingly
                    let result = function(actualArgumentValues)
                    ReplaceGateWithOutputs(
                        signature, f, e, argumentEdges, result
                    )
                }
        }
    )
}
/**
 * Get the rewrite rule for discarding an edge with all its outputs stubbed.
 *
 * @return The stub rewrite rule
 */
func GetStubRule<V, G>() : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "stub",
        ANY,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // Check to see if each target has no outgoing tentacles
                let targets = e.GetTargets()
                for(v in targets) {
                    if(
                        v.GetOutEdges().size != 0 ||
                        f.GetOutputPositions(v).size != 0
                    ) {
                        return None
                    }
                }
                // The next elements are the edges to the left of this one, as
                // they may also need to be discarded now
                let nextElements = HashSet<TraversalElement<V, G>>()
                let removedElements = HashSet<TraversalElement<V, G>>()
                for(v in e.GetSources()){
                    v.RemoveOutEdge(e)
                    match(v.GetInEdge()){
                        case Some(ec) =>
                            nextElements.put(EDGE(ec.GetEdge()))
                        case None =>
                            // If this vertex has no in edges and is also not
                            // in the interface, we can remove it altogether
                            if(v.GetInterfacedInputs().size == 0){
                                RemoveVertex(v, f, removedElements)
                            }
                    }
                }
                // Now remove the edge
                RemoveEdge(e, f, removedElements)
                // The targets can also be removed
                for(v in e.GetTargets()) {
                    RemoveVertex(v, f, removedElements)
                }
                (nextElements, removedElements)
        }
    )
}
/**
 * Get the rewrite rule for joining two values or signals together, using the
 * join operation in the signature lattice.
 *
 * @param signature
 * @return The join rewrite rule
 */
func GetJoinRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "join",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // The join is just a special kind of gate, so we follow
                // the same procedure
                let (argumentEdges, argumentValues) = GetArgs(e)
                try {
                    // We know a join always has two arguments so we can
                    // access them explicitly
                    let result = signature.Join(
                        argumentValues[0].getOrThrow(),
                        argumentValues[1].getOrThrow()
                    )
                    Some(
                        ReplaceGateWithOutputs(
                            signature, f, e,
                            [argumentEdges[0], argumentEdges[1]],
                            [result]
                        )
                    )
                // If not everything is an argument, an exception will be
                // thrown when we try to read the contents of a None
                } catch(e : NoneValueException) {
                    return None
                }
        }
    )
}
/**
 * Check if a specific argument to an edge is a signal in which all the elements
 * are a specific value.
 *
 * @param v The value to check for
 * @param e The edge
 * @param i The index of the source to check the argument of
 * @return Whether the specific argument is all this value
 */
func ArgumentIsAllValue<V, G>(v : V, e : Edge<V, G>, i : Int64) : Bool
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    match(e.GetSource(i).GetInEdge()){
        case None => false
        case Some(e) => e.GetEdge().GetLabel().IsAllValue(v)
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
func ArgumentsAreAllValue<V, G>(v : V, e : Edge<V, G>) : Bool
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    // Need to explicitly check for the zero case because otherwise it will
    // return true which is not desired
    if(e.GetArity() > 0) {
        for(i in 0..e.GetArity()) {
            if(!ArgumentIsAllValue(v, e, i)) {
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
    e : Edge<V, G>,
    i : Int64,
    f : InterfacedHypergraph<V, G>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    // Get the argument edge to remove
    let arg = e.NextEdgeLeft(i).GetEdge()
    // Compute the index of the gate that will become the passthrough identity
    let otherIndex = if (i == 0) { 1 } else { 0 }
    // Track the source and target we will merge to get the identity
    let source = e.GetSource(otherIndex)
    let target = e.GetTarget(i)
    let nextElements = HashSet<TraversalElement<V, G>>()
    let removedElements = HashSet<TraversalElement<V, G>>()
    // Remove the gate edge
    RemoveEdge(e, f, removedElements)
    // Remove the argument edge
    RemoveEdge(arg, f, removedElements)
    // Remove each target from this edge, as it is becoming an identity
    for(v in arg.GetTargets()) {
        RemoveVertex(v, f, removedElements)
    }
    // Merge the dangling source and target
    source.MergeVertex(target, false)
    // If the identity has another edge to the left, add it to the queue
    match(source.GetInEdge()) {
        case None => ()
        case Some(ec) => nextElements.put(EDGE(ec.GetEdge()))
    }
    (nextElements, removedElements)
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
func GetJoinUnitRule<V, G>(
    signature : Signature<V, G>,
    i : Int64,
    str : String
) : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
        RewriteRule<V, G>(
        "join-unit-${str}",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ArgumentIsAllValue(signature.GetBottom(), e, i)){
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
func GetJoinUnitLeftRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
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
func GetJoinUnitRightRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & LessOrEqual<V>,
    G <: PrimitiveSymbol<V> & Equatable<G>
{
    GetJoinUnitRule(signature, 1, "r")
}
/**
 * Perform a rewrite that involves expanding a subgraph from a parent edge,
 * assuming that there is a subgraph inside the edge
 *
 * @param e The edge
 * @param f The interfaced graph we are rewriting in
 * @return The hash set of next elements and removed elements
 */
func ExpandSubgraphRewrite<V, G>(
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{

    let nextElements = HashSet<TraversalElement<V, G>>()
    let removedElements = HashSet<TraversalElement<V, G>>()
    // We assume there is a subgraph in this edge
    let subgraph = e.GetSubgraph().getOrThrow()
    let (newSources, newTargets) = e.BurstSubgraph()
    // Add the merged sources as the next elements to traverse
    for(t in newSources) {
        match(t.GetVertex().GetInEdge()){
            case Some(ec) => nextElements.put(EDGE(ec.GetEdge()))
            case None => ()
        }
    }
    // Also add the values contained within the subgraph
    for(edge in subgraph.GetValueEdges()){
        nextElements.put(EDGE(edge))
    }
    // The edge has already been removed by the burst subgraph operation
    removedElements.put(EDGE(e))
    (nextElements, removedElements)
}
/**
 * Get the rewrite rule for rewriting an enhanced gate, i.e. one parameterised
 * for more than one input or a greater width
 *
 * @param signature
 * @return The enhanced rewrite rule
 */
func GetEnhancedRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
        RewriteRule<V, G>(
        "enhanced",
        ENHANCED,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // Only rewrite enhanced edges if all their arguments are signals
            if(!ApplyPreconditions(e)){
                None
            } else {
                Some(ExpandSubgraphRewrite(e, f))
            }
        }
    )
}
/**
 * Get the rewrite rule for a composite rule, i.e. expanding it to see if any
 * rewrites can be applied to it.
 *
 * @param signature
 * @return The composite rewrite rule
 */
func GetCompositeRule<V, G>(signature : Signature<V, G>, all : Bool)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "composite",
        SUBGRAPH,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // Always expand composite edges
            Some(ExpandSubgraphRewrite(e, f))
        }
    )
}
/**
 * Get a value bundle rule, where the values applied to a bundle are transformed
 * into appropriate width signals.
 *
 * @param signature
 * @return The value bundle rule
 */
func GetValueBundleRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "bundle",
        BUNDLE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ApplyPreconditions(e)){
                    None
                } else {
                    let newElements = HashSet<TraversalElement<V, G>>()
                    let removedElements = HashSet<TraversalElement<V, G>>()
                    let values = ArrayList<V>()
                    // Remove the bundle edge
                    RemoveEdge(e, f, removedElements)
                    // Get all the individual values in an array
                    for(v in e.GetSources()){
                        // Precondition enforces there must be an in edge
                        let valueEdge = v.GetInEdge().getOrThrow().GetEdge()
                        match(valueEdge.GetLabel()) {
                            case VALUE(v) =>
                                values.append(v)
                            case SIGNAL(signal) =>
                                values.appendAll(signal.GetValues())
                            case _ => ()
                        }
                        // Remove the old value edges and their vertices
                        RemoveEdge(valueEdge, f, removedElements)
                        RemoveVertex(v, f, removedElements)
                    }
                    // Create a new signal edge for each output of the bundle
                    for(v in e.GetTargets()) {
                        let width = v.GetWidth()
                        let newEdge = if(width == 1) {
                            let value = values.remove(0)
                            Edge(
                                Label.VALUE(value), Array<Vertex<V, G>>(),
                                [v], None, f.GetGraph()
                            )
                        } else {
                            // Pop an appropriate number of values off the
                            // complete arraylist of all values
                            let wireValues = Array<V>(width){
                                i : Int64 => values.remove(0)
                            }
                            let signal = Signal(wireValues)
                            // Make the signal subgraph
                            let signalGraph = MakeSignal<V, G>(signal)
                            Edge(
                                SIGNAL(signal), Array<Vertex<V, G>>(),
                                [v], signalGraph, f.GetGraph()
                            )
                        }
                        newElements.put(EDGE(newEdge))
                    }
                    Some((newElements, removedElements))
                }
        }
    )
}
/**
 * Get the bottom rule, i.e. any edge applied to all bottoms is just buttoms.
 *
 * @param signature
 * @return The bottom rule
 */
func GetBottomRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "bottom",
        ANY,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            if(!ArgumentsAreAllValue(signature.GetBottom(), e)){
                None
            } else {
                let (argumentEdges, argumentValues) = GetArgs(e)
                // Get appropriate width bottoms for each target of the edge
                let bottoms = Array<Array<V>>(e.GetCoarity()){
                    i : Int64 =>
                        Array<V>(e.GetTarget(i).GetWidth()){
                            j : Int64 => signature.GetBottom()
                        }
                }
                ReplaceGateWithOutputs<V, G>(
                    signature, f, e, argumentEdges, bottoms
                )
            }
        }
    )
}
/**
 * Get the copy blackbox rule, where if a blackbox has multiple targets,
 * enough copies are made so that each blackbox has precisely one target that
 * is not a stub. This is useful when we want each state transition of
 * an evaluation to have a distinct subgraph.
 *
 * @param blackBoxTracker A hashmap representing the 'active' output of a
 *                          blackbox edge
 * @param signature
 * @return The copy blackbox rule
 */
func GetCopyBlackboxRule<V, G>(blackBoxTracker : HashMap<Edge<V, G>, Int64>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "blackbox-copy",
        BLACKBOX,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            let targets = e.GetTargets().size
            // If a blackbox has less than two targets, this rule does not
            // apply: the fork blackbox rule takes precedence
            if(targets < 2) {
                blackBoxTracker.put(e, 0)
                None
            } else {
                let nextEdges = HashSet<TraversalElement<V, G>>()
                let discardedEdges = HashSet<TraversalElement<V, G>>()
                // Create a copy of the blackbox for each target
                for(i in 0..targets) {
                    let newTargets = Array<Vertex<V, G>>(targets){
                        j : Int64 =>
                            // Outputs below the current index will be stubbed
                            // so need a new vertex
                            if(j < i){
                                f.GetGraph().AddNewVertex(
                                    e.GetTarget(j).GetWidth()
                                )
                            // The current index will be retained to preserve
                            // the connections
                            } else if (j == i) {
                                e.GetTarget(j)
                            // Outputs above the current index will be stubbed
                            // so need a new vertex
                            } else {
                                f.GetGraph().AddNewVertex(
                                    e.GetTarget(j + 1).GetWidth()
                                )
                            }
                    }
                    // Create the new blackbox with the specified targets,
                    // forking the original sources
                    let newEdge = e.Clone(
                        e.GetSources(), newTargets, f.GetGraph()
                    )
                    nextEdges.put(EDGE(newEdge))
                    // Make a note of the 'active' target of this blackbox
                    blackBoxTracker.put(newEdge, i)
                }
                discardedEdges.put(EDGE(e))
                Some((nextEdges, discardedEdges))
            }
        }
    )
}
/**
 * Get the fork blackbox rule, where a blackbox is propagated over a fork.
 *
 * @param blackBoxTracker A hashmap keeping track of the 'active' target of a
                              black box edge, if they have been copied by the
                              copy blackbox rule
 * @return The fork blackbox rule
 */
func GetForkBlackboxRule<V, G>(blackBoxTracker : HashMap<Edge<V, G>, Int64>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
        RewriteRule<V, G>(
            "blackbox-fork",
            BLACKBOX,
            { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                match(blackBoxTracker.get(e)){
                    // If this edge is not in the blackbox tracker, rewrite it
                    // with the copy blackbox rule first
                    case None => None
                    case Some(i) =>
                        if(!ForkCondition(e, f)) {
                            None
                        } else {
                            let outgoingTentacles =
                                GetOutgoingTentacles(f, e, i)
                            let tentacleTargets = map(
                                { tt : TentacleType<V, G> =>
                                    Array<Option<TentacleType<V, G>>>(
                                        e.GetCoarity()
                                    ) {
                                        j : Int64 =>
                                            if(i == j) {
                                                Some(tt)
                                            } else {
                                                None
                                            }
                                    }
                                },
                                outgoingTentacles
                            )
                            Some(PropagateAcrossFork(e, f, tentacleTargets))
                        }
                }
            }
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
    e : Edge<V, G>, i : Int64, desired : Array<V>
) : Option<(Edge<V, G>, Vertex<V, G>)>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let vertex = e.GetSource(i)
    if(vertex.GetOutEdges().size == 1) {
        match(vertex.GetInEdge()) {
            case None => None
            case Some(ec) =>
                let edge = ec.GetEdge()
                let label = edge.GetLabel()
                if(!label.IsSignal() || label.GetValueArray() != desired) {
                    None
                } else {
                    Some((edge, vertex))
                }
        }
    } else {
        None
    }
}
/**
 * Get an annihiliation rule, where a particular input to a gate forces its
 * output to be a particular signal regardless of the other inputs.
 *
 * @param ann The annihilator to make a rule for
 * @return The annihilation rewrite rule
 */
func GetAnnihiliationRule<V, G>(
    ann : Annihilator<V, G>
) : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
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
                    case Some((signalEdge, vertex)) =>
                        let nextElements = HashSet<TraversalElement<V, G>>()
                        let removedElements = HashSet<TraversalElement<V, G>>()
                        // Remove the annihilating edge
                        RemoveEdge(signalEdge, f, removedElements)
                        // Remove the gate edge
                        RemoveEdge(e, f, removedElements)
                        // Remove the connections from the other inputs
                        for(i in 0..e.GetArity()) {
                            let v = e.GetSource(i)
                            v.RemoveOutEdge(e)
                            if(i != ann.index) {
                                nextElements.put(VERTEX(v))
                            } else {
                                RemoveVertex(v, f, removedElements)
                            }
                        }
                        // Create the annihilated outputs
                        let targets = e.GetTargets()
                        for(i in 0..ann.output.size) {
                            let signal = ann.output[i]
                            let resultEdge = MakeValueOrSignal(
                                signal, [targets[i]], f.GetGraph()
                            )
                            nextElements.put(EDGE(resultEdge))
                        }
                        Some((nextElements, removedElements))
                }
            }
        }
    )
}
/**
 * Get an identitfier rule, where a particular input to a gate forces the gate
 * to act as the identity regardless of the value of the other inputs.
 *
 * @param ann The identifier to make a rule for
 * @return The identifier rewrite rule
 */
func GetIdentifierRule<V, G>(
    ide : Identifier<V, G>
) : RewriteRule<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "identity-${ide.gate.GetName()}-${ide.index}-${ide.input}",
        PRIMITIVE,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // Check this is the right gate
            if(e.GetLabel().GetPrimitive() != ide.gate){
                None
            } else {
                let index = ide.index
                match(ArgumentIsUnsharedTrigger(e, index, ide.input)) {
                    case None => None
                    case Some((signalEdge, vertex)) =>
                        let nextElements =
                            HashSet<TraversalElement<V, G>>()
                        let removedElements =
                            HashSet<TraversalElement<V, G>>()
                        // Remove the gate edge
                        RemoveEdge(e, f, removedElements)
                        // Remove the trigger edge and vertex
                        RemoveEdge(signalEdge, f, removedElements)
                        RemoveVertex(vertex, f, removedElements)
                        // Put the other vertices as the next elements,
                        // as they will become the identity
                        for(i in 0..e.GetCoarity()) {
                            let v = e.GetSource(i)
                            if(i != index) {
                                nextElements.put(VERTEX(v))
                            }
                        }
                        for(i in 0..e.GetCoarity()) {
                            let actualIndex = if(i < index) {
                                i
                            } else {
                                i + 1
                            }
                            let source = e.GetSource(actualIndex)
                            if(i != index) {
                                nextElements.put(VERTEX(source))
                            }
                            let target = e.GetTarget(i)
                            source.MergeVertex(target, false)
                            nextElements.put(VERTEX(source))
                            // The target vertex has already been removed from
                            // the graph by the call to MergeVertex so we just
                            // need to add it to our hash map
                            removedElements.put(VERTEX(target))
                        }
                        Some((nextElements, removedElements))
                }
            }
        }
    )
}