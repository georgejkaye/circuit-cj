/**
 * rewrite/transform.cj
 *
 * Functions for transforming an arbitrary circuit into a form the evaluator
 * can reason with.
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite

////////////////////////////////////////////////////////////////////////////////
//                      Conversion to Mealy form                              //
////////////////////////////////////////////////////////////////////////////////

/**
 * Given an edge (which is assumed to either be a value or a delay),
 * transform it into a register. For values, this means joining with
 * a delay; for delays this means joining with a bottom signal.
 *
 * @param sig The signature we are working in
 * @param e The edge to transform
 * @param f The interfaced hypergraph we are working in
 * @param delays Whether this edge is a delay or not
 * @return A tuple with
 *              0) the TentacleOrigin of the target of the
 *                 register
 *              1) the TentacleOrigin of the source of the
 *                 register
 *              2) The signal contained within this register
 *              3) The vertex connected to the value of this
 *                 register
 */
func MakeRegisterJoin<V, G>(
    sig : Signature<V, G>, e : Edge<V, G>, f : InterfacedHypergraph<V, G>
) : (Edge<V, G>, Edge<V, G>, Signal<V>, Vertex<V, G>)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // We can only turn a delay or a value into a register
    let isDelay = e.GetLabel().IsDelay()
    let IsSignal = e.GetLabel().IsSignal()
    if(!isDelay && !IsSignal) {
        throw IncompatibleVariantException(e.GetLabel(), "DELAY/VALUE")
    }
    let target = e.GetTarget(0)
    let width = target.GetWidth()
    let (leftVertex, rightVertex) = target.SplitVertex()
    let bot = sig.UseSignal(sig.GetBottom(), width)
    let (valueTarget, delayTarget, delayEdge, signal) = if(isDelay) {
        (bot.GetVertex(), leftVertex, e, Signal(sig.GetBottom(), width))
    } else {
        let newVertex = f.GetGraph().AddNewVertex(width)
        let delayEdge = Edge(
            DELAY(width), [bot.GetVertex()],[newVertex], None, f.GetGraph()
        )
        (leftVertex, newVertex, delayEdge, e.GetLabel().GetSignal())
    }
    let joinEdge = Edge(
        Label<V, G>.JOIN(width), [valueTarget, delayTarget],
        [rightVertex], None<InterfacedHypergraph<V, G>>, f.GetGraph()
    )
    (joinEdge, delayEdge, signal, valueTarget)
}
/**
 * Convert a circuit to Mealy form, in which there is a `combinational core'
 * with inputs registers and the original inputs of the graph, and outputs
 * the registers and the original outputs of the graph.
 *
 * @param sig The signature
 * @param f The interfaced hypergraph to convert
 * @return A tuple of the combinational graph, the edge for the core, and
 *               the array of signals of the registers (the 'state')
 */
func ConvertToMealyForm<V, G>(
    sig : Signature<V, G>, f : InterfacedHypergraph<V, G>
) : (InterfacedHypergraph<V, G>, Edge<V, G>, Int64)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let valueEdges = HashSet(f.GetValueEdges())
    let delayEdges = HashSet(f.GetDelayEdges())
    let coreInputs = ArrayList<TentacleOrigin<V, G>>()
    let coreOutputs = ArrayList<TentacleOrigin<V, G>>()
    let state = ArrayList<Signal<V>>()
    let values = ArrayList<Vertex<V, G>>()
    func GetInputAndOutput(e : Edge<V, G>) {
        let (joinEdge, delayEdge, signal, value) = MakeRegisterJoin(sig, e, f)
        coreInputs.append(FROM_EDGE(EdgeConnection(joinEdge, 0, TARGET)))
        coreOutputs.append(FROM_EDGE(EdgeConnection(delayEdge, 0, SOURCE)))
        state.append(signal)
        values.append(value)
    }
    for(e in delayEdges) {
        GetInputAndOutput(e)
    }
    for(e in valueEdges) {
        GetInputAndOutput(e)
    }
    for(v in f.GetInputs()) {
        coreInputs.append(FROM_VERTEX(v.GetVertex()))
    }
    for(v in f.GetOutputs()) {
        coreOutputs.append(FROM_VERTEX(v.GetVertex()))
    }
    let (graph, edge) = f.CollapseSubgraph(
        coreInputs.toArray(), coreOutputs.toArray(), "MealyCore(${f.GetName()})"
    )
    (graph, edge, delayEdges.size + valueEdges.size)
}

////////////////////////////////////////////////////////////////////////////////
//                      Eliminating instant feedback                          //
////////////////////////////////////////////////////////////////////////////////

/**
 * Create a bottom signal to provide as the initial value for feedback when
 * copying the cores.
 *
 * @param graph
 * @param feedbackVertices
 * @param coreEdge
 * @param index
 */
func CreateBottomSignal<V, G>(
    graph : InterfacedHypergraph<V, G>, feedbackVertices : Array<Vertex<V, G>>,
    coreEdge : Edge<V, G>, index : Int64
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let (left, right) = feedbackVertices[index].SplitVertex()
    let bot = Edge(
        GetSignalLabel<V, G>(
            V.GetDisconnected(),
            coreEdge.GetSource(index).GetWidth()
        ),
        Array<Vertex<V, G>>(), [right], None, graph.GetGraph()
    )
}
/**
 * Copy a pre-Mealy core, attaching its feedback sources to some given feedback
 * targets specified in a previous iteration. Also adds the edge to a hash set
 * of core edges.
 *
 * @param graph
 * @param coreEdge
 * @param numberOfFeedbackWires
 * @param feedbackTargets The feedback targets of the previous iteration
 * @param coreEdges
 */
