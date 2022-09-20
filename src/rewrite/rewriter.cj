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
func YankDelays(f : InterfacedHypergraph) : Unit {
    for(e in f.GetSequentialData().delayEdges){
        if(e.GetSource(0).feedback){
            e.RemoveFeedback(0)
        }
        let v = e.GetTarget(0).GetVertex()
        for(ec in v.GetOutEdges()) {
            let e = ec.edge
            let i = ec.index
            let t = e.GetSource(i)
            if(t.feedback) {
                e.RemoveFeedback(i)
            }
        }
    }
}

public func InstantFeedback(f : InterfacedHypergraph) : Unit {
    // If the tentacles adjacent to a delay edge are marked as feedback,
    // we can eliminate this since a delay is already implicitly on a big
    // feedback loop and an additional loop is redundant
    YankDelays(f)
    if(f.GetSequentialData().feedbackConnections.size() != 0) {
        Debug("Non-delay-guarded feedback found, unrolling it...")
        UnrollInstantFeedback(f)
    } else {
        Debug("No non-delay-guarded feedback, skipping instant feedback unrolling...")
    }
}

func UnrollInstantFeedback(f : InterfacedHypergraph) : Unit {
    let sequentialData = f.GetSequentialData()
    let inputVertices = HashSet<Vertex>()
    // Input vertices don't need to be copied, edges can just be connected to them
    for(v in f.GetInputVertices()) {
        inputVertices.put(v.GetVertex())
    }
    // Sequential components (values and delays) are also treated as inputs because when
    // unrolling instant feedback we need the underlying circuit to be combinational:
    // to this end we 'drag' all sequential edges out of the circuit
    for(e in sequentialData.valueEdges) {
        let v = e.GetTarget(0).GetVertex()
        inputVertices.put(v)
    }
    let delayEdges = sequentialData.delayEdges
    let delayMap = HashMap<Edge, Vertex>()
    for(e in delayEdges) {
        let t = e.GetTarget(0)
        let v = t.GetVertex()
        inputVertices.put(v)
        delayMap.put(e, v)
    }
    // We need to keep track of the vertices that will be used in the next iteration
    // as the incoming feedback vertices
    let feedbackConnections = sequentialData.feedbackConnections
    let feedbackMap = HashMap<EdgeConnection, Vertex>()
    for(ec in sequentialData.feedbackConnections) {
        feedbackMap.put(ec, ec.edge.GetSource(ec.index).GetVertex())
    }
    // We need a map to keep track of the most recently copied vertex that corresponds
    // to each vertex in the original graph
    let vertexMap = HashMap<Vertex, Vertex>()
    let vertices = HashSet<Vertex>(f.GetVertices())
    // Only combinational edges are affected by this procedure
    // We make a copy of the set since we'll be adding to the original
    // set during the procedure
    let edges = HashSet<Edge>(sequentialData.combinationalEdges)
    // How many iterations we need to perform in order to guarantee a fixpoint
    // This is the longest chain in the value lattice so if we introduce
    // alternative lattices then this will not be fixed
    let iterations = 3
    for(i in 0..(iterations - 1)) {
        // Any non-input, non-value, non-delay vertex must be copied, we keep track
        // of the original vertex each vertex corresponds to in the vertex map
        for(v in vertices) {
            if(!inputVertices.contains(v)) {
                let w = Vertex(v.GetWidth())
                vertexMap.put(v, w)
            }
        }
        for(e in edges) {
            let newSources = mapi({ t : Tentacle, i : Int64 =>
                let ec = EdgeConnection(e, i, SOURCE)
                // If this was originally feedback, hook it up to
                // the corresponding vertex from the last iteration
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
        // Update the feedback map with the new vertices created in this iteration
        for((ec, v) in feedbackMap){
            match(vertexMap.get(v)) {
                case Some(w) =>
                    feedbackMap.put(ec, w)
                case None => ()
            }
        }
    }
    // Initialise each feedback connection with a disconnected bottom edge
    for(ec in feedbackConnections) {
        let bot = UseValue(Bottom, ec.GetWidth())
        let v = bot.GetVertex()
        ec.edge.SetSource(ec.index, v, false)
    }
    // Set the source of each delay edge to be its latest iteration
    for(e in delayEdges){
        let v = e.GetSource(0).GetVertex()
        match(vertexMap.get(v)){
            case Some(w) => e.SetSource(0, w, false)
            case None => ()
        }
    }
    // Replace each output with its latest iteration
    for(i in 0..f.GetOutputs()) {
        let v = f.GetOutput(i).GetVertex()
        match(vertexMap.get(v)) {
            case Some(w) => f.ReplaceOutput(i, w)
            case None => ()
        }
    }
}