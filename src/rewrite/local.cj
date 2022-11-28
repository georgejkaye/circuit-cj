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
    let actionAtEdge = {
        e : Edge<V, G>, data : TraversalData<V, G> =>
            let nextEdges = HashSet<TraversalElement<V, G>>()
            let removedEdges = HashSet<TraversalElement<V, G>>()
            for(rule in rules) {
                if(rule.CanRewrite(e, f)) {
                    Debug("Rewriting ${e} with ${rule.name}")
                    return rule.Rewrite(e, f)
                }
            }
            if(!e.GetLabel().IsDelay()) {
                for(t in e.GetTargets()) {
                    nextEdges.put(VERTEX(t.GetVertex()))
                }
            }
            (nextEdges, removedEdges)
    }
    let actionAtVertex = {
        v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextEdges = HashSet<TraversalElement<V, G>>()
        for(ec in v.GetOutEdges()) {
            nextEdges.put(EDGE(ec.GetEdge()))
        }
        (nextEdges, HashSet<TraversalElement<V, G>>())
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