func CopyCore<V, G>(
    graph : InterfacedHypergraph<V, G>,
    coreEdge : Edge<V, G>,
    numberOfFeedbackWires : Int64,
    feedbackTargets : Array<Vertex<V, G>>,
    coreEdges : HashSet<Edge<V, G>>
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    // Get the inputs to this core iteration: the feedback outputs from the
    // previous iteration and the inputs to the original circuit
    let copyInputs = Array<Vertex<V, G>>(coreEdge.GetArity()) {
        i : Int64 =>
            if(i < numberOfFeedbackWires) {
                feedbackTargets[i]
            } else {
                graph.GetInput(i - numberOfFeedbackWires).GetVertex()
            }
    }
    // Create the outputs to the core iteration
    let copyOutputs = Array<Vertex<V, G>>(coreEdge.GetCoarity()) {
        i : Int64 =>
            graph.GetGraph().AddNewVertex(coreEdge.GetTarget(i).GetWidth())
    }
    let coreCopy = coreEdge.Clone(copyInputs, copyOutputs, graph.GetGraph())
    // Set the new outputs accordingly
    for(i in 0..numberOfFeedbackWires) {
        feedbackTargets[i] = copyOutputs[i].GetVertex()
    }
    // Replace the outputs of the original graph by the outputs from this
    // core
    for(i in 0..graph.GetCoarity()) {
        graph.ReplaceOutput(
            i, copyOutputs[i + numberOfFeedbackWires].GetVertex()
        )
    }
    coreEdges.put(coreCopy)
}
/**
 * Remove 'instant feedback' (i.e. feedback that is not delay guardeded) from
 * circuits by iterating the circuit some number of times. (The number of times
 * is determined as cx + 1, where c is the longest chain in the value lattice,
 * and x is the number of feedback wires).
 *
 * @param sig
 * @param f
 */
func EliminateInstantFeedback<V, G>(
    sig : Signature<V, G>, f : InterfacedHypergraph<V, G>
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let feedbackConnections = f.GetFeedbackConnections()
    let numberOfFeedbackWires = feedbackConnections.size
    // Extract the instant feedback tentacles so they are the inputs and outputs
    // to a (sequential) core
    let (feedbackVertices, coreEdge, _) =
        f.IsolateTentacles(
            Array(feedbackConnections),
            "PreMealyCore(${f.GetName()})"
        )
    // Feedback connections don't need to be treated as feedback any more
    f.GetGraph().RemoveAllFeedback()
    // In the first iteration, the feedback wires are initialised as the
    // disconnected bottom value
    for(i in 0..numberOfFeedbackWires) {
        CreateBottomSignal(f, feedbackVertices, coreEdge, i)
    }
    let feedbackTargets = Array<Vertex<V, G>>(numberOfFeedbackWires){
        i : Int64 => coreEdge.GetTarget(i)
    }
    // The number of times we need to copy depends on the longest chain in the
    // value lattice: each application of the core can potentially move one
    // element up the chain and it may not stabilise until the end of the chain
    let iterations = sig.GetLongestChain(numberOfFeedbackWires)
    let coreEdges = HashSet([coreEdge])
    // For each iteration, connect the previous feedback outputs to a copied
    // core's feedback inputs
    for(it in 0..iterations) {
        CopyCore(f, coreEdge, numberOfFeedbackWires, feedbackTargets, coreEdges)
    }
    // We don't need to have the cores collapsed any more
    for(e in coreEdges) {
        e.BurstSubgraph()
    }
}

////////////////////////////////////////////////////////////////////////////////
//                         Complete transformation                            //
////////////////////////////////////////////////////////////////////////////////

/**
 * 'Burst' edges that have sequential subgraphs.
 * This is because all of the delays in the subgraph must be
 * dealt with separately, and cannot remain in their subgraphs.
 *
 * @param f The interfaced hypergraph
 */
func BurstSequentialGraphs<V, G>(f : InterfacedHypergraph<V, G>) : Unit
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    var sequentialEdges = f.GetSequentialEdges().size
    while(sequentialEdges != 0) {
        let edges = HashSet<Edge<V, G>>(f.GetSequentialEdges())
        for(e in edges) {
            e.BurstSubgraph()
        }
        sequentialEdges = f.GetSequentialEdges().size
    }
}
/**
 * Given a graph, clone it and transform it into a form suitable for evaluation,
 * with the combinational logic separated from the state.
 *
 * @param signature
 * @param graph
 * @param debug
 * @return (cloned graph, combinational core edge, size of the state)
 */
func TransformCircuitIntoEvalForm<V, G>(
    signature : Signature<V, G>,
    graph : InterfacedHypergraph<V, G>,
    debug!: Bool = false
) : (InterfacedHypergraph<V, G>, Edge<V, G>, Int64)
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let clonedGraph = graph.Clone()
    BurstSequentialGraphs(clonedGraph)
    let (coreGraph, coreEdge, numberOfStateWires) =
        ConvertToMealyForm(signature, clonedGraph)
    // Eliminate the instant feedback from the Mealy core
    if(coreGraph.GetFeedbackConnections().size != 0) {
        EliminateInstantFeedback(signature, coreGraph)
        // Simplify the resulting graphs
        RewriteCombinational(
            signature, coreGraph, copyBlackBoxes: false,
            allInstantaneous: false, debug: debug
        )
    }
    (clonedGraph, coreEdge, numberOfStateWires)
}