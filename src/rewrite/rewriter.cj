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
    // Input vertices don't need to be copied: we just send another tentacle
    // to them. Sequential components are also treated as inputs as when unrolling
    // instant feedback we need the underlying circuit to be combinational
    let inputVertices = HashSet<Vertex>()
    // Delay edges cannot be contained contained within the copied subcircuit
    // as they are sequential in nature. The targets of delay edges are thus
    // treated as inputs external to the copied subcircuit
    for(e in sequentialData.delayEdges) {
        inputVertices.put(e.GetTarget(0).GetVertex())
    }
    // Ditto for value edges, which are also sequential
    for(e in sequentialData.valueEdges) {
        inputVertices.put(e.GetTarget(0).GetVertex())
    }
    // Of course the original inputs vertices are also inputs
    for(v in f.GetInputVertices()){
        inputVertices.put(v.GetVertex())
    }
    // To avoid a concurrency exception, we make a static copy of the
    // edges before we start rewriting
    let workingEdges = HashSet<Edge>(f.GetEdges())
    let feedbackVertexMap = HashMap<Vertex, Vertex>()
    // Three iterations to reach a fixpoint
    let iterations = 3
    // Create a map to keep track of which vertices belonging to the
    // current iteration override vertices in the original graph
    let vertexMap = HashMap<Vertex, Vertex>()
    for(it in 0..(iterations - 1)) {
        // Clear the vertex map so we don't accidentally connect
        // to the previous iteration
        vertexMap.clear()
        // Copy each edge from the original graph
        for(e in workingEdges) {
            match(e.GetLabel()){
                // We don't copy delays or values, as they are sequential components
                case DELAY(_,_) => ()
                case VALUE(_) => ()
                case VALUES(_) => ()
                case _ =>
                    let newSources = mapi({t : Tentacle, i : Int64 =>
                        let v = t.GetVertex()
                        // If we've already dealt with this vertex, just paste it in
                        let w = match(vertexMap.get(v)) {
                            case Some(w) => w
                            case None =>
                                // If this is a feedback tentacle, we want to attach it
                                // to the feedback outputs of the last iteration
                                let newVertex = if(t.feedback){
                                    let v1 = match(feedbackVertexMap.get(v)) {
                                        case Some(w) => w
                                        case None    => v
                                    }
                                    v1
                                // If this is an 'input' vertex, we don't need to make a copy,
                                // instead we can just attach the edge to the original
                                } else if(inputVertices.contains(v)){
                                    v
                                // Otherwise we need to make a new vertex
                                } else {
                                    let w = Vertex(v.GetWidth())
                                    // If another edge refers to the initial vertex
                                    // we don't want to make a new one but rather use
                                    // this existing one
                                    vertexMap.put(v, w)
                                    w
                                }
                                newVertex
                        }
                        Tentacle(w, false)
                    }, e.GetSources())
                    let newTargets = map({t : Tentacle =>
                        let v = t.GetVertex()
                        let currentVertex = match(vertexMap.get(v)) {
                            case Some(w) => w
                            case None =>
                                let w = Vertex(v.GetWidth())
                                // If this vertex has a feedback tentacle connecting to it,
                                // we keep track of it for the next iteration to use
                                for(ec in v.GetOutEdges()) {
                                    if(sequentialData.feedbackConnections.contains(ec)){
                                        feedbackVertexMap.put(v, w)
                                    }
                                }
                                vertexMap.put(v, w)
                                w
                        }
                        Tentacle(currentVertex, false)
                    }, e.GetTargets())
                    // The subgraph can just be whacked in
                    let newSubgraph = match(e.GetSubgraph()){
                        case None => None<InterfacedHypergraph>
                        case Some(g) =>
                            let (newGraph, _, _) = g.CloneGraph()
                            Some(newGraph)
                    }
                    // Finally make the edge
                    let newEdge = Edge(
                        e.GetLabel(),
                        newSources,
                        newTargets,
                        newSubgraph,
                        f.GetGraph()
                    )
            }
        }
    }
    // Set the outputs of the graph to be those created
    // in the final iteration
    for(i in 0..f.GetOutputs()) {
        let v = f.GetOutput(i).GetVertex()
        match(vertexMap.get(v)){
            case Some(w) =>
                f.ReplaceOutput(i, w)
            case None =>
                f.ReplaceOutput(i, v)
        }
    }
    // // Replace the original feedback connections with
    // // bottom edges
    // for(ec in sequentialData.feedbackConnections) {
    //     let e = ec.edge
    //     let v = e.GetSource(ec.index).GetVertex()
    //     let bot = UseValue(Bottom, v.GetWidth())
    //     ec.edge.SetSource(ec.index, bot.GetVertex(), false)
    // }
    // Connect any delay edges to the versions of the sources
    // created in the final iteration
    for(de in sequentialData.delayEdges) {
        let originalVertex = de.GetSource(0).GetVertex()
        match(vertexMap.get(originalVertex)) {
            case Some(v) => de.SetSource(0, v, false)
            case None => ()
        }
    }
}