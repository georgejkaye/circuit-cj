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
    let initialState : Array<Signal<V>>
    var tailVertices : Array<Vertex<V, G>>
    var inputVertices : Array<Vertex<V, G>>
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
        let (graph, edge, state) = ConvertToMealyForm(signature, clonedF)
        this.combinationalCore = graph
        this.initialState = state
        this.tailVertices = Array<Vertex<V, G>>(f.GetCoarity()) {
            i : Int64 => f.GetOutput(i).GetVertex()
        }
        this.inputVertices = Array<Vertex<V, G>>(f.GetArity()) {
            i : Int64 => f.GetInput(i).GetVertex()
        }
        this.traceVertices = Array<Vertex<V, G>>(combinationalCore.GetCoarity() - f.GetCoarity()) {
            i : Int64 => graph.GetOutput(i).GetVertex()
        }
    }
    // public func EvaluateCycle(vs : Array<Signal<V>>) : Signal<V> {
    //     let nowEdge = MakeNowEdge(vs)
    //     let laterEdge = MakeLaterEdge(vs)
    public func GetGraph() : InterfacedHypergraph<V, G>  {
        this.f
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
) : (TentacleOrigin<V, G>, TentacleOrigin<V, G>, Signal<V>) where
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
    (input, TARGET(join, 0), signal)
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
public func ConvertToMealyForm<V, G>(
    sig : Signature<V, G>,
    f : InterfacedHypergraph<V, G>
) : (InterfacedHypergraph<V, G>, Edge<V, G>, Array<Signal<V>>) where
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
    func GetInputAndOutput(e : Edge<V, G>, delays : Bool) {
        let (input, output, signal) = MakeRegisterJoin(sig, e, f, delays)
        coreInputs.append(output)
        coreOutputs.append(input)
        state.append(signal)
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
    sig.WriteDotToFile(f, 1, "after-regs")
    let (graph, edge) = f.CollapseSubgraph(
        coreInputs.toArray(),
        coreOutputs.toArray(),
        "Core(${f.GetName()})"
    )
    (graph, edge, state.toArray())
}