/**
 * rewrite/local.cj
 *
 * Local rewrites of hypergraphs
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
var totalRewrites = 0
/**
 * Given a rewrite rule, try to apply it to a given edge.
 *
 * @param signature
 * @param e
 * @param rule
 * @param f The interfaced graph we are rewriting in
 * @param debug Whether to draw the graph after rewriting
 * @return None if the rule could not be applied, or Some hashmap containing the
 *                 next elements to traverse
 */
func AttemptRewriteRule<V, G>(
    signature : Signature<V, G>, e : Edge<V, G>,
    rule : RewriteRule<V, G>, f : InterfacedHypergraph<V, G>,
    draw!: Bool = false, debug!: Bool = false
) : Option<HashSet<TraversalElement<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    match(rule.Rewrite(e, f)) {
        case None => None
        case Some(result) =>
            Debug("Rewrote ${e} with ${rule.name}")
            if(draw) {
                let fileName =
                    "rewrite-${totalRewrites}-${e.GetId()}-${rule.GetName()}"
                f.WriteDotToFile("dot/${fileName}", depth: 0, debug: debug)
            }
            totalRewrites++
            Some(result)
    }
}
/**
 * Given an edge, attempt all rewrite rules that could apply to it. If a rewrite
 * is successfully performed, return the next elements rather than continuing,
 * as the edge could have been removed from the graph.
 *
 * @param edge
 * @param f The interfaced hypergraph we are rewriting in
 * @param signature
 * @param copyBlackboxes (optional)
 *     Whether to allow the copying of blackboxes, which is sometimes desired if
 *     we are rewriting a graph with multiple outputs into disjoint graphs for
 *     each output
 * @param allInstantaneous (optional)
 *     Whether this is a graph where all the inputs are guaranteed to be
 *     instantaneous i.e. we know that eventually they will only ever be signals
 * @param debug (optional)
 *     Whether to draw dot graphs after every rewrite
 * @return
 *     Either None if no rewrites could be performed, or Some hashset containing
 *     the next elements to be traversed
 */
func AttemptAllRewriteRules<V, G>(
    edge : Edge<V, G>, f : InterfacedHypergraph<V, G>,
    signature : Signature<V, G>, copyBlackBoxes!: Bool = false,
    allInstantaneous!: Bool = false, partial!: Bool = false,
    debug!: Bool = false, draw!: Bool = false
) : Option<HashSet<TraversalElement<V, G>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let label = edge.GetLabel()
    let validRules = ArrayList<RewriteRule<V, G>>()
    // Hashmap for tracking the 'active' vertex of a blackbox
    // This is only required when separating each state, where
    // any blackbox with multiple outputs is separated into
    // ones where only one output is 'active' and the rest
    // are stubbed
    let blackBoxTracker = HashMap<Edge<V, G>, Int64>()
    func AddRule(rule : RewriteRule<V, G>) {
        validRules.append(rule)
    }
    AddRule(GetStubRule())
    AddRule(GetBottomRule(signature))
    match(label) {
        case VALUE(_) =>
            AddRule(GetForkRule())
        case SIGNAL(_) =>
            AddRule(GetForkRule())
        case PARTIAL(_) =>
            AddRule(GetForkRule())
        case BUNDLER(_, _) =>
            AddRule(GetValueBundleRule(signature))
        case JOIN(_) =>
            AddRule(GetJoinRule(signature))
        case PRIMITIVE(_) =>
            AddRule(GetPrimitiveRule(signature))
            if(allInstantaneous) {
                for(ann in signature.GetAnnihilators()) {
                    AddRule(GetAnnihiliationRule(ann))
                }
                for(ide in signature.GetIdentities()) {
                    AddRule(GetIdentifierRule(ide))
                }
            }
        case ENHANCED_PRIMITIVE(_) =>
            AddRule(GetCompositeRule(signature))
        case COMPOSITE(_) =>
            AddRule(GetCompositeRule(signature))
        case BLACKBOX(_) =>
            if(copyBlackBoxes) {
                AddRule(GetCopyBlackboxRule(blackBoxTracker))
                AddRule(GetForkBlackboxRule(blackBoxTracker))
            }
        case _ => ()
    }
    for(rule in validRules) {
        match(
            AttemptRewriteRule(
                signature, edge, rule, f, debug: debug, draw: draw
            )
        ){
            case None => ()
            case Some(result) => return Some(result)
        }
    }
    return None
}
/**
 * Rewrite a combinational circuit as much as possible, given some starting and
 * ending elements to traverse between.
 *
 * @param signature
 * @param f The interfaced hypergraph we are rewriting in
 * @param startingElements
 * @oaram endingElements
 * @param copyBlackboxes (optional)
 *     Whether to allow the copying of blackboxes, which is sometimes desired if
 *     we are rewriting a graph with multiple outputs into disjoint graphs for
 *     each output
 * @param allInstantaneous (optional)
 *     Whether this is a graph where all the inputs are guaranteed to be
 *     instantaneous i.e. we know that eventually they will only ever be signals
 * @param debug (optional)
 *     Whether to draw dot graphs after every rewrite
 */
