/**
 * rewrite/cycle.cj
 *
 * Functions for performing cycles with the evaluator
 *
 * @author George Kaye
 * @since 0.3
 */
package rewrite
/**
 * Detach the current wires from the state registers.
 *
 * @param coreEdge
 * @param numberOfStateWires
 * @param rewriteStartingElements
 * @param rewriteEndingElements
 * @return A tuple (lefts, rights) where
 *              lefts is the dangling vertices of the current state
 *              rights is the dangling vertices from the state registers
 */
func SplitCurrentState<V, G>(
    coreEdge : Edge<V, G>,
    numberOfStateWires : Int64,
    rewriteStartingElements : HashSet<TraversalElement<V, G>>,
    rewriteEndingElements : HashSet<TraversalElement<V, G>>
) : Array<(Vertex<V, G>, Vertex<V, G>)>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Array<(Vertex<V, G>, Vertex<V, G>)>(
        numberOfStateWires,
        { i : Int64 =>
            let joinEdge = coreEdge.NextEdgeLeft(i).getOrThrow().GetEdge()
            let joinSourceLeft = joinEdge.GetSource(0)
            let (left, right) = joinSourceLeft.SplitVertex()
            rewriteStartingElements.put(VERTEX(left))
            rewriteEndingElements.put(EDGE(joinEdge))
            (left, right)
        }
    )
}
/**
 * Get an array of vertices that will make up the sources of the cloned core for
 * reduction at this tick of the clock. In particular, this is the current
 * state vertices which should have already been split, and the targets of new
 * signal edges made based on the array of signals passed in.
 *
 * @param coreEdge
 * @param numberOfStateWires
 * @param inputSignals
 * @param splitStateVertices
 * @param rewriteStartingElements
 * @return An array of source vertices for a cloned core
 */
func GetCoreSourceVertices<V, G>(
    coreEdge : Edge<V, G>,
    numberOfStateWires : Int64,
    inputSignals : Array<CycleInput<V>>,
    splitStateVertices : Array<(Vertex<V, G>, Vertex<V, G>)>,
    rewriteStartingElements : HashSet<TraversalElement<V, G>>
) : Array<Vertex<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    Array<Vertex<V, G>>(
        coreEdge.GetArity(),
        { i : Int64 =>
            // Check which partition of sources this belongs to
            if(i < numberOfStateWires) {
                // This is a vertex from the state
                // We grab the existing state vertex
                splitStateVertices[i][0]
            } else {
                // This is a vertex from the inputs
                // We create the input edge and grab its target
                // Get the signal
                let input = inputSignals[i - numberOfStateWires]
                let (inputLabel, inputSubgraph) =
                    match(input) {
                        case DEFINITE(signal) =>
                            // Make a label
                            let signalLabel = GetSignalLabel<V, G>(signal)
                            let signalSubgraph = if(signal.GetWidth() == 1) {
                                None<InterfacedHypergraph<V, G>>
                            } else {
                                MakeSignal<V, G>(signal)
                            }
                            (signalLabel, signalSubgraph)
                        case PARTIAL(pi) =>
                            let partialLabel = Label<V, G>.PARTIAL(pi)
                            let partialSubgraph =
                                None<InterfacedHypergraph<V, G>>
                            (partialLabel, partialSubgraph)
                    }
                let inputTarget = Vertex<V, G>(input.GetWidth(), None)
                // Create the signal
                let inputEdge = Edge(
                    inputLabel, Array<Vertex<V, G>>(), [inputTarget],
                    inputSubgraph, coreEdge.GetGraph()
                )
                // The target of this edge will need to be traversed
                // during rewriting
                rewriteStartingElements.put(VERTEX(inputTarget))
                inputTarget
            }
        }
    )
}
/**
 * Create the new join and delay edges that will root the output of the circuit
 * at this tick. The first source of the join is the output at this tick and the
 * second source is the delay and the next outputs.
 *
 * @param graph
 * @param latestDelayVertices
 * @param latestInstantVertices
 * @param rewriteEndingElements
 * @return The array of join edges
 */
func CreateOutputJoinEdges<V, G>(
    graph : Hypergraph<V, G>,
    latestDelayVertices : Array<Vertex<V, G>>,
    latestInstantVertices : Array<Vertex<V, G>>,
    rewriteEndingElements : HashSet<TraversalElement<V, G>>
) : Array<Edge<V, G>> where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    mapi(
        { v : Vertex<V, G>, i : Int64 =>
            // Split this vertex, as we are going to insert a register
            let (leftVertex, rightVertex) = v.SplitVertex()
            let outputWidth = v.GetWidth()
            let delayTarget = Vertex<V, G>(outputWidth, Some(graph))
            let delayEdge = Edge(
                DELAY(outputWidth), [leftVertex], [delayTarget], None, graph
            )
            latestDelayVertices[i] = leftVertex
            // Create the instant component for this register
            let outputTarget = Vertex<V, G>(outputWidth, Some(graph))
            latestInstantVertices[i] = outputTarget
            // Create the join for this register
            let joinEdge = Edge(
                JOIN(outputWidth), [outputTarget, delayTarget],
                [rightVertex], None, graph
            )
            rewriteEndingElements.put(VERTEX(outputTarget))
            joinEdge
        }, latestDelayVertices
    )
}
/**
 * Get an array of vertices that will make up the targets of the cloned core for
 * reduction at this tick of the clock. In particular, this is the current
 * state vertices which should have already been split, and the targets of new
 * signal edges made based on the array of signals passed in.
 *
 * @param coreEdge
 * @param numberOfStateWires
 * @param latestDelayVertices
 * @param latestInstantVertices
 * @param splitStateVertices
 * @param latestInstantVertices
 * @return An array of source vertices for a cloned core
 */
public func GetCoreTargetVertices<V, G>(
    coreEdge : Edge<V, G>,
    numberOfStateWires : Int64,
    splitStateVertices : Array<(Vertex<V, G>, Vertex<V, G>)>,
    latestInstantVertices : Array<Vertex<V, G>>
) : Array<Vertex<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Array<Vertex<V, G>>(coreEdge.GetCoarity()) {
        i : Int64 =>
            // The targets of the cloned core edge are paritioned between
            // the state transition and the outputs. If we are getting the
            // target for a state transition, we just use the right vertex
            // of the split state we made earlier. If we are getting the
            // target for an output, we split the corresponding output
            // vertex and insert a register, the instnat component of which
            // is the target we are getting.
            if(i < numberOfStateWires) {
                splitStateVertices[i][1]
            } else {
                latestInstantVertices[i - numberOfStateWires]
            }
    }
}
/**
 * Get the array of outputs of a graph from a given source of some edge.
 *
 * @param edges The array of join edges for the desired tick of the clock
 * @param i The index of the source that the output feeds into
 * @return An array of outputs
 */
func GetOutputData<V, G>(
    outputSubgraphs : Array<InterfacedHypergraph<V, G>>
) : Array<OutputData<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    map(
        { f =>
            let term = GetOutputTerm(f.GetOutput(0).GetVertex())
            OutputData<V, G>(term, f)
        }, outputSubgraphs
    )
}
/**
 * Update the various input-output history data structures with the latest
 * input and output signals. The output signals may be None if there is not
 * enough information to compute them.
 *
 * @param graph
 * @param inputSignals
 * @param latestInstantVertices
 * @param history
 */
func UpdateInputOutputHistory<V, G>(
    graph : InterfacedHypergraph<V, G>,
    inputSignals : Array<CycleInput<V>>,
    outputSubgraphs : Array<InterfacedHypergraph<V, G>>,
    history : InputOutputHistory<V, G>
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    let outputData = GetOutputData(outputSubgraphs)
    history.inputHistoryPerTick.append(inputSignals)
    history.outputHistoryPerTick.append(outputData)
    let inputOutput = InputOutput(inputSignals, outputData)
    history.inputOutputHistoryPerTick.append(inputOutput)
    for(i in 0..graph.GetArity()) {
        history.inputHistoryPerPort[i].append(inputSignals[i])
    }
    for(i in 0..graph.GetCoarity()) {
        history.outputHistoryPerPort[i].append(outputData[i])
    }
}
/**
 * Collapse the instantaneous component of a register join into a subgraph.
 *
 * @param rootVertex
 * @param label
 * @param tick The tick of the clock this output is for
 * @param index The index of the graph outputs this is for
 */
func CollapseSingleOutput<V, G>(
    rootVertex : Vertex<V, G>, label : Label<V, G>, tick : Int64, index : Int64
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let (subgraph, _) = rootVertex.GetGraph().CollapseSubgraph(
        Array<TentacleOrigin<V, G>>(),
        [FROM_EDGE(rootVertex.GetInEdge().getOrThrow())],
        "${label.GetName()}[${index}] @ ${tick}"
    )
    subgraph
}
/**
 * Collapse the instantaneous component of an array of register joins into a
 * subgraph.
 *
 * @param joinEdges
 * @param label
 * @param tick The tick of the clock this output is for
 */
func CollapseOutputs<V, G>(
    joinEdges : Array<Edge<V, G>>, label : Label<V, G>, tick : Int64
) : Array<InterfacedHypergraph<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    mapi(
        { e : Edge<V, G>, i : Int64 =>
            CollapseSingleOutput(e.GetSource(0), label, tick, i)
        },
        joinEdges
    )
}
/**
 * Perform a cycle of the circuit in evaluator form given some input signals.
 *
 * @param graph
 * @param inputSignals
 * @param signature
 * @param coreEdge
 * @param numberOfStateWires
 * @param latestInstantVertices
 * @param latestDelayVertices
 */
func PerformCycle<V, G>(
    graph : InterfacedHypergraph<V, G>, inputSignals : Array<CycleInput<V>>,
    signature : Signature<V, G>, coreEdge : Edge<V, G>,
    numberOfStateWires : Int64, latestInstantVertices : Array<Vertex<V, G>>,
    latestDelayVertices : Array<Vertex<V, G>>,
    history : InputOutputHistory<V, G>, debug : Bool, draw!: Bool = false
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    // Can only perform a cycle for the right number of inputs
    AssertHasInputs(graph, inputSignals.size)
    // Track the elements we will be starting and ending the rewrite later
    let rewriteStartingElements = HashSet<TraversalElement<V, G>>()
    let rewriteEndingElements = HashSet<TraversalElement<V, G>>()
    // Split the state vertices so we can insert the next state
    let splitJoinVertices = SplitCurrentState(
        coreEdge, numberOfStateWires,
        rewriteStartingElements, rewriteEndingElements
    )
    let currentJoinEdges = CreateOutputJoinEdges(
        graph.GetGraph(), latestDelayVertices, latestInstantVertices,
        rewriteEndingElements
    )
    // The next step is to clone the core so we can attach the current state
    // and input values to it and reduce appropriately.
    // To do this we need to get or create the vertices that will make up
    // its inputs and outputs.
    let coreCopyInputs = GetCoreSourceVertices(
        coreEdge, numberOfStateWires, inputSignals, splitJoinVertices,
        rewriteStartingElements
    )
    let coreCopyOutputs = GetCoreTargetVertices(
        coreEdge, numberOfStateWires, splitJoinVertices, latestInstantVertices
    )
    // Now we can actually clone the core edge and attach it to the inputs
    // and outputs we just made
    let coreCopyEdge = coreEdge.Clone(
        coreCopyInputs, coreCopyOutputs, graph.GetGraph()
    )
    // Rewrite the copy of the combinational core. We want to
    // force blackboxes as much as possible to the right so that each
    // element of the state is isolated. Moreover, since the core is
    // guaranteed to be capped off with values, we can safely apply
    // instantaneous rules
    RewriteCombinational(
        signature, graph, rewriteStartingElements, rewriteEndingElements,
        copyBlackBoxes: true, allInstantaneous: true, debug: debug, draw: draw
    )
    let outputSubgraphs = CollapseOutputs(
        currentJoinEdges, graph.GetLabel(), history.GetCurrentTick()
    )
    // Look at what we've just done and update the input output history
    UpdateInputOutputHistory(
        graph, inputSignals, outputSubgraphs, history
    )
}
extend Evaluator<V, G> {
    public func PerformCycle(
        inputs : Array<CycleInput<V>>, debug!: Bool = false,  draw!: Bool = false
    ) : Unit {
        PerformCycle<V, G>(
            this.graph, inputs, this.sig, this.coreEdge,
            this.numberOfStateWires, this.latestInstantVertices,
            this.latestDelayVertices, this.history, debug, draw: draw
        )
        // We're done!
        this.currentCycle++
    }
    /**
     * Perform a cycle using this evaluator for some given input signals.
     *
     * @param signals The array of input signals to process
     * @param debug
     */
    public func PerformCycle(
        signals : Array<Signal<V>>, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        let inputs = map({ s : Signal<V> => DEFINITE(s) }, signals)
        PerformCycle(inputs, debug: debug, draw: draw)
    }
    /**
     * Perform a cycle using this evaluator for some given input values.
     *
     * @param values The array of input values to process
     */
    public func PerformCycle(
        values : Array<V>, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        let inputSignals = map({ v : V => Signal(v) }, values)
        this.PerformCycle(inputSignals, debug: debug, draw: draw)
    }
    /**
     * Perform a cycle using this evaluator for a given input signal.
     *
     * @param signal
     * @param debug
     */
    public func PerformCycle(
        signal : Signal<V>, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, 1)
        this.PerformCycle([signal], debug: debug, draw: draw)
    }
    /**
     * Perform a cycle using this evaluator for a given input value.
     *
     * @param value
     * @param debug
     */
    public func PerformCycle(
        value : V, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, 1)
        this.PerformCycle(Signal(value), debug: debug, draw: draw)
    }
    /**
     * Perform several cycles using this evaluator for a given array of signals
     * at each tick of the clock.
     *
     * @param signals The array of arrays of input signals to process at each
     *                  subsequent tick of the clock
     */
    public func PerformCycles(
        signalsPerTick: Array<Array<CycleInput<V>>>, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        for(signals in signalsPerTick) {
            this.PerformCycle(signals, debug: debug, draw: draw)
        }
    }
    /**
     * Perform several cycles using this evaluator for a given array of values
     * at each tick of the clock.
     *
     * @param signals The array of arrays of input values to process at each
     *                  subsequent tick of the clock
     */
    public func PerformCycles(
        valuesPerTick: Array<Array<V>>, debug!: Bool = false, draw!: Bool = false) : Unit {
        for(values in valuesPerTick) {
            this.PerformCycle(values, debug: debug, draw: draw)
        }
    }
    /**
     * Perform several cycles using this evaluator for a given array of
     * waveforms to provide to each input port.
     *
     * @param waveforms The array of waveforms for each input port
     */
    public func PerformCycles(
        waveforms: Array<Waveform<V>>, debug!: Bool = false, draw!: Bool = false) : Unit {
        let signalsPerTick = ArrayOfInputsToArrayOfTicks(waveforms)
        PerformCycles(signalsPerTick, debug: debug, draw: draw)
    }
    /**
     * Perform several cycles using this evaluator for a waveform to provide to
     * the input port.
     *
     * @param waveforms The array of waveforms for each input port
     */
    public func PerformCycles(
        waveform: Waveform<V>, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, 1)
        PerformCycles([waveform], debug: debug, draw: draw)
    }
    /**
     * Perform several cycles using this evaluator, with the same inputs
     * provided to the input each time.
     *
     * @param signals
     * @param ticks The number of cycles to perform
     */
    public func PerformCycles(
        signals: Array<Signal<V>>, ticks!: Int64, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, signals.size)
        for(_ in 0..ticks) {
            PerformCycle(signals, debug: debug, draw: draw)
        }
    }
    /**
     * Perform several cycles using this evaluator, with the same inputs
     * provided to the input each time.
     *
     * @param signals
     * @param ticks The number of cycles to perform
     */
    public func PerformCycles(
        values: Array<V>, ticks!: Int64, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, values.size)
        for(_ in 0..ticks) {
            PerformCycle(values, debug: debug, draw: draw)
        }
    }
}
extend Evaluator<V, G> where V <: Decimal<V> {
    /**
     * Perform a cycle using this evaluator given numbers to be interpreted as
     * signals.
     *
     * @param inputs
     * @param signed
     * @param debug
     */
    public func PerformCycle(
        inputs : Array<Int64>, signed!: Bool, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, inputs.size)
        let inputSignals = mapi(
            { v : Int64, i : Int64 =>
                V.DecToSignal(
                    v, width: this.graph.GetInput(i).GetWidth(), signed: signed
                )
            },
            inputs
        )
        this.PerformCycle(inputSignals, debug: debug, draw: draw)
    }
    /**
     * Perform a cycle using this evaluator given a number to be interpreted as
     * a signal.
     *
     * @param input
     * @param signed
     * @param debug
     */
    public func PerformCycle(
        input: Int64, signed!: Bool, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, 1)
        this.PerformCycle([input], signed: signed, debug: debug, draw: draw)
    }
    /**
     * Perform multiple cycles using this evaluator given numbers to be
     * interpreted as a signal for a given number of ticks
     *
     * @param inputs
     * @param signed
     * @param ticks
     * @param debug
     */
    public func PerformCycles(
        inputs : Array<Int64>, signed!: Bool, ticks!: Int64,
        debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, inputs.size)
        for(_ in 0..ticks) {
            PerformCycle(inputs, signed: signed, debug: debug, draw: draw)
        }
    }
    /**
     * Perform multiple cycles using this evaluator given a number to be
     * interpreted as a signal for a given number of ticks
     *
     * @param input
     * @param signed
     * @param ticks
     * @param debug
     */
    public func PerformCycles(
        input : Int64, signed!: Bool, ticks!: Int64, debug!: Bool = false, draw!: Bool = false
    ) : Unit {
        AssertHasInputs(this.graph, 1)
        for(_ in 0..ticks) {
            PerformCycle(input, signed: signed, debug: debug, draw: draw)
        }
    }
}