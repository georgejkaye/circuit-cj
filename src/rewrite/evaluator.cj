/**
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
        where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    var currentCycle = 0
    let sig : Signature<V, G>
    let f : InterfacedHypergraph<V, G>
    let combinationalCore : InterfacedHypergraph<V, G>
    let coreEdge : Edge<V, G>
    var currentState : Array<Signal<V>>
    var tailVertices : Array<Vertex<V, G>>
    var inputVertices : Array<Vertex<V, G>>
    var stateVertices : Array<Vertex<V, G>>
    var traceVertices : Array<Vertex<V, G>>
    public init(
        signature : Signature<V, G>,
        f : InterfacedHypergraph<V, G>
    ){
        this.sig = signature
        // Clone the graph so that the original is not affected
        let clonedF = f.Clone()
        BurstSequentialGraphs(clonedF)
        sig.WriteDotToFile(clonedF, 0, "after-burst")
        this.f = clonedF
        let (graph, edge, state, stateVertices) =
            ConvertToMealyForm(signature, clonedF)
        this.combinationalCore = graph
        this.coreEdge = edge
        this.currentState = state
        this.stateVertices = stateVertices
        this.tailVertices = Array<Vertex<V, G>>(f.GetCoarity()) {
            i : Int64 => f.GetOutput(i).GetVertex()
        }
        this.inputVertices = Array<Vertex<V, G>>(f.GetArity()) {
            i : Int64 => f.GetInput(i).GetVertex()
        }
        this.traceVertices = Array<Vertex<V, G>>(
            graph.GetCoarity() - f.GetCoarity()
        ) {
            i : Int64 => graph.GetOutput(i).GetVertex()
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
        for(i in this.traceVertices.size..this.combinationalCore.GetCoarity()) {
            let vertex = vertexFn(i, i - traceVertices.size)
            outputs.append(vertex)
            for(ec in vertex.GetOutEdges()) {
                endingElements.put(EDGE(ec.GetEdge()))
            }
        }
    }
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
    func MakeTransitionRegister(
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
    func MakeOutputRegister(
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
                let outputVertex = f.GetOutput(outputIndex).GetVertex()
                let width = outputVertex.GetWidth()
                let delayTarget = Vertex<V, G>(width)
                let delay = Edge(
                    DELAY(width),
                    [outputVertex],
                    [delayTarget],
                    None,
                    f.GetGraph()
                )
                let coreTarget = Vertex<V, G>(width)
                let joinTarget = Vertex<V, G>(width)
                let join = Edge(
                    JOIN(width),
                    [coreTarget, delayTarget],
                    [joinTarget],
                    None,
                    f.GetGraph()
                )
                f.ReplaceOutput(outputIndex, joinTarget)
                coreTarget
        }
        CopyCore(signals, stateVertexFn, inputVertexFn, outputVertexFn)
    }
    public func PerformCycle(signals : Array<Signal<V>>) : Unit {
        AssertArrayHasLength(signals, f.GetArity())
        // TODO This is inefficient as we're reducing the same graph twice.
        // Really we should be reducing the core with values once, then
        // sticking the appropriate values (transition or output) into the
        // appropriate places
        let (transitionStarting, transitionEnding) = MakeTransitionRegister(signals)
        let (outputStarting, outputEnding) = MakeOutputRegister(signals)
        this.sig.WriteDotToFile(this.f, 0, "before-rewrite-0")
        this.sig.WriteDotToFile(this.f, 1, "before-rewrite-1")
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
    }
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

func MakeRegisterJoin<V, G>(
    sig : Signature<V, G>,
    e : Edge<V, G>,
    f : InterfacedHypergraph<V, G>,
    delays : Bool
) : (
    TentacleOrigin<V, G>,
    TentacleOrigin<V, G>,
    Signal<V>,
    Vertex<V, G>
) where
    V <: ValueSymbol,
    V <: Equatable<V>,
    G <: PrimitiveSymbol<V>,
    G <: Equatable<G>
{
    let target = e.GetTarget(0).GetVertex()
    let width = target.GetWidth()
    let (left, right) = SplitVertex(target)
    let bot = sig.UseSignal(sig.GetBottom(), width)
    let (value, delay, input, signal) = if(delays) {
        let tentacle = SOURCE(e, 0)
        (
            bot.GetVertex(),
            left,
            SOURCE(e, 0),
            Signal(sig.GetBottom(), width)
        )
    } else {
        let delayTarget = Vertex<V, G>(width)
        let delayEdge = Edge(
            DELAY(width),
            [bot.GetVertex()],
            [delayTarget],
            None,
            f.GetGraph()
        )
        (
            left,
            delayTarget,
            SOURCE(delayEdge, 0),
            e.GetLabel().GetSignal()
        )
    }
    let join = Edge(
        Label<V, G>.JOIN(width),
        [value, delay],
        [right],
        None<InterfacedHypergraph<V, G>>,
        f.GetGraph()
    )
    (input, TARGET(join, 0), signal, value)
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
    V <: ValueSymbol,
    V <: Equatable<V>,
    G <: PrimitiveSymbol<V>,
    G <: Equatable<G>
{
    let sequentialData = f.GetSequentialData()
    let valueEdges = HashSet(sequentialData.valueEdges)
    let delayEdges = HashSet(sequentialData.delayEdges)
    let coreInputs = ArrayList<TentacleOrigin<V, G>>()
    let coreOutputs = ArrayList<TentacleOrigin<V, G>>()
    let state = ArrayList<Signal<V>>()
    let values = ArrayList<Vertex<V, G>>()
    func GetInputAndOutput(e : Edge<V, G>, delays : Bool) {
        let (input, output, signal, value) = MakeRegisterJoin(sig, e, f, delays)
        coreInputs.append(output)
        coreOutputs.append(input)
        state.append(signal)
        values.append(value)
    }
    for(e in HashSet(delayEdges)) {
        GetInputAndOutput(e, true)
    }
    for(e in HashSet(valueEdges)) {
        GetInputAndOutput(e, false)
    }
    for(i in 0..f.GetArity()) {
        coreInputs.append(INPUT(f, i))
    }
    for(i in 0..f.GetCoarity()) {
        coreOutputs.append(OUTPUT(f, i))
    }
    let (graph, edge) = f.CollapseSubgraph(
        coreInputs.toArray(),
        coreOutputs.toArray(),
        "Core(${f.GetName()})"
    )
    (graph, edge, state.toArray(), values.toArray())
}