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
import graphs.*
import assertions.*

public struct InputOutput<V> <: ToString where V <: ValueSymbol<V> {
    public InputOutput(
        public let input : Array<Signal<V>>,
        public let output : Array<Option<Signal<V>>>
    ){}
    public func toString() : String {
        "${GetArgumentString(this.input)} -> ${GetOutputString(this.output)}"
    }
}

/**
 * Class for evaluating circuits given inputs at each tick of the clock
 */
public class Evaluator<V, G> <: Drawable<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    var currentCycle = 0
    let debug : Bool
    let sig : Signature<V, G>
    let graph : InterfacedHypergraph<V, G>
    let coreGraph : InterfacedHypergraph<V, G>
    var coreEdge : Edge<V, G>
    let stateWires : Int64
    // The vertices that are the root of the next output (i.e. the sources of
    // the last delay, or the outputs if there is no delay)
    let nextRootVertices : Array<Vertex<V, G>>
    // The vertices that were the targets of the last output signals, or the
    // outputs if no signals have been computed yet
    let lastSignalTargets : Array<Vertex<V, G>>
    // The edges representing the join of the current state and the feedback
    let stateJoinEdges : Array<TraversalElement<V, G>>
    // The sequence of inputs and corresponding outputs
    let inputOutputHistory : ArrayList<InputOutput<V>>
    public init(
        signature : Signature<V, G>, f : InterfacedHypergraph<V, G>,
        debug!: Bool = false
    ){
        this.debug = debug
        this.sig = signature
        // Clone the graph so that the original is not affected
        this.graph = f.Clone()
        // Sequential components need to be isolated from the combinational ones
        BurstSequentialGraphs(this.graph)
        // Put all state into registers, and bundle combinational logic into
        // one block
        let (coreGraph, coreEdge, stateWires) =
            ConvertToMealyForm(signature, this.graph)
        this.coreEdge = coreEdge
        this.coreGraph = coreGraph
        this.stateWires = stateWires
        // Eliminate the instant feedback from the Mealy core
        if(this.coreGraph.GetFeedbackConnections().size != 0){
            EliminateInstantFeedback(sig, this.coreGraph)
            // Simplify the resulting graph
            RewriteCombinational(
                sig, this.coreGraph, copyBlackBoxes: false,
                allInstantaneous: false, debug: debug
            )
        }
        this.nextRootVertices = this.graph.GetOutputVertices()
        this.lastSignalTargets = this.graph.GetOutputVertices()
        this.stateJoinEdges = Array<TraversalElement<V, G>>(this.stateWires){
            i : Int64 => EDGE(coreEdge.NextEdgeLeft(i).getOrThrow().GetEdge())
        }
        this.inputOutputHistory = ArrayList()
    }
    public func GetInputOutputHistory() : ArrayList<InputOutput<V>> {
        this.inputOutputHistory
    }
    public func GetGraph() : InterfacedHypergraph<V, G> {
        this.graph
    }
    public func WriteDotToFile(
        depth : Int64, file : String, debug!: Bool = false
    ) : Unit {
        this.GetGraph().WriteDotToFile(depth, file, debug: debug)
    }
    /**
     * Perform a cycle using this evaluator for some given input signals
     * for this cycle
     *
     * @param signals The input signals at the current tick of the clock
     */
    public func PerformCycle(inputSignals : Array<Signal<V>>) : Unit {
        AssertHasLength(inputSignals, this.graph.GetArity())
        let rewriteStartingElements = HashSet<TraversalElement<V, G>>()
        let rewriteEndingElements = HashSet<TraversalElement<V, G>>()
        // Split the state vertices so we can insert the next state
        let splitJoinVertices = Array<(Vertex<V, G>, Vertex<V, G>)>(
            this.stateWires,
            { i : Int64 =>
                let joinEdge = this.coreEdge.NextEdgeLeft(i).getOrThrow().GetEdge()
                let joinSourceLeft = joinEdge.GetSource(0)
                let (left, right) = joinSourceLeft.SplitVertex()
                rewriteStartingElements.put(VERTEX(left))
                rewriteEndingElements.put(EDGE(joinEdge))
                (left, right)
            }
        )
        // Get the input vertices to the copied core: the left hand split state
        // vertices and the inputs at this tick of the clock
        let coreCopyInputs = Array<Vertex<V, G>>(
            this.coreEdge.GetArity(),
            { i : Int64 =>
                if(i < this.stateWires) {
                    splitJoinVertices[i][0]
                } else {
                    let signal = inputSignals[i - this.stateWires]
                    let signalLabel = GetSignalLabel<V, G>(signal.GetValues())
                    let signalVertex = Vertex<V, G>(signal.GetWidth(), None)
                    let signalSubgraph = if(signal.GetValues().size == 1) {
                        None<InterfacedHypergraph<V, G>>
                    } else {
                        MakeSignal<V, G>(signal)
                    }
                    let signalEdge = Edge(
                        signalLabel, Array<Vertex<V, G>>(), [signalVertex],
                        signalSubgraph, this.graph.GetGraph()
                    )
                    rewriteStartingElements.put(VERTEX(signalVertex))
                    signalVertex
                }
            }
        )
        // Get the output vertices to the copied core: the right hand split
        // state vertices and the next output vertices
        let coreCopyOutputs = Array<Vertex<V, G>>(this.coreEdge.GetCoarity()) {
            i : Int64 =>
                if(i < this.stateWires) {
                    splitJoinVertices[i][1]
                } else {
                    let outputIndex = i - this.stateWires
                    let outputVertex = nextRootVertices[outputIndex]
                    // We are going to insert the register containing the
                    // output subcircuit in between the previous register
                    // and the main graph
                    let (leftVertex, rightVertex) = outputVertex.SplitVertex()
                    // Make the delay edge for this output
                    let outputWidth = outputVertex.GetWidth()
                    let delayTarget = Vertex<V, G>(
                        outputWidth, Some(this.graph.GetGraph())
                    )
                    let delayEdge = Edge(
                        DELAY(outputWidth), [leftVertex], [delayTarget],
                        None, this.graph.GetGraph()
                    )
                    // The source of the output delay will be the output vertex
                    // in the next cycle
                    nextRootVertices[outputIndex] = leftVertex
                    // The output of the core copy we are constructing will be
                    // joined with the delay we just made
                    let outputTarget = Vertex<V, G>(
                        outputWidth, Some(this.graph.GetGraph())
                    )
                    lastSignalTargets[outputIndex] = outputTarget
                    let joinEdge = Edge(
                        JOIN(outputWidth), [outputTarget, delayTarget],
                        [rightVertex], None, this.graph.GetGraph()
                    )
                    rewriteEndingElements.put(VERTEX(rightVertex))
                    outputTarget
                }
        }
        // Clone the new core using the inputs and outputs
        let coreCopyEdge = this.coreEdge.Clone(
            coreCopyInputs, coreCopyOutputs, this.graph.GetGraph()
        )
        // Rewrite the copy of the combinational core. We want to
        // force blackboxes as much as possible to the right so that each
        // element of the state is isolated. Moreover, since the core is
        // guaranteed to be capped off with values, we can safely apply
        // instantaneous rules
        RewriteCombinational(
            this.sig, this.graph, rewriteStartingElements,
            rewriteEndingElements, copyBlackBoxes: true, allInstantaneous: true,
            debug: debug
        )
        let outputSignals = GetOutputSignals(this.lastSignalTargets)
        let inputOutput = InputOutput(inputSignals, outputSignals)
        this.inputOutputHistory.append(inputOutput)
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
    sig : Signature<V, G>, e : Edge<V, G>,f : InterfacedHypergraph<V, G>
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
    sig : Signature<V, G>,
    f : InterfacedHypergraph<V, G>
) : (
    InterfacedHypergraph<V, G>,
    Edge<V, G>,
    Int64
) where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
    sig : Signature<V, G>,
    f : InterfacedHypergraph<V, G>
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    f.WriteDotToFile(0, "dot/core", debug: true)
    let feedbackConnections = f.GetFeedbackConnections()
    let feedbackWires = feedbackConnections.size
    // Extract the instant feedback tentacles so they are the inputs and outputs
    // to a (sequential) core
    let (feedbackVertices, coreEdge, _) =
        f.IsolateTentacles(
            Array(feedbackConnections),
            "PreMealyCore(${f.GetName()})"
        )
    f.WriteDotToFile(1, "dot/core-isolated", debug: true)
    // In the first iteration, the feedback wires are initialised as the
    // disconnected bottom value
    for(i in 0..feedbackWires) {
        let (left, right) = feedbackVertices[i].SplitVertex()
        let bot = Edge(
            GetSignalLabel<V, G>(
                sig.GetBottom(),
                coreEdge.GetSource(i).GetWidth()
            ),
            Array<Vertex<V, G>>(), [right], None, f.GetGraph()
        )
    }
    let feedbackOutputs = Array<Vertex<V, G>>(feedbackWires){
        i : Int64 => coreEdge.GetTarget(i)
    }
    let iterations = sig.GetLongestChain(feedbackWires)
    let coreEdges = HashSet([coreEdge])
    // For each iteration, connect the previous feedback outputs to a copied
    // core's feedback inputs
    for(it in 0..iterations) {
        // Get the inputs to this core iteration: the feedback outputs from the
        // previous iteration and the inputs to the original circuit
        let copyInputs = Array<Vertex<V, G>>(coreEdge.GetArity()) {
            i : Int64 =>
                if(i < feedbackWires) {
                    feedbackOutputs[i]
                } else {
                    f.GetInput(i - feedbackWires).GetVertex()
                }
        }
        // Create the outputs to the core iteration
        let copyOutputs = Array<Vertex<V, G>>(coreEdge.GetCoarity()) {
            i : Int64 =>
                f.GetGraph().AddNewVertex(coreEdge.GetTarget(i).GetWidth())
        }
        let coreCopy = coreEdge.Clone(copyInputs, copyOutputs,f.GetGraph())
        // Set the new outputs accordingly
        for(i in 0..feedbackWires) {
            feedbackOutputs[i] = copyOutputs[i].GetVertex()
        }
        // Replace the outputs of the original graph by the outputs from this
        // core
        for(i in 0..f.GetCoarity()) {
            f.ReplaceOutput(i, copyOutputs[i + feedbackWires].GetVertex())
        }
        coreEdges.put(coreCopy)
    }
    f.WriteDotToFile(1, "dot/core-copies", debug: true)
    // We don't need to have the cores collapsed any more
    for(e in coreEdges) {
        e.BurstSubgraph()
    }
    f.WriteDotToFile(1, "dot/core-unfolded", debug: true)
}
/**
 * Get the array of output signals of a graph at a given time. The elements of
 * the array will be None if the outputs cannot be successfully recovered, i.e.
 * if there is not a simple register at the desired tick of the clock.
 *
 * @param currentVertices
 *             the array of vertices that are the targets of the output graph
 *             for each tick of the clock
 * @return An array in which each element is either a signal, or None if there
 *             is not a simple register at the desired tick for this output
 */
func GetOutputSignals<V, G>(
   signalVertices : Array<Vertex<V, G>>
) : Array<Option<Signal<V>>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    map({ v =>
        match(v.GetInEdge()) {
            case None => None
            case Some(ec) => ec.GetEdge().GetLabel().GetMaybeSignal()
        }
    }, signalVertices)
}
/**
 * Allow evaluation using decimal values
 */
extend Evaluator<V, G> where V <: Decimal<V> {
    public func PerformCycle(inputs : Array<Int64>, signed!: Bool) : Unit {
        let inputSignals = mapi(
            { v : Int64, i : Int64 =>
                V.DecToSignal(v, this.graph.GetInput(i).GetWidth(), signed)
            },
            inputs
        )
        this.PerformCycle(inputSignals)
    }
}