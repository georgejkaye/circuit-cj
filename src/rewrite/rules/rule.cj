/**
 * rewrite/rule.cj
 *
 * Contains the definition of rewrite rules
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite.rules
/**
 * Entry point to a rewrite rule: the category of label that triggers
 * a rewrite attempt
 */
public enum EntryPoint {
    | VALUE | PRIMITIVE | NJOIN | ENHANCED | SUBGRAPH | ANY | BUNDLE | BLACKBOX | PARTIAL
}
/**
 * A rewrite rule consists of a name, an 'entry point' which is the class of
 * label that this rewrite potentially applies to, and the actual rewrite:
 * a function that takes an edge and graph, and either returns None if the
 * rewrite cannot be applied, or two hashsets specifying the next elements to
 * traverse and the elements removed by the rewrite.
 */
public struct RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public RewriteRule(
        let name : String,
        let entryPoint : EntryPoint,
        let rewrite :  (Edge<V, G>, InterfacedHypergraph<V, G>)
                        -> Option<HashSet<TraversalElement<V, G>>>
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
            case VALUE => label.IsSignal() || label.IsWaveform()
            case PRIMITIVE => label.IsPrimitive()
            case NJOIN => label.IsJoin()
            case ENHANCED => label.IsEnhanced()
            case SUBGRAPH => label.IsComposite()
            case BUNDLE => label.IsBundler()
            case BLACKBOX => label.IsBlackBox()
            case PARTIAL => label.IsPartial()
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
    ) : Option<HashSet<TraversalElement<V, G>>> {
        this.rewrite(e, f)
    }
}
/**
 * Perform actions associated with removing an edge during a rewrite.
 *
 * @param e The edge
 * @param f The graph
 */
func RemoveEdge<V, G>(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    f.RemoveEdge(e)
}
/**
 * Perform actions associated with removing an vertex during a rewrite.
 *
 * @param v The vertex
 * @param f The graph
 */
func RemoveVertex<V, G>(v : Vertex<V, G>, f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    f.RemoveVertex(v)
}
/**
 * Check that the edges to the left of an edge are all values or signals.
 *
 * @param e The edge
 * @param f The interfaced graph we are rewriting in
 * @return If the apply preconditions are met
 */
func ApplyPreconditions<V, G>(e : Edge<V, G>) : Bool
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
                if(!ec.GetEdge().GetLabel().IsCycleInput()) {
                    return false
                }
        }
    }
    return true
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
    signal : Signal<V>,
    targets : Array<Vertex<V, G>>,
    owner : Hypergraph<V, G>
) : Edge<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let (label, graph) = if(signal.GetWidth() == 1) {
        (Label<V, G>.VALUE(signal.GetBit(0)), None<InterfacedHypergraph<V, G>>)
    } else {
        (Label<V, G>.SIGNAL(signal), Some(MakeSignal<V, G>(signal)))
    }
    Edge(label, Array<Vertex<V, G>>(), targets, graph, owner)
}
/**
 * Get the rewrite rule for discarding an edge with all its outputs stubbed.
 *
 * @return The stub rewrite rule
 */
public func GetStubRule<V, G>() : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteRule<V, G>(
        "stub",
        ANY,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // Check to see if each target has no outgoing tentacles
                for(v in e.GetTargets()) {
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
                for(v in e.GetSources()){
                    match(v.GetInEdge()){
                        case Some(ec) =>
                            nextElements.put(EDGE(ec.GetEdge()))
                        case None =>
                            // If this vertex has no in edges and is also not
                            // in the interface, we can remove it altogether
                            if(v.GetInterfacedInputs().size == 0 &&
                                v.GetOutEdges().size == 0
                            ){
                                RemoveVertex(v, f)
                            }
                    }
                }
                // Now remove the edge
                RemoveEdge(e, f)
                // The targets can also be removed
                for(v in e.GetTargets()) {
                    RemoveVertex(v, f)
                }
                nextElements
        }
    )
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
) : HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{

    let nextElements = HashSet<TraversalElement<V, G>>()
    // We assume there is a subgraph in this edge
    let subgraph = e.GetSubgraph().getOrThrow()
    // Add the values contained within the subgraph to the next elements
    for(edge in subgraph.GetValueEdges()){
        nextElements.put(EDGE(edge))
    }
    // Do the same for the disconnected edges
    for(edge in subgraph.GetDisconnectedEdges()) {
        nextElements.put(EDGE(edge))
    }
    let (newSources, newTargets) = e.BurstSubgraph()
    // Add the merged sources as the next elements to traverse
    for(v in newSources) {
        // Expanding the subgraph could create forks, so we retraverse
        // the edges before the source vertices in case there is rewrite
        // potential there
        match(v.GetInEdge()){
            case Some(ec) => nextElements.put(EDGE(ec.GetEdge()))
            case None => nextElements.put(VERTEX(v))
        }
    }
    nextElements
}
/**
 * Get the rewrite rule for rewriting an enhanced gate, i.e. one parameterised
 * for more than one input or a greater width
 *
 * @param signature
 * @return The enhanced rewrite rule
 */
public func GetEnhancedRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
public func GetCompositeRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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