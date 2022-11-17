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
    starting : ArrayList<Edge<V, G>>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let actionAtEdge = {
        e : Edge<V, G>, data : TraversalData<V, G> =>
            let nexts = HashSet<TraversalElement<V, G>>()
            for(rule in rules) {
                if(rule.CanRewrite(e, f)) {
                    Debug("Rewriting ${e} with ${rule.name}")
                    for(e in rule.Rewrite(e, f)){
                        nexts.put(EDGE(e))
                    }
                    return nexts
                }
            }
            if(!e.GetLabel().IsDelay()) {
                for(t in e.GetTargets()) {
                    nexts.put(VERTEX(t.GetVertex()))
                }
            }
            nexts
    }
    let actionAtVertex = {
        v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextEdges = HashSet<TraversalElement<V, G>>()
        for(ec in v.GetOutEdges()) {
            println("Next out edge")
            nextEdges.put(EDGE(ec.edge))
        }
        nextEdges
    }
    let startingElements = HashSet<TraversalElement<V, G>>()
    for(e in starting) {
        startingElements.put(EDGE(e))
    }
    BeginTraversal(
        startingElements,
        0,
        actionAtVertex,
        actionAtEdge,
        revisit: true
    )
}