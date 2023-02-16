/*
 * rewrite/evaluator.cj
 *
 * Evaluator for reducing closed circuits
 * to their outputs
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

import syntax.*
import debug.*

public class Evaluator<V, G>
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    var currentCycle = 0
    let sig : Signature<V, G>
    let f : InterfacedHypergraph<V, G>
    let combinationalCore : InterfacedHypergraph<V, G>
    let coreEdge : Edge<V, G>
    var currentState : Array<Signal<V>>
    var coreStateSources : Array<Vertex<V, G>>
    var coreInputSources : Array<Vertex<V, G>>
    var coreStateTargets : Array<Vertex<V, G>>
    var coreOutputTargets : Array<Vertex<V, G>>
    var stateVertices : Array<Vertex<V, G>>
    var stateJoinEdges : Array<Edge<V, G>>
    public init(
        signature : Signature<V, G>,
        f : InterfacedHypergraph<V, G>
    ){
        this.sig = signature
        // Clone the graph so that the original is not affected
        let clonedF = f.Clone()
        BurstSequentialGraphs(clonedF)
        this.f = clonedF
        let (graph, edge, state, stateVertices) =
            ConvertToMealyForm(signature, clonedF)
        this.combinationalCore = graph
        this.coreEdge = edge
        this.currentState = state
        this.stateVertices = stateVertices
        this.coreOutputTargets = Array<Vertex<V, G>>(f.GetCoarity()) {
            i : Int64 => clonedF.GetOutput(i).GetVertex()
        }
        this.coreInputSources = Array<Vertex<V, G>>(f.GetArity()) {
            i : Int64 => clonedF.GetInput(i).GetVertex()
        }
        this.coreStateSources = Array<Vertex<V, G>>(
            graph.GetCoarity() - f.GetCoarity()
        ) {
            i : Int64 => edge.GetSource(i).GetVertex()
        }
        this.coreStateTargets = Array<Vertex<V, G>>(
            graph.GetCoarity() - f.GetCoarity()
        ) {
            i : Int64 => edge.GetTarget(i).GetVertex()
        }
        this.stateJoinEdges = Array<Edge<V, G>>(graph.GetCoarity() - f.GetCoarity()){
            i : Int64 => edge.GetSource(i).GetVertex().GetInEdge().getOrThrow().GetEdge()
        }
    }
    public func GetGraph() : InterfacedHypergraph<V, G> {
        this.f
    }
    func GetSignalVertex(s : Signal<V>) : Vertex<V, G> {
        sig.UseSignal(s).GetVertex()
    }
    func GetStateVertices(
        inputs : ArrayList<Vertex<V, G>>,
        outputs : ArrayList<Vertex<V, G>>,
        startingElements : HashSet<TraversalElement<V, G>>,
        endingElements : HashSet<TraversalElement<V, G>>,
        vertexFn : (Int64, Vertex<V, G>, Signal<V>) -> (Vertex<V, G>, Vertex<V, G>)
    ) : Unit {
        for(i in 0..this.currentState.size) {
            let stateVertex = this.stateVertices[i]
            let stateSignal = this.currentState[i]
            let (inputVertex, outputVertex) = vertexFn(i, stateVertex, stateSignal)
            inputs.append(inputVertex)
            outputs.append(outputVertex)
            let inputEdge = inputVertex.GetInEdge().getOrThrow().GetEdge()
            startingElements.put(EDGE(inputEdge))
            for(ec in outputVertex.GetOutEdges()) {
                endingElements.put(EDGE(ec.GetEdge()))
            }
        }
    }
    func GetInputVertices(
        signals : Array<Signal<V>>,
        inputs : ArrayList<Vertex<V, G>>,
        startingElements : HashSet<TraversalElement<V, G>>,
        vertexFn : (Int64, Signal<V>) -> (Vertex<V, G>)
    ) : Unit {
        for(i in 0..signals.size) {
            let vertex = vertexFn(i, signals[i])
            inputs.append(vertex)
            let inputEdge = vertex.GetInEdge().getOrThrow().GetEdge()
            startingElements.put(EDGE(inputEdge))
        }
    }
    func GetOutputVertices(
        outputs : ArrayList<Vertex<V, G>>,
        endingElements : HashSet<TraversalElement<V, G>>,
        vertexFn : (Int64, Int64) -> Vertex<V, G>
    ) : Unit {
        for(i in this.coreStateTargets.size..this.combinationalCore.GetCoarity()) {
            let vertex = vertexFn(i, i - coreStateTargets.size)
            outputs.append(vertex)
            for(ec in vertex.GetOutEdges()) {
                endingElements.put(EDGE(ec.GetEdge()))
            }
        }
    }
    /**
     * Make a copy of the combinational core.
     *
     * @param signals The input signals at this tick
     * @param stateVertexFn The function that specifies the source and target
                              state vertex at each index for this copy
     * @param inputVertexFn the function that specifies the input source vertex
                               at each index for this copy
     * @param outputVertexFn the function that specifies the output target vertex
                               at each index for this copy
     * @return A tuple containing
     *              0) The starting elements for traversing this core (the values)
     *              1) The ending elements for traversing this core (the join)
     */
    func CopyCore(
        signals : Array<Signal<V>>,
        stateVertexFn : (Int64, Vertex<V, G>, Signal<V>) -> (Vertex<V, G>, Vertex<V, G>),
        inputVertexFn : (Int64, Signal<V>) -> Vertex<V, G>,
        outputVertexFn : (Int64, Int64) -> Vertex<V, G>
    ) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>) {
        let inputs = ArrayList<Vertex<V, G>>()
        let outputs = ArrayList<Vertex<V, G>>()
        let startingElements = HashSet<TraversalElement<V, G>>()
        let endingElements = HashSet<TraversalElement<V, G>>()
        GetStateVertices(inputs, outputs, startingElements, endingElements, stateVertexFn)
        GetInputVertices(signals, inputs, startingElements, inputVertexFn)
        GetOutputVertices(outputs, endingElements, outputVertexFn)
        let clonedEdge = coreEdge.Clone(
            inputs.toArray(),
            outputs.toArray(),
            f.GetGraph()
        )
        (startingElements, endingElements)
    }
    /**
     * Create the copy of the core that produces the transition at this tick.
     *
     * @param signals The input signals
     * @return A tuple of
     *          a) The starting traversal elements (the values)
     *          b) The ending trversal elements (the join of the register)
     */
    func MakeTransitionCore(
        signals : Array<Signal<V>>
    ) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>) {
        let stateVertexFn = {
            i : Int64, v : Vertex<V, G>, s : Signal<V> =>
                SplitVertex(v)
        }
        let inputVertexFn = {
            i : Int64, s : Signal<V> =>
                GetSignalVertex(s)
        }
        let outputVertexFn = {
            i : Int64, j : Int64 =>
                Vertex<V, G>(this.coreEdge.GetTarget(i).GetWidth())
        }
        CopyCore(signals, stateVertexFn, inputVertexFn, outputVertexFn)
    }
    /**
     * Create the copy of the core that produces the output at this tick.
     *
     * @param signals The input signals
     * @return A tuple of
     *          a) The starting traversal elements (the values)
     *          b) The ending trversal elements (the join of the register)
     */
    func MakeOutputCore(
        signals : Array<Signal<V>>
    ) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>) {
        let stateVertexFn = {
            i : Int64, v : Vertex<V, G>, s : Signal<V> =>
                (GetSignalVertex(s), Vertex<V, G>(s.GetWidth()))
        }
        let inputVertexFn = {
            i : Int64, s : Signal<V> =>
                GetSignalVertex(s)
        }
        let outputVertexFn = {
            sourceIndex : Int64, outputIndex : Int64 =>
                let tailVertex = this.coreOutputTargets[outputIndex]
                let (left, right) = SplitVertex(tailVertex)
                this.coreOutputTargets[outputIndex] = left
                let width = left.GetWidth()
                let delayTarget = Vertex<V, G>(width)
                let delay = Edge(
                    DELAY(width),
                    [left],
                    [delayTarget],
                    None,
                    f.GetGraph()
                )
                let coreTarget = Vertex<V, G>(width)
                let join = Edge(
                    JOIN(width),
                    [coreTarget, delayTarget],
                    [right],
                    None,
                    f.GetGraph()
                )
                coreTarget
        }
        CopyCore(signals, stateVertexFn, inputVertexFn, outputVertexFn)
    }
    /**
     * Perform a cycle using this evaluator for some given input signals
     * for this cycle
     *
     * @param signals The input signals at the current tick of the clock
     */
    public func PerformCycle(signals : Array<Signal<V>>) : Unit {
        AssertArrayHasLength(signals, f.GetArity())
        // TODO This is inefficient as we're reducing the same graph twice.
        // Really we should be reducing the core with values once, then
        // sticking the appropriate values (transition or output) into the
        // appropriate places
        let (transitionStarting, transitionEnding) = MakeTransitionCore(signals)
        let (outputStarting, outputEnding) = MakeOutputCore(signals)
        RewriteCombinational<V, G>(
            this.sig,
            this.f,
            transitionStarting,
            transitionEnding
        )
        RewriteCombinational<V, G>(
            this.sig,
            this.f,
            outputStarting,
            outputEnding
        )
        for(i in 0..this.stateJoinEdges.size) {
            let e = this.stateJoinEdges[i]
            let stateVertex = e.GetSource(0).GetVertex()
            this.stateVertices[i] = stateVertex
            this.currentState[i] = stateVertex.GetInEdge().getOrThrow().GetEdge().GetLabel().GetSignal()
        }
        this.currentCycle++
    }
}
/**
 * 'Burst' edges that have sequential subgraphs.
 * This is because all of the delays in the subgraph must be
 * dealt with separately, and cannot remain in their subgraphs.
 *
 * @param f The interfaced hypergraph
 */
