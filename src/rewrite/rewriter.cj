/**
 * rewrite/rewriter.cj
 *
 * Contains the definition of the rewriter
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

public func RewriteCombinational(f : InterfacedHypergraph) : Unit {
    let actionAtEdge = {
        ed : EdgeAtDepth, data : TraversalData =>
            let nexts = ArrayList<EdgeAtDepth>()
            for(rule in rules) {
                if(rule.CanRewrite(ed.edge, f)) {
                    Debug("Rewriting ${ed.edge} with ${rule.name}")
                    for(e in rule.Rewrite(ed.edge, f)){
                        nexts.append(EdgeAtDepth(e, ed.depth))
                    }
                    return nexts
                } else {
                }
            }
            GetUniqueNextEdges(ed, nexts)
            nexts
    }
    Traverse(f, 0, actionAtEdge)
}