/**
 * rewrite/rules/fork.cj
 *
 * Functions for rewrite rules that involve forking.
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite.rules
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
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
 *                          (single) outgoing tentacle of the jth target vertex
 *                          of the ith copy
 * @return The hash set of next elements
 */
func PropagateAcrossFork<V, G>(
    e : Edge<V, G>,
    f : InterfacedHypergraph<V, G>,
    outTentacles : Array<Array<Option<TentacleType<V, G>>>>
) : HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
        let edgeCopy = e.Clone(Array(e.GetSources()), newTargets, e.GetGraph())
        nextElements.put(EDGE(edgeCopy))
        // Send tentacles to each target vertex
        for(i in 0..targetDestinations.size) {
            let td = targetDestinations[i]
            let targetVertex = newTargets[i]
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
    nextElements
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
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
public func GetForkRule<V, G>() : RewriteRule<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
public func GetCopyBlackboxRule<V, G>(blackBoxTracker : HashMap<Edge<V, G>, Int64>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
                Some(nextEdges)
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
public func GetForkBlackboxRule<V, G>(blackBoxTracker : HashMap<Edge<V, G>, Int64>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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