func BurstSequentialGraphs<V, G>(f : InterfacedHypergraph<V, G>) : Unit
    where
        V <: ValueSymbol & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
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
    sig : Signature<V, G>,
    e : Edge<V, G>,
    f : InterfacedHypergraph<V, G>
) : (
    Edge<V, G>,
    Edge<V, G>,
    Signal<V>,
    Vertex<V, G>
) where
    V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
    G <: PrimitiveSymbol<V> & Equatable<G>
{
    // We can only turn a delay or a value into a register
    let isDelay = e.GetLabel().IsDelay()
    let isValue = e.GetLabel().IsValue()
    if(!isDelay && !isValue) {
        throw IncompatibleVariantException(e.GetLabel(), "DELAY/VALUE")
    }
    let target = e.GetTarget(0).GetVertex()
    let width = target.GetWidth()
    let (leftVertex, rightVertex) = SplitVertex(target)
    let bot = sig.UseSignal(sig.GetBottom(), width)
    let (valueTarget, delayTarget, delayEdge, signal) = if(isDelay) {
        (
            bot.GetVertex(),
            leftVertex,
            e,
            Signal(sig.GetBottom(), width)
        )
    } else {
        let newVertex = Vertex<V, G>(width)
        let delayEdge = Edge(
            DELAY(width),
            [bot.GetVertex()],
            [newVertex],
            None,
            f.GetGraph()
        )
        (
            leftVertex,
            newVertex,
            delayEdge,
            e.GetLabel().GetSignal()
        )
    }
    let joinEdge = Edge(
        Label<V, G>.JOIN(width),
        [valueTarget, delayTarget],
        [rightVertex],
        None<InterfacedHypergraph<V, G>>,
        f.GetGraph()
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
    sig : Signature<V, G>,
    f : InterfacedHypergraph<V, G>
) : (
    InterfacedHypergraph<V, G>,
    Edge<V, G>,
    Array<Signal<V>>,
    Array<Vertex<V, G>>
) where
    V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
    G <: PrimitiveSymbol<V> & Equatable<G>
{
    let sequentialData = f.GetSequentialData()
    let valueEdges = HashSet(sequentialData.valueEdges)
    let delayEdges = HashSet(sequentialData.delayEdges)
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
    for(i in 0..f.GetArity()) {
        coreInputs.append(FROM_VERTEX(f.GetInput(i).GetVertex()))
    }
    for(i in 0..f.GetCoarity()) {
        coreOutputs.append(FROM_VERTEX(f.GetOutput(i).GetVertex()))
    }
    let (graph, edge) = f.CollapseSubgraph(
        coreInputs.toArray(),
        coreOutputs.toArray(),
        "MealyCore(${f.GetName()})"
    )
    (graph, edge, state.toArray(), values.toArray())
}

func EliminateInstantFeedback<V, G>(
    sig : Signature<V, G>,
    f : InterfacedHypergraph<V, G>
) : Unit where
    V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
    G <: PrimitiveSymbol<V> & Equatable<G>
{
    let feedbackConnections = f.GetSequentialData().feedbackConnections
    let feedbackWires = feedbackConnections.size
    let (feedbackVertices, coreEdge, _) =
        f.IsolateTentacles(
            Array(feedbackConnections),
            "PreMealyCore(${f.GetName()})"
        )
    for(i in 0..feedbackWires) {
        let (left, right) = SplitVertex(feedbackVertices[i])
        let bot = Edge(
            GetSignalLabel<V, G>(
                sig.GetBottom(),
                coreEdge.GetSource(i).GetWidth()
            ),
            Array<Vertex<V, G>>(),
            [right],
            None,
            f.GetGraph()
        )
    }
    let feedbackOutputs = Array<Vertex<V, G>>(feedbackWires){
        i : Int64 => coreEdge.GetTarget(i).GetVertex()
    }
    let iterations = sig.GetLongestChain(feedbackWires)
    let coreEdges = HashSet([coreEdge])
    for(it in 0..iterations) {
        let copyInputs = Array<Vertex<V, G>>(coreEdge.GetArity()) {
            i : Int64 =>
                if(i < feedbackWires) {
                    feedbackOutputs[i]
                } else {
                    f.GetInput(i - feedbackWires).GetVertex()
                }
        }
        let copyOutputs = Array<Vertex<V, G>>(coreEdge.GetCoarity()) {
            i : Int64 => Vertex(coreEdge.GetTarget(i).GetWidth())
        }
        let coreCopy = coreEdge.Clone(
            copyInputs,
            copyOutputs,
            f.GetGraph()
        )
        for(i in 0..feedbackWires) {
            feedbackOutputs[i] = copyOutputs[i]
        }
        for(i in 0..f.GetCoarity()) {
            f.ReplaceOutput(i, copyOutputs[i + feedbackWires])
        }
        coreEdges.put(coreCopy)
    }
    for(e in coreEdges) {
        e.BurstSubgraph()
    }
}