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
    let graph : InterfacedHypergraph<V, G>
    let coreGraph : InterfacedHypergraph<V, G>
    var coreEdge : Edge<V, G>
    let stateWires : Int64
    let nextOutputVertices : Array<Vertex<V, G>>
    public init(
        signature : Signature<V, G>,
        f : InterfacedHypergraph<V, G>
    ){
        this.sig = signature
        // Clone the graph so that the original is not affected
        this.graph = f.Clone()
        // Sequential components need to be isolated from the combinational ones
        BurstSequentialGraphs(this.graph)
        // Put all state into registers, and bundle combinational logic into
        // one block
        let (coreGraph, coreEdge, stateWires) =
            ConvertToMealyForm(signature, this.graph)
        // Eliminate the instant feedback from the Mealy core
        this.coreEdge = coreEdge
        this.coreGraph = coreGraph
        this.stateWires = stateWires
        EliminateInstantFeedback(sig, this.coreGraph)
        RewriteCombinational(sig, this.coreGraph)
        this.nextOutputVertices = map({
            iv => iv.GetVertex()
        }, this.graph.GetOutputs())
    }
    public func GetGraph() : InterfacedHypergraph<V, G> {
        this.graph
    }
    func ApplyCore(signals : Array<Signal<V>>) : InterfacedHypergraph<V, G> {
        let appliedCoreGraph = Hypergraph<V, G>()
        let coreCopyEdge = this.coreEdge.Clone(appliedCoreGraph)
        let stateEdges = Array<Edge<V, G>>(this.stateWires) {
            i : Int64 =>
                println("Getting state edge ${i}")
                let joinEdge = this.coreEdge.NextEdgeLeft(i).GetEdge()
                let stateEdge = joinEdge.NextEdgeLeft(0).GetEdge()
                println("The ${i} state edge is ${stateEdge}")
                stateEdge.Clone(
                    Array<Vertex<V, G>>(),
                    [coreCopyEdge.GetSource(i).GetVertex()],
                    appliedCoreGraph
                )
        }
        let inputEdges = mapi({
            signal : Signal<V>, i : Int64 =>
                Edge(
                    GetSignalLabel<V, G>(signal.GetValues()),
                    Array<Vertex<V, G>>(),
                    [coreCopyEdge.GetSource(this.stateWires + i).GetVertex()],
                    this.sig.MakeSignal(signal),
                    appliedCoreGraph
                )
            },
            signals
        )
        let outputVertices = map(
            {t : Tentacle<V, G> => InterfaceVertex(t.GetVertex(), "")},
            coreCopyEdge.GetTargets()
        )
        InterfacedHypergraph(
            appliedCoreGraph,
            Array<InterfaceVertex<V, G>>(),
            outputVertices,
            "Core${GetSignalsString(signals)}"
        )
    }
    /**
     * Perform a cycle using this evaluator for some given input signals
     * for this cycle
     *
     * @param signals The input signals at the current tick of the clock
     */
    public func PerformCycle(signals : Array<Signal<V>>) : Unit {
        AssertArrayHasLength(signals, this.graph.GetArity())
        let appliedCoreGraph = ApplyCore(signals)
        this.sig.WriteDotToFile(appliedCoreGraph, 2, "after-applying")
        RewriteCombinational<V, G>(
            this.sig,
            appliedCoreGraph
        )
        let transitionTargets = Array<Vertex<V, G>>(
            this.coreGraph.GetCoarity()
        ) {
            i : Int64 =>
                if(i < this.stateWires) {
                    let stateVertex =
                        this.coreEdge
                            .NextEdgeLeft(i)
                            .GetEdge()
                            .GetSource(0)
                            .GetVertex()
                    let oldStateEdge =
                        stateVertex
                            .GetInEdge()
                            .getOrThrow()
                            .GetEdge()
                    this.graph.RemoveEdge(oldStateEdge)
                    stateVertex.RemoveInEdge()
                    stateVertex
                } else {
                    Vertex<V, G>(appliedCoreGraph.GetOutput(i).GetWidth())
                }
        }
        // TODO we shouldn't have to clone here, but if we don't the traversal
        // elements are wrong and I'm not sure why.
        // Presumably they aren't being updated correctly after some rewrite,
        // but they are recomputed when the new graph is made so it's okay after
        // that
        let transitionGraph = appliedCoreGraph.Clone()
        let transitionEdge = Edge<V, G>(
            "Transition",
            Array<Vertex<V, G>>(),
            transitionTargets,
            transitionGraph,
            this.graph.GetGraph()
        )
        let outputTargets = Array<Vertex<V, G>>(this.coreEdge.GetCoarity()) {
            i : Int64 => Vertex<V, G>(
                appliedCoreGraph.GetOutput(i).GetWidth()
            )
        }
        let outputGraph = appliedCoreGraph.Clone()
        let outputEdge = Edge<V, G>(
            "Output",
            Array<Vertex<V, G>>(),
            outputTargets,
            outputGraph,
            this.graph.GetGraph()
        )
        for(i in 0..this.nextOutputVertices.size) {
            let outputVertex = nextOutputVertices[i]
            // We are going to insert the register containing the
            // output subcircuit in between the previous register
            // and the main graph
            let (leftVertex, rightVertex) = SplitVertex(outputVertex)
            // Make the delay edge for this output
            let outputWidth = outputVertex.GetWidth()
            let delayTarget = Vertex<V, G>(outputWidth)
            let delayEdge = Edge(
                DELAY(outputWidth),
                [leftVertex],
                [delayTarget],
                None,
                this.graph.GetGraph()
            )
            // The ith target from the output subgraph is the first source
            // of this register's join edge
            let outputTarget = outputTargets[this.stateWires + i]
            let joinEdge = Edge(
                JOIN(outputWidth),
                [outputTarget, delayTarget],
                [rightVertex],
                None,
                this.graph.GetGraph()
            )
        }
        this.sig.WriteDotToFile(this.graph, 1, "before-rewrite")
        let transitionEnding = HashSet<TraversalElement<V, G>>()
        for(t in transitionEdge.GetTargets()){
            transitionEnding.put(VERTEX(t.GetVertex()))
        }
        RewriteCombinational(
            this.sig,
            this.graph,
            HashSet([EDGE(transitionEdge)]),
            HashSet(transitionEnding)
        )
        let outputEnding = HashSet<TraversalElement<V, G>>()
        for(t in outputEdge.GetTargets()){
            outputEnding.put(VERTEX(t.GetVertex()))
        }
        RewriteCombinational(
            this.sig,
            this.graph,
            HashSet([EDGE(outputEdge)]),
            HashSet(transitionEnding)
        )
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
    Int64
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
    for(v in f.GetInputs()) {
        coreInputs.append(FROM_VERTEX(v.GetVertex()))
    }
    for(v in f.GetOutputs()) {
        coreOutputs.append(FROM_VERTEX(v.GetVertex()))
    }
    let (graph, edge) = f.CollapseSubgraph(
        coreInputs.toArray(),
        coreOutputs.toArray(),
        "MealyCore(${f.GetName()})"
    )
    (graph, edge, delayEdges.size + valueEdges.size)
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