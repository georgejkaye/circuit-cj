/**
 * rewrite/instant.cj
 *
 * Methods for unfolding circuits, either to eliminate
 * 'instant feedback' or to simulate a cycle of the circuit
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

import syntax.*

public func RunCycle(f : InterfacedHypergraph){
    BurstSequentialGraphs(f)
    InstantFeedback(f)
    WriteDotToFile(f, 0, "before-uf")
    Unfold(f)
}

/**
 * 'Burst' edges that have sequential subgraphs. This is because all of the delays
 * in the subgraph must be dealt with separately, and cannot remain in their subgraphs
 *
 * @param f The interfaced hypergraph
 */
func BurstSequentialGraphs(f : InterfacedHypergraph) : Unit {
    var sequentialEdges = f.GetSequentialData().sequentialEdges.size()
    while(sequentialEdges != 0) {
        let edges = HashSet<Edge>(f.GetSequentialData().sequentialEdges)
        for(e in edges) {
            e.BurstSubgraph()
        }
        sequentialEdges = f.GetSequentialData().sequentialEdges.size()
    }
}
/**
 * Remove feedback designations from tentacles immediately
 * adjacent to a delay edge
 *
 * @param f The hypergraph to yank delays from
 */
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
func CopyVertices(
    vertices : HashSet<Vertex>,
    inputVertices : HashSet<Vertex>,
    vertexMap : HashMap<Vertex, Vertex>
) : Unit {
    for(v in vertices) {
        if(!inputVertices.contains(v)) {
            let w = Vertex(v.GetWidth())
            vertexMap.put(v, w)
        }
    }
}
/**
 * Apply the 'instant feedback' equation: when we have feedback loops that
 * are not guarded by a feedback loop, we copy the subcircuit the loop is over
 * a number of times, until we can be sure we have reached a fixpoint.
 * This procedure will only be applied if there is non-delay-guarded feedback
 * present in the circuit.
 *
 * @param f The circuit to replace 'instant feedback' in
 */
func InstantFeedback(f : InterfacedHypergraph) : Unit {
    // If the tentacles adjacent to a delay edge are marked as feedback,
    // we can eliminate this since a delay is already implicitly on a big
    // feedback loop and an additional loop is redundant
    YankDelays(f)
    if(f.HasNonDelayGuardedFeedback()) {
        Debug("Non-delay-guarded feedback found, unrolling it...")
        UnrollInstantFeedback(f)
    } else {
        Debug("No non-delay-guarded feedback, skipping instant feedback unrolling...")
    }
}
/**
 * Based on some vertex map, get the vertex that a copy of a tentacle should
 * attach to.
 *
 * @param t The tentacle
 * @param vertexMap The vertex map
 */
func CopyTentacle(t : Tentacle, vertexMap : HashMap<Vertex, Vertex>) : Vertex {
    let v = t.GetVertex()
    match(vertexMap.get(v)) {
        case Some(w) => w
        case None => v
    }
}
/**
 * Given an edge, either get a copy of its subgraph, or None if there is
 * no such subgraph
 *
 * @param e The edge
 * @return An option potentially containing a copy of the edge's subgraph
 */
func CopySubgraph(e : Edge) : Option<InterfacedHypergraph> {
    match(e.GetSubgraph()){
        case Some(g) =>
            let (h, _, _) = g.CloneGraph()
            Some(h)
        case None => None<InterfacedHypergraph>
    }
}
/**
 * Perform the 'instant feedback' equation. The underlying combinational circuit
 * is copied some number of times (for the usual lattice it is 3) and the feedback
 * inputs and outputs chained together. The first feedback input is initialised with
 * a bottom signal, and thus a least fixed point is computed.
 *
 * @param f The circuit to replace 'instant feedback' in
 */
