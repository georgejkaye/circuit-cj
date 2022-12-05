/**
 * rewrite/local.cj
 *
 * Local rewrites of hypergraphs
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

import prelude.map
import graphs.*
import debug.Debug

from std import collection.HashMap
from std import collection.HashSet

public func RewriteCombinational<V, G>(
    signature : Signature<V, G>,
    rules : ArrayList<RewriteRule<V, G>>,
    f : InterfacedHypergraph<V, G>,
    starting : HashSet<TraversalElement<V, G>>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let ending = HashSet<TraversalElement<V, G>>()
    for(iv in f.GetOutputs()) {
        let v = iv.GetVertex()
        // At this stage of rewriting every output
        // should be a join of an immediate graph and
        // a delayed graph
        let joinEdge = v.GetInEdge().getOrThrow().GetEdge()
        let source = joinEdge.GetSource(0).GetVertex()
        ending.put(VERTEX(source))
    }
    let actionAtEdge = {
        e : Edge<V, G>, data : TraversalData<V, G> =>
            let nextElements = HashSet<TraversalElement<V, G>>()
            let removedElements = HashSet<TraversalElement<V, G>>()
            for(rule in rules) {
                if(rule.CanRewrite(e, f)) {
                    Debug("Rewriting ${e} with ${rule.name}")
                    return rule.Rewrite(e, f)
                }
            }
            if(!e.GetLabel().IsDelay()) {
                for(t in e.GetTargets()) {
                    let te = VERTEX(t.GetVertex())
                    if(!ending.contains(te)) {
                        nextElements.put(te)
                    }
                }
            }
            (nextElements, removedElements)
    }
    let actionAtVertex = {
        v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        for(ec in v.GetOutEdges()) {
            let te = EDGE(ec.GetEdge())
            if(!ending.contains(te)){
                nextElements.put(te)
            }
        }
        (nextElements, HashSet<TraversalElement<V, G>>())
    }
    let startingElements = HashSet<TraversalElement<V, G>>()
    for(e in starting) {
        startingElements.put(e)
    }
    Traverse<V, G>(
        startingElements,
        0,
        actionAtVertex,
        actionAtEdge,
        revisit: true
    )
}