public func RewriteCombinational<V, G>(
    signature : Signature<V, G>, f : InterfacedHypergraph<V, G>,
    startingElements : HashSet<TraversalElement<V, G>>,
    endingElements : HashSet<TraversalElement<V, G>>,
    copyBlackBoxes!: Bool = false, allInstantaneous!: Bool = false,
    debug!: Bool = false, draw!: Bool = false
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let visitedSources = HashMap<Edge<V, G>, HashSet<Vertex<V, G>>>()
    let actionAtEdge = {
        e : Edge<V, G>, data : TraversalData<V, G> =>
            // Only rewrite or proceed from this edge if its sources have
            // all been traversed
            let visitedSet = match(visitedSources.get(e)) {
                case None =>
                    let set = HashSet<Vertex<V, G>>()
                    visitedSources.put(e, set)
                    set
                case Some(set) => set
            }
            for(v in e.GetSources()) {
                if(visitedSet.contains(v)) {
                    return HashSet<TraversalElement<V, G>>()
                }
            }
            match(AttemptAllRewriteRules(
                e, f, signature, copyBlackBoxes: copyBlackBoxes,
                allInstantaneous: true, debug: debug, draw: draw
            )) {
                case Some(result) => result
                case None =>
                    let nextElements = HashSet<TraversalElement<V, G>>()
                    for(v in e.GetTargets()) {
                        let te = VERTEX(v)
                        if(!endingElements.contains(te)) {
                            nextElements.put(te)
                        }
                    }
                    nextElements
                }
    }
    let actionAtVertex = {
        v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        for(ec in v.GetOutEdges()) {
            let te = EDGE(ec.GetEdge())
            if(!endingElements.contains(te)){
                nextElements.put(te)
            }
        }
        nextElements
    }
    Traverse<V, G>(
        startingElements, actionAtVertex: actionAtVertex,
        actionAtEdge: actionAtEdge, revisit: true,
    )
}
/**
 * Rewrite a combinational circuit as much as possible, given some starting
 * elements to traverse from.
 *
 * @param signature
 * @param f The interfaced hypergraph we are rewriting in
 * @param startingElements
 * @param copyBlackboxes (optional)
 *     Whether to allow the copying of blackboxes, which is sometimes desired if
 *     we are rewriting a graph with multiple outputs into disjoint graphs for
 *     each output
 * @param allInstantaneous (optional)
 *     Whether this is a graph where all the inputs are guaranteed to be
 *     instantaneous i.e. we know that eventually they will only ever be signals
 * @param debug (optional)
 *     Whether to draw dot graphs after every rewrite
 */
public func RewriteCombinational<V, G>(
    signature : Signature<V, G>, f : InterfacedHypergraph<V, G>,
    startingElements : HashSet<TraversalElement<V, G>>, copyBlackBoxes!: Bool,
    allInstantaneous!: Bool, debug!: Bool = false, draw!: Bool = false
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    RewriteCombinational(
        signature, f, startingElements, HashSet<TraversalElement<V, G>>(),
        copyBlackBoxes: copyBlackBoxes, debug: debug, draw: draw
    )
}
/**
 * Rewrite a combinational circuit as much as possible, traversing the entire
 * graph.
 *
 * @param signature
 * @param f The interfaced hypergraph we are rewriting in
 * @param copyBlackboxes (optional)
 *     Whether to allow the copying of blackboxes, which is sometimes desired if
 *     we are rewriting a graph with multiple outputs into disjoint graphs for
 *     each output
 * @param allInstantaneous (optional)
 *     Whether this is a graph where all the inputs are guaranteed to be
 *     instantaneous i.e. we know that eventually they will only ever be signals
 * @param debug (optional)
 *     Whether to draw dot graphs after every rewrite
 */
public func RewriteCombinational<V, G>(
    signature : Signature<V, G>, f : InterfacedHypergraph<V, G>,
    copyBlackBoxes!: Bool, allInstantaneous!: Bool, debug!: Bool = false,
    draw!: Bool = false
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let startingElements = HashSet<TraversalElement<V, G>>()
    startingElements.putAll(f.GetLeftmostTraversalElements())
    for(iv in f.GetInputs()) {
        startingElements.put(VERTEX(iv.GetVertex()))
    }
    RewriteCombinational(
        signature, f, startingElements,
        HashSet<TraversalElement<V, G>>(), copyBlackBoxes: copyBlackBoxes,
        allInstantaneous: allInstantaneous, debug: debug, draw: draw
    )
}