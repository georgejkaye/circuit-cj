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

func GetFeedbackPorts(f : Hypergraph) : ArrayList<EdgeConnection> {
    let connections = ArrayList<EdgeConnection>()
    for(e in f.GetEdges()){
        for(i in 0..e.GetSources().size()) {
            let t = e.GetSource(i)
            if(t.feedback){
                connections.append(EdgeConnection(e, i, SOURCE))
            }
        }
    }
    connections
}

public func InstantFeedback(f : InterfacedHypergraph) : Unit {
    let feedbackPorts = GetFeedbackPorts(f.GetGraph())
    for(p in feedbackPorts) {
        let disconnect = BottomSignal()
        let e = p.edge
        e.SetSource(p.index, disconnect.GetVertex(), false)
    }
    // let numberOfCopies = 3
    // let copies = Array<(InterfacedHypergraph, HashMap<Edge,Edge>)>(numberOfCopies - 1, {
    //     i : Int64 =>
    //         let (graph, _, edgeMap) = f.CloneGraph()
    //         (graph, edgeMap)
    // })
}