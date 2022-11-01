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
    starting : ArrayList<EdgeAtDepth<V, G>>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let actionAtEdge = {
        ed : EdgeAtDepth<V, G>, data : TraversalData<V, G> =>
            let nexts = ArrayList<EdgeAtDepth<V, G>>()
            for(rule in rules) {
                if(rule.CanRewrite(ed.edge, f)) {
                    Debug("Rewriting ${ed.edge} with ${rule.name}")
                    for(e in rule.Rewrite(ed.edge, f)){
                        nexts.append(EdgeAtDepth(e, ed.depth))
                    }
                    return nexts
                }
            }
            GetUniqueNextEdges(ed, nexts)
            nexts
    }
    Traverse(starting, 0, actionAtEdge)
}