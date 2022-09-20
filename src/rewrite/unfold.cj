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
func CopyTentacle(t : Tentacle, vertexMap : HashMap<Vertex, Vertex>) : Vertex {
    let v = t.GetVertex()
    match(vertexMap.get(v)) {
        case Some(w) => w
        case None => v
    }
}
func CopySubgraph(e : Edge) : Option<InterfacedHypergraph> {
    match(e.GetSubgraph()){
        case Some(g) =>
            let (h, _, _) = g.CloneGraph()
            Some(h)
        case None => None<InterfacedHypergraph>
    }
}
/**
 * Perform the 'instant feedback' equation
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
func GetFeedbackMap(f : InterfacedHypergraph) : HashMap<EdgeConnection, Vertex> {
    let sequentialData = f.GetSequentialData()
    let feedbackMap = HashMap<EdgeConnection, Vertex>()
    for(ec in sequentialData.feedbackConnections) {
        feedbackMap.put(ec, ec.edge.GetSource(ec.index).GetVertex())
    }
    feedbackMap
}
func PostUnrollInstantFeedback(
    f : InterfacedHypergraph,
    vertexMap : HashMap<Vertex, Vertex>
) : Unit {
    let sequentialData = f.GetSequentialData()
    // Initialise each feedback connection with a disconnected bottom edge
    for(ec in sequentialData.feedbackConnections) {
        let bot = UseValue(Bottom, ec.GetWidth())
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

public func Unfold(f : InterfacedHypergraph) : Unit {

    let vertexMap = HashMap<Vertex, Vertex>()
    let vertices = HashSet<Vertex>(f.GetVertices())
    let edges = HashSet<Edge>(f.GetEdges())
    let inputVertices = GetInputVertices(f, false)
    CopyVertices(vertices, inputVertices, vertexMap)
    for(e in edges) {
        let newSources = map({t : Tentacle =>
            if(e.GetLabel().IsDelay()) {
                t.GetVertex()
            } else {
                CopyTentacle(t, vertexMap)
            }
        }, e.GetSources())
        let newTargets = map({t : Tentacle => CopyTentacle(t, vertexMap)}, e.GetTargets())
        let subgraph = CopySubgraph(e)
        Edge(e.GetLabel(), newSources, newTargets, subgraph, f.GetGraph())
    }
    ReplaceOutputs(f, vertexMap)
}