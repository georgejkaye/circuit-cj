/**
 * rewrite/global.cj
 *
 * Global rewrites of a circuit
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

import syntax.*
import components.*

public class Rewriter<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    var nextCycle = 0
    public Rewriter(
        let signature : Signature<V, G>,
        let f : InterfacedHypergraph<V, G>
    ){}
    public func RunNextCycle(tidyNext : Bool) : Unit {
        RunCycle(f, nextCycle, tidyNext)
        nextCycle++
    }
    public func RunCycle(f : InterfacedHypergraph<V, G>, cycle : Int64, tidyNext : Bool) : Unit {
        AssertNonNegative(cycle)
        Debug("Running cycle ${cycle} on ${f.GetName()}")
        // This graph may be prefixed by some waveform: we will need to remove
        // this to deal with the
        match(CheckForHead(f)) {
            case Some(later) => RunCycle(later, cycle - 1, tidyNext)
            case None =>
                BurstSequentialGraphs(f)
                // Eliminate 'instant feedback' by copying the circuit some
                // number of times. If there is no instant feedback, skips this step
                InstantFeedback(signature, f)
                // Unfold and stream the circuit, so that we have a combinational
                // circuit for what is happening 'now', and some subcircuit that
                // contains what is happening 'later'
                let nowStartingEdges = Unfold(signature, f)
                // Exhaustively rewrite the now subcircuit: this is guaranteed
                // to terminate in a signal, the output of the current cycle
                RewriteCombinational(signature, GetRules(signature, true), f, nowStartingEdges)
                // If this was a closed circuit, then there will be an instantaneous
                // value and a delayed subcircuit at the 'head' of the circuit. We
                // collapse this into a register for ease of viewing
                CreateHeadRegisters(f)
                // If desired, we can also tidy up the later subcircuit
                if(tidyNext) {
                    let allStartingEdges = ArrayList<Edge<V, G>>()
                    for(e in f.GetSequentialData().valueEdges){
                        allStartingEdges.append(e)
                    }
                    for(e in f.GetSequentialData().delayEdges){
                        allStartingEdges.append(e)
                    }
                    RewriteCombinational(signature, GetRules(signature, false), f, allStartingEdges)
                }
                let later = CollapseNext(f)
                if(cycle > 0) {
                    RunCycle(later, cycle - 1, tidyNext)
                }
        }
    }
}
func CheckForHead<V, G>(f : InterfacedHypergraph<V, G>) : Option<InterfacedHypergraph<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    for(iv in f.GetOutputs()) {
        match(iv.GetVertex().GetInEdge()) {
            case None => return None<InterfacedHypergraph<V, G>>
            case Some(ec) => if(!ec.edge.GetLabel().IsRegister()){
                return None<InterfacedHypergraph<V, G>>
            }
        }
    }
    Some<InterfacedHypergraph<V, G>>(f.GetOutput(0).GetVertex().GetInEdge().getOrThrow().edge.GetSource(0).vertex.GetInEdge().getOrThrow().edge.GetSubgraph().getOrThrow())
}
/**
 * 'Burst' edges that have sequential subgraphs. This is because all of the delays
 * in the subgraph must be dealt with separately, and cannot remain in their subgraphs
 *
 * @param f The interfaced hypergraph
 */
func BurstSequentialGraphs<V, G>(f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    var sequentialEdges = f.GetSequentialData().sequentialEdges.size
    while(sequentialEdges != 0) {
        let edges = HashSet<Edge<V, G>>(f.GetSequentialData().sequentialEdges)
        for(e in edges) {
            e.BurstSubgraph()
        }
        sequentialEdges = f.GetSequentialData().sequentialEdges.size
    }
}
/**
 * Remove feedback designations from tentacles immediately
 * adjacent to a delay edge
 *
 * @param f The hypergraph to yank delays from
 */
func YankDelays<V, G>(f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    // We need to check all the delay edges to see if their
    // source or target is designated as a feedback tentacle
    for(e in f.GetSequentialData().delayEdges){
        if(e.GetSource(0).feedback){
            e.RemoveFeedback(0)
        }
        let v = e.GetTarget(0).GetVertex()
        // There may be many target tentacles
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
/**
 * Given a set of vertices, make copies of the ones not contained
 * in some other set, updating a vertex map
 *
 * @param vertices The set of vertices
 * @param exceptions The set of vertices not to copy
 * @param vertexMap The vertex map to update
 */
func CopyVertices<V, G>(
    vertices : HashSet<Vertex<V, G>>,
    exceptions : HashSet<Vertex<V, G>>,
    vertexMap : HashMap<Vertex<V, G>, Vertex<V, G>>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    for(v in vertices) {
        if(!exceptions.contains(v)) {
            let w = Vertex<V, G>(v.GetWidth())
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
func InstantFeedback<V, G>(signature : Signature<V, G>, f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    // If the tentacles adjacent to a delay edge are marked as feedback,
    // we can eliminate this since a delay is already implicitly on a big
    // feedback loop and an additional loop is redundant
    YankDelays(f)
    // If there is no non-delay-guarded feedback (which is common), there is
    // no need waste time and copy all the graph
    if(f.HasNonDelayGuardedFeedback()) {
        Debug("Non-delay-guarded feedback found, unrolling it...")
        UnrollInstantFeedback(signature, f)
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
func CopyTentacle<V, G>(
    t : Tentacle<V, G>,
    vertexMap : HashMap<Vertex<V, G>, Vertex<V, G>>
) : Vertex<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
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
func CopySubgraph<V, G>(e : Edge<V, G>) : Option<InterfacedHypergraph<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    match(e.GetSubgraph()){
        case Some(g) =>
            let (h, _, _) = g.CloneGraph()
            Some(h)
        case None => None<InterfacedHypergraph<V, G>>
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
func UnrollInstantFeedback<V, G>(signature : Signature<V, G>, f : InterfacedHypergraph<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    // The 'input vertices' to the combinational subcircuit are the original inputs,
    // and targets of sequential components i.e. values and delays
    let inputVertices = GetInputs(f, true)
    // A 'feedback map' needs to be constructed so that we know which vertex of
    // the previous iteration to hook each feedback loop to
    let feedbackMap = GetFeedbackMap(f)
    // We need a map to keep track of the most recently copied vertex that corresponds
    // to each vertex in the original graph
    let vertexMap = HashMap<Vertex<V, G>, Vertex<V, G>>()
    // We will be adding elements to the graph so we need a static copy to iterate over
    let vertices = HashSet<Vertex<V, G>>(f.GetVertices())
    let edges = HashSet<Edge<V, G>>(f.GetSequentialData().combinationalEdges)
    // How many iterations we need to perform in order to guarantee a fixpoint
    // This is the longest chain in the value lattice so if we introduce
    // alternative lattices then this will not be fixed
    let iterations = signature.GetLongestChain(feedbackMap.size) + 1
    for(i in 0..(iterations - 1)) {
        // Any non-input, non-value, non-delay vertex must be copied, we keep track
        // of the original vertex each vertex corresponds to in the vertex map
        CopyVertices(vertices, inputVertices, vertexMap)
        for(e in edges) {
            // Source tentacles can be marked as 'feedback' tentacles: if
            // this is the case then we need to connect it to the corresponding
            // vertex from the previous iteration
            let newSources = mapi({ t : Tentacle<V, G>, i : Int64 =>
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
            let newTargets = map({ t : Tentacle<V, G> => CopyTentacle(t, vertexMap)}, e.GetTargets())
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
    PostUnrollInstantFeedback(signature, f, vertexMap)
}
/**
 * Get the 'input vertices' when performing a global rewrite of an entire graph
 * These input vertices of course include the inputs of the graph, but can also
 * include the targets of delays and values if we are rewriting combinationally
 *
 * @param f The interfaced hypergraph
 * @param sequential Whether to include delay and value edges
 */
func GetInputs<V, G>(f : InterfacedHypergraph<V, G>, sequential : Bool) : HashSet<Vertex<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let sequentialData = f.GetSequentialData()
    let inputVertices = HashSet<Vertex<V, G>>()
    // Input vertices don't need to be copied, edges can just be connected to them
    for(v in f.GetInputs()) {
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
func GetFeedbackMap<V, G>(f : InterfacedHypergraph<V, G>) : HashMap<EdgeConnection<V, G>, Vertex<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let sequentialData = f.GetSequentialData()
    let feedbackMap = HashMap<EdgeConnection<V, G>, Vertex<V, G>>()
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
func PostUnrollInstantFeedback<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    vertexMap : HashMap<Vertex<V, G>, Vertex<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let sequentialData = f.GetSequentialData()
    // Initialise each feedback connection with a disconnected bottom edge
    for(ec in sequentialData.feedbackConnections) {
        let bot = signature.UseSignal(signature.GetBottom(), ec.GetWidth())
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
func ReplaceOutputs<V, G>(
    f : InterfacedHypergraph<V, G>,
    vertexMap : HashMap<Vertex<V, G>, Vertex<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    // Replace each output with its latest iteration
    for(i in 0..f.GetCoarity()) {
        let v = f.GetOutput(i).GetVertex()
        match(vertexMap.get(v)) {
            case Some(w) => f.ReplaceOutput(i, w)
            case None => ()
        }
    }
}
/**
 * Make a copy of a graph as part of the 'streaming' step of rewriting.
 * Depending on a flag, can either be a 'now' graph in which all delayed
 * inputs are replaced by bottom calues, or a 'later' graph in which all
 * instant values are replaced by bottom values
 *
 * @param signature     The signature we are working with
 * @param f             The parent graph
 * @param vertices      The set of vertices to copy
 * @param inputVertices The 'input vertices' of the underlying combinational graph
 * @param vertexMap     The map of vertices to copies
 * @param edges         The set of edges to copy
 * @param now           Whether this copy is for 'now' or 'later'
 * @param startingEdges An optional arraylist of edges to contain the 'starting edges':
                            the values and inputs of this graph
*/
func MakeCopy<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    vertices : HashSet<Vertex<V, G>>,
    inputVertices : HashSet<Vertex<V, G>>,
    vertexMap : HashMap<Vertex<V, G>, Vertex<V, G>>,
    edges : HashSet<Edge<V, G>>,
    now : Bool,
    startingEdges : Option<HashSet<TraversalElement<V, G>>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    CopyVertices(vertices, inputVertices, vertexMap)
    for(e in edges) {
        let label = e.GetLabel()
        // If this edge is a delay and we are making a later graph,
        // we copy the delay
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
            let newEdge =
                // If this is a now graph, we replace delays with bottoms
                // If this is a later graph, we replace values with bottoms
                if(now && label.IsDelay() || !now && label.IsValue()) {
                    let sources = Array<Vertex<V, G>>()
                    let targets = map({t : Tentacle<V, G> => CopyTentacle(t, vertexMap)}, e.GetTargets())
                    let signal = signature.MakeSignal(Signal(signature.GetBottom(), label.GetOutputPorts()[0].GetWidth()))
                    Edge(signal.GetLabel(), Array<Vertex<V, G>>(), targets, signal, f.GetGraph())
                // Otherwise we just copy the sources and targets as usual
                } else {
                    let sources = map({t : Tentacle<V, G> =>
                        if(e.GetLabel().IsDelay()) {
                            t.GetVertex()
                        } else {
                            CopyTentacle(t, vertexMap)
                        }
                    }, e.GetSources())
                    let targets = map({t : Tentacle<V, G> => CopyTentacle(t, vertexMap)}, e.GetTargets())
                    let ed = Edge(label, sources, targets, CopySubgraph(e), f.GetGraph())
                    ed
                }
            // If the new edge is a value, then it is a starting edge for traversing this graph
            if(newEdge.GetLabel().IsValue()){
                match(startingEdges){
                    case Some(es) => es.put(EDGE(newEdge))
                    case None => ()
                }
            }
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
func Unfold<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>
) : HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let startingEdges = HashSet<TraversalElement<V, G>>()
    // We can only safely unfold graphs with delay-guarded feedback
    if(f.HasNonDelayGuardedFeedback()) {
        Debug("Cannot unfold circuits with non-delay-guarded feedback, please unroll it first")
    } else if (f.GetSequentialData().delayEdges.size == 0) {
        Debug("No need to unfold circuits with no delay")
        for(e in f.GetSequentialData().valueEdges) {
            startingEdges.put(EDGE(e))
        }
    } else {
        let vertices = HashSet<Vertex<V, G>>(f.GetVertices())
        let edges = HashSet<Edge<V, G>>(f.GetEdges())
        let inputVertices = GetInputs(f, false)
        // Make a copy for what is happening 'now'
        // Replace any delays with bottom values
        let nowVertexMap = HashMap<Vertex<V, G>, Vertex<V, G>>()
        MakeCopy(signature, f, vertices, inputVertices, nowVertexMap, edges, true, startingEdges)
        // Make a copy for what is happening 'later'
        // Replace any values with bottom values and remove any delays
        // The output of the later copy will be delayed instead
        let laterVertexMap = HashMap<Vertex<V, G>, Vertex<V, G>>()
        MakeCopy(
            signature,
            f,
            vertices,
            inputVertices,
            laterVertexMap,
            edges,
            false,
            None<HashSet<TraversalElement<V, G>>>
        )
        // Update the outputs by joining the outputs of the two copies
        let outputs = Array<InterfaceVertex<V, G>>(f.GetOutputs())
        for(i in 0..outputs.size){
            let v = outputs[i].GetVertex()
            let width = v.GetWidth()
            // Get the corresponding output from the now circuit
            let nowOutput = nowVertexMap[v]
            // Get the corresponding output from the later circuit
            let laterOutput = laterVertexMap[v]
            // The later source must be delayed to make it truly 'later'
            let delayTarget = Vertex<V, G>(width)
            let delayEdge = Edge(
                DELAY(width),
                [laterOutput],
                [delayTarget],
                None<InterfacedHypergraph<V, G>>,
                f.GetGraph()
            )
            let joinTarget = Vertex<V, G>(width)
            let joinEdge = Edge(
                JOIN(width),
                [nowOutput, delayTarget],
                [joinTarget],
                None<InterfacedHypergraph<V, G>>,
                f.GetGraph()
            )
            f.ReplaceOutput(i, joinTarget)
        }
    }
    startingEdges
}
func CreateHeadRegisters<V, G>(f : InterfacedHypergraph<V, G>) : Unit
        where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    var i = 0
    for(iv in f.GetOutputs()) {
        i++
        let v = iv.vertex
        let width = v.GetWidth()
        // We are assuming this has been successfully rewritten
        // so its head is a join with a signal as its left arg and
        // a delay as its right arg
        let joinEdge = v.GetInEdge().getOrThrow().edge
        let oldJoinTarget = v
        // The signal is the left arg of the join
        let signalEdge = joinEdge.NextEdgeLeft(0)
        let signal = signalEdge.GetLabel().GetSignal()
        // The delay is the right arg of the join
        let delayEdge = joinEdge.NextEdgeLeft(1)
        f.GetGraph().CollapseSubgraph([SOURCE(delayEdge, 0)], [TARGET(joinEdge, 0)], Label<V, G>.REGISTER(signal))
    }
}
func CollapseNext<V, G>(f : InterfacedHypergraph<V, G>) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let laterOutputs = map(
        {iv : InterfaceVertex<V, G> =>
            let registerEdge = iv.GetVertex().GetInEdge().getOrThrow().edge
            SOURCE(registerEdge, 0)
        },
        f.GetOutputs()
    )
    f.GetGraph().CollapseSubgraph(Array<TentacleOrigin<V, G>>(), laterOutputs, COMPOSITE(Specification(
        "later",
        Array<Port<V>>(),
        map({ iv => Port<V>(iv.GetWidth()) }, f.GetOutputs())
    )))
    f.GetOutput(0).vertex.GetInEdge().getOrThrow().edge.GetSource(0).vertex.GetInEdge().getOrThrow().edge.GetSubgraph().getOrThrow()
}