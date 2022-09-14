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
    for(e in sequentialData.valueEdges) {
        let v = e.GetTarget(0).GetVertex()
        inputVertices.put(v)
    }
    let feedbackMap = HashMap<EdgeConnection, Vertex>()
    let feedbackConnections = HashSet<EdgeConnection>(sequentialData.feedbackConnections)
    let delayEdges = HashSet<Edge>(sequentialData.delayEdges)
    println(feedbackConnections)
    for(ec in feedbackConnections) {
        println("init ${ec}")
        let bot = UseValue(Bottom, ec.GetWidth())
        feedbackMap.put(ec, bot.GetVertex())
    }
    let delayMap = HashMap<Edge, Vertex>()
    for(e in sequentialData.delayEdges) {
        let t = e.GetTarget(0)
        let v = t.GetVertex()
        inputVertices.put(v)
        let ec = EdgeConnection(e, 0, SOURCE)
        match(feedbackMap.get(ec)) {
            case Some(w) => w
            case None => v
        }

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
        for(e in edges) {
            let newSources = mapi({ t : Tentacle, i : Int64 =>
                let ec = EdgeConnection(e, i, SOURCE)
                println("iteration ${i}: ${ec}")
                match(feedbackMap.get(ec)){
                    case Some(v) => v
                    case None =>
                        let v = t.GetVertex()
                        match(vertexMap.get(v)) {
                            case Some(w) => w
                            case None => v
                        }
                }
            }, e.GetSources())
            let newTargets = map({ t : Tentacle =>
                let v = t.GetVertex()
                match(vertexMap.get(v)) {
                    case Some(w) => w
                    case None => v
                }
            }, e.GetTargets())
            let subgraph = match(e.GetSubgraph()){
                case Some(g) =>
                    let (h, _, _) = g.CloneGraph()
                    Some(h)
                case None => None<InterfacedHypergraph>
            }
            Edge(
                e.GetLabel(),
                newSources,
                newTargets,
                subgraph,
                f.GetGraph()
            )
        }
        for(e in delayEdges){
            let t = e.GetSource(0)
            let ec = EdgeConnection(e, 0, SOURCE)
            match(delayMap.get(e)) {
                case Some(v) => e.SetSource(0, v, false)
                case None => ()
            }
        }
    }
}