func UnrollInstantFeedback(f : InterfacedHypergraph) : Unit {
    // How many iterations we need to perform in order to guarantee a fixpoint
    // This is the longest chain in the value lattice so if we introduce
    // alternative lattices then this will not be fixed
    let iterations = 3
    // The 'input vertices' to the combinational subcircuit are the original inputs,
    // and targets of sequential components i.e. values and delays
    let inputVertices = GetInputVertices(f, true)
    // A 'feedback map' needs to be constructed so that we know which vertex of
    // the previous iteration to hook each feedback loop to
    let feedbackMap = GetFeedbackMap(f)
    // We need a map to keep track of the most recently copied vertex that corresponds
    // to each vertex in the original graph
    let vertexMap = HashMap<Vertex, Vertex>()
    // We will be adding elements to the graph so we need a static copy to iterate over
    let vertices = HashSet<Vertex>(f.GetVertices())
    let edges = HashSet<Edge>(f.GetSequentialData().combinationalEdges)
    for(i in 0..(iterations - 1)) {
        // Any non-input, non-value, non-delay vertex must be copied, we keep track
        // of the original vertex each vertex corresponds to in the vertex map
        CopyVertices(vertices, inputVertices, vertexMap)
        for(e in edges) {
            // Source tentacles can be marked as 'feedback' tentacles: if
            // this is the case then we need to connect it to the corresponding
            // vertex from the previous iteration
            let newSources = mapi({ t : Tentacle, i : Int64 =>
                let ec = EdgeConnection(e, i, SOURCE)
                match(feedbackMap.get(ec)){
                    // If this was originally feedback, hook it up to
                    // the corresponding vertex from the last iteration
                    case Some(v) => v
                    // Otherwise just use the map
                    case None => CopyTentacle(t, vertexMap)

                }
            }, e.GetSources())
            // Targets are less complicated, just map them to the
            // corresponding vertex in this iteration
            let newTargets = map({ t : Tentacle => CopyTentacle(t, vertexMap)}, e.GetTargets())
            let subgraph = CopySubgraph(e)
            // Finally create the edge
            Edge(e.GetLabel(), newSources, newTargets, subgraph, f.GetGraph())
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
    PostUnrollInstantFeedback(f, vertexMap)
}
/**
 * Get the 'input vertices' when performing a global rewrite of an entire graph
 * These input vertices of course include the inputs of the graph, but can also
 * include the targets of delays and values if we are rewriting combinationally
 *
 * @param f The interfaced hypergraph
 * @param sequential Whether to include delay and value edges
 */
func GetInputVertices(f : InterfacedHypergraph, sequential : Bool) : HashSet<Vertex> {
    let sequentialData = f.GetSequentialData()
    let inputVertices = HashSet<Vertex>()
    // Input vertices don't need to be copied, edges can just be connected to them
    for(v in f.GetInputVertices()) {
        inputVertices.put(v.GetVertex())
    }
    // If desired, sequential components (values and delays) can be treated as inputs:
    // for example, when  unrolling instant feedback we need the underlying circuit to
    // be combinational so we 'drag' all sequential edges out of the circuit
    if(sequential) {
        for(e in sequentialData.valueEdges) {
            let v = e.GetTarget(0).GetVertex()
            inputVertices.put(v)
        }
        for(e in sequentialData.delayEdges) {
            let t = e.GetTarget(0)
            let v = t.GetVertex()
            inputVertices.put(v)
        }
    }
    inputVertices
}
/**
 * Populate a map from edge connections to vertices, representing where the feedback
 * connections in a graph currently connect to
 *
 * @param f The interfaced hypergraph
 */
func GetFeedbackMap(f : InterfacedHypergraph) : HashMap<EdgeConnection, Vertex> {
    let sequentialData = f.GetSequentialData()
    let feedbackMap = HashMap<EdgeConnection, Vertex>()
    for(ec in sequentialData.feedbackConnections) {
        feedbackMap.put(ec, ec.edge.GetSource(ec.index).GetVertex())
    }
    feedbackMap
}
/**
 * Operations to apply after unrolling instant feedback.
 * 1) 'Initialise' each feedback connection with a bottom signal
 * 2) Set each delay edge to connect to the last unrolling
 * 3) Replace each output with its latest iteration
 *
 * @param f The interfaced hypergraph
 * @param vertexMap The vertex map
 */
func PostUnrollInstantFeedback(
    f : InterfacedHypergraph,
    vertexMap : HashMap<Vertex, Vertex>
) : Unit {
    let sequentialData = f.GetSequentialData()
    // Initialise each feedback connection with a disconnected bottom edge
    for(ec in sequentialData.feedbackConnections) {
        let bot = UseSignal(Bottom, ec.GetWidth())
        let v = bot.GetVertex()
        ec.edge.SetSource(ec.index, v, false)
    }
    // Set the source of each delay edge to be its latest iteration
    for(e in sequentialData.delayEdges){
        let v = e.GetSource(0).GetVertex()
        match(vertexMap.get(v)){
            case Some(w) => e.SetSource(0, w, false)
            case None => ()
        }
    }
    ReplaceOutputs(f, vertexMap)
}
/**
 * After performing an operation that involves populating a vertex map, replace the
 * output vertices in an interfaced hypergraph with the new ones
 *
 * @param f The interfaced hypergraph to update
 * @param vertexMap the vertex map
 */
func ReplaceOutputs(f : InterfacedHypergraph, vertexMap : HashMap<Vertex,Vertex>) : Unit {
    // Replace each output with its latest iteration
    for(i in 0..f.GetOutputs()) {
        let v = f.GetOutput(i).GetVertex()
        match(vertexMap.get(v)) {
            case Some(w) => f.ReplaceOutput(i, w)
            case None => ()
        }
    }
}
func MakeCopy(
    f : InterfacedHypergraph,
    vertices : HashSet<Vertex>,
    inputVertices : HashSet<Vertex>,
    vertexMap : HashMap<Vertex, Vertex>,
    edges : HashSet<Edge>,
    now : Bool
) : Unit {
    CopyVertices(vertices, inputVertices, vertexMap)
    for(e in edges) {
        let label = e.GetLabel()
        if(!now && label.IsDelay()){
            let originalSource = e.GetSource(0).GetVertex()
            let originalTarget = e.GetTarget(0).GetVertex()
            let currentTarget = match(vertexMap.get(originalTarget)){
                case Some(v) => v
                case None => originalTarget
            }
            MergeVertices(originalSource, currentTarget, false)
            vertexMap.put(originalTarget, originalSource)
            ()
        } else {
            let (newSources, newTargets, newLabel) =
                if(now && label.IsDelay() || !now && label.IsValue()) {
                    let sources = Array<Vertex>()
                    let targets = map({t : Tentacle => CopyTentacle(t, vertexMap)}, e.GetTargets())
                    let botLabel = GetSignalLabel(Bottom, label.GetOutputPorts()[0].GetWidth())
                    (sources, targets, botLabel)
                } else {
                    let sources = map({t : Tentacle =>
                        if(e.GetLabel().IsDelay()) {
                            t.GetVertex()
                        } else {
                            CopyTentacle(t, vertexMap)
                        }
                    }, e.GetSources())
                    let targets = map({t : Tentacle => CopyTentacle(t, vertexMap)}, e.GetTargets())
                    (sources, targets, label)
                }
            let subgraph = CopySubgraph(e)
            Edge(newLabel, newSources, newTargets, subgraph, f.GetGraph())
            ()
        }
    }
}
/**
 * Unfold an interfaced hypergraph with no non-delay-guarded feedback.
 * View the graph in a form in which the delay guarded feedback is all
 * 'global feedback', then copy the underlying circuit so one copy has
 * no feedback.
 *
 * @param f The interfaced hypergraph to unfold
 */
func Unfold(f : InterfacedHypergraph) : Unit {
    if(f.HasNonDelayGuardedFeedback()) {
        Debug("Cannot unfold circuits with non-delay-guarded feedback, please unroll it first")
    } else {
        let vertices = HashSet<Vertex>(f.GetVertices())
        let edges = HashSet<Edge>(f.GetEdges())
        let inputVertices = GetInputVertices(f, false)
        // Make a copy for what is happening 'now'
        // Replace any delays with bottom values
        let nowVertexMap = HashMap<Vertex, Vertex>()
        MakeCopy(f, vertices, inputVertices, nowVertexMap, edges, true)
        // Make a copy for what is happening 'later'
        // Replace any values with bottom values and remove any delays
        // The output of the later copy will be delayed instead
        let laterVertexMap = HashMap<Vertex, Vertex>()
        MakeCopy(f, vertices, inputVertices, laterVertexMap, edges, false)
        // Update the outputs by joining the outputs of the two copies
        let outputs = Array<InterfaceVertex>(f.GetOutputVertices())
        for(i in 0..outputs.size()){
            let v = outputs[i].GetVertex()
            let width = v.GetWidth()
            // Get the corresponding output from the now circuit
            let nowOutput = nowVertexMap[v]
            // Get the corresponding output from the later circuit
            let laterOutput = laterVertexMap[v]
            // The later source must be delayed to make it truly 'later'
            let delayTarget = Vertex(width)
            let delayEdge = Edge(DELAY(width), [laterOutput], [delayTarget], None<InterfacedHypergraph>, f.GetGraph())
            let joinTarget = Vertex(width)
            let joinEdge = Edge(JOIN(width), [nowOutput, delayTarget], [joinTarget], None<InterfacedHypergraph>, f.GetGraph())
            f.ReplaceOutput(i, joinTarget)
        }
    }
}