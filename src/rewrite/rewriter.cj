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
    let sequentialData = f.GetSequentialData()
    let feedbackPorts = sequentialData.feedbackConnections
    let combinationalEdges = sequentialData.combinationalEdges
    let vertexMap = HashMap<Vertex, Vertex>()
    let feedbackPairs = HashMap<Vertex, Vertex>()
    let delayPairs = HashMap<Vertex, Vertex>()
    let newVertices = HashSet<Vertex>()
    newVertices.putAll(f.GetVertices())
    let newEdges = HashSet<Edge>()
    newEdges.putAll(f.GetEdges())

    let inputVertices = HashSet<Vertex>()
    for(e in sequentialData.delayEdges) {
        inputVertices.put(e.GetTarget(0).GetVertex())
    }
    for(e in sequentialData.valueEdges) {
        inputVertices.put(e.GetTarget(0).GetVertex())
    }
    for(v in f.GetInputVertices()){
        inputVertices.put(v.GetVertex())
    }
    let feedbackConnections = HashSet<EdgeConnection>()
    feedbackConnections.putAll(feedbackPorts)
    let workingEdges = HashSet<Edge>(f.GetEdges())

    for(e in workingEdges) {
        match(e.GetLabel()){
            // We don't copy delays or values, as they are sequential components
            case DELAY(_,_) => ()
            case VALUE(_) => ()
            case VALUES(_) => ()
            // For everything else we copy the edge
            // If the vertex would have connected to a sequential component,
            // we
            case _ =>
                let newSources = map({
                        t : Tentacle =>
                            let v = t.GetVertex()
                            if(inputVertices.contains(v)){
                                v
                            } else if(t.GetFeedback()) {
                                match(vertexMap.get(v)) {
                                    case Some(w) => w
                                    case None => v
                                }
                            } else {
                                match(vertexMap.get(v)){
                                    case Some(w) => w
                                    case None    =>
                                        let w = Vertex(v.GetWidth())
                                        vertexMap.put(v, w)
                                        w
                                }
                            }
                }, e.GetSources())
                let newTargets = map({
                        t : Tentacle =>
                            let v = t.GetVertex()
                            match(vertexMap.get(v)) {
                                case Some(w) => w
                                case None =>
                                    let w = Vertex(v.GetWidth())
                                    vertexMap.put(v, w)
                                    w
                            }
                }, e.GetTargets())
                let newSubgraph = match(e.GetSubgraph()){
                    case None => None<InterfacedHypergraph>
                    case Some(g) =>
                        let (newGraph, _, _) = g.CloneGraph()
                        Some(newGraph)
                }
                let newEdge = Edge(
                    e.GetLabel(),
                    newSources,
                    newTargets,
                    newSubgraph
                )
                f.AddEdgeAndVertices(newEdge)
        }
    }
}