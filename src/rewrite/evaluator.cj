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

/**
 * Class for evaluating circuits given inputs at each tick of the clock
 */
public class Evaluator<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    var currentCycle = 0
    let sig : Signature<V, G>
    let graph : InterfacedHypergraph<V, G>
    var coreEdge : Edge<V, G>
    let numberOfStateWires : Int64
    // The vertices that are the root of the next output (i.e. the sources of
    // the last delay, or the outputs if there is no delay)
    let latestDelayVertices : Array<Vertex<V, G>>
    // The vertices that were the targets of the last output signals, or the
    // outputs if no signals have been computed yet
    let latestInstantVertices : Array<Vertex<V, G>>
    // The longest name of a port in the graph, used for waveform diagrams
    let longestPortName : Int64
    // Struct containing various input-output history data structures
    let history : InputOutputHistory<V, G>
    public init(
        signature : Signature<V, G>, graph : InterfacedHypergraph<V, G>,
        debug!: Bool = false
    ){
        this.sig = signature
        // Transform the circuit into the right form
        let (clonedGraph, coreEdge, numberOfStateWires) =
            TransformCircuitIntoEvalForm(signature, graph, debug: debug)
        this.graph = clonedGraph
        this.coreEdge = coreEdge
        this.numberOfStateWires = numberOfStateWires
        this.latestDelayVertices = Array(this.graph.GetOutputVertices())
        this.latestInstantVertices = Array(this.graph.GetOutputVertices())
        let longestInputPortName =
            GetLongestNameLength(this.graph.GetInputPorts())
        let longestOutputPortName =
            GetLongestNameLength(this.graph.GetOutputPorts())
        this.longestPortName = max(longestInputPortName, longestOutputPortName)
        this.history =
            InputOutputHistory(this.graph.GetArity(), this.graph.GetCoarity())
    }
}
extend Evaluator<V, G> <: HasInterfacedGraph<V, G> {
    public func GetInterfacedGraph() : InterfacedHypergraph<V, G> {
        this.graph
    }
}
extend Evaluator<V, G> <: Drawable<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0,
        debug!: Bool = false, expandSignals!: Bool = false
    ) : Unit {
        this.GetInterfacedGraph().WriteDotToFile(
            file, depth: depth, debug: debug, expandSignals: expandSignals
        )
    }
}
extend Evaluator<V, G> <: DecimalDrawable
    where V <: Decimal<V> & ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0, signed!: Bool, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        this.GetInterfacedGraph().WriteDotToFile(
            file, depth: depth, signed: signed, debug: debug, expandSignals: expandSignals
        )
    }
}