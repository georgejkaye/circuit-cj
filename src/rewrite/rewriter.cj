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

public func InstantFeedback(f : InterfacedHypergraph) : Unit {
    println(f.toLongString())
    let sequentialData = f.GetSequentialData()
    // Input vertices don't need to be copied: we just send another tentacle
    // to them. Sequential components are also treated as inputs as when unrolling
    // instant feedback we need the underlying circuit to be combinational
    let inputVertices = HashSet<Vertex>()
    for(e in sequentialData.delayEdges) {
        let v = e.GetTarget(0).GetVertex()
        inputVertices.put(v)
    }
    for(e in sequentialData.valueEdges) {
        let v = e.GetTarget(0).GetVertex()
        inputVertices.put(v)
    }
    let feedbackMap = HashMap<EdgeConnection, Vertex>()
    let feedbackConnections = HashSet<EdgeConnection>(sequentialData.feedbackConnections)
    for(ec in feedbackConnections) {
        let v = if(ec.edge.GetLabel().IsDelay())
        let bot = UseValue(Bottom, ec.GetWidth())
        feedbackMap.put(ec, bot.GetVertex())
    }
    let iterations = 3
    let vertexMap = HashMap<Vertex, Vertex>()
    let vertices = HashSet<Vertex>(f.GetVertices())
    let edges = HashSet<Edge>(sequentialData.combinationalEdges)
    for(i in 0..(iterations - 1)) {
        vertexMap.clear()
        for(v in vertices) {
            if(!inputVertices.contains(v)) {
                let w = Vertex(v.GetWidth())
                vertexMap.put(v, w)
            }
        }
    }


}