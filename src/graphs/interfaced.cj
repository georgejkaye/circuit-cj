/**
 * graphs/interfaced.cj
 *
 * Definition of interfaced hypergraphs
 *
 * @author George Kaye
 * @since 0.2
 */
package graphs
/**
 * An interface vertex is a pair of a vertex and an optional name.
 */
public class InterfaceVertex<V, G> <: HasPort & ContainsVertex<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public InterfaceVertex(
        let vertex : Vertex<V, G>,
        let name!: Option<String> = None
    ){}
    public init(
        vertex : Vertex<V, G>,
        name : String
    ){
        this(vertex, name: Some(name))
    }
    public operator func ==(rhs : HasPort) : Bool {
        this.GetWidth() == rhs.GetWidth() && this.GetName() == rhs.GetName()
    }
    public operator func !=(rhs : HasPort) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        let nameString = match (this.name) {
            case None => ""
            case Some(n) => " (${n})"
        }
        "${vertex}${nameString}"
    }
    public func GetWidth() : Int64 {
        this.vertex.GetWidth()
    }
    public func GetName() : Option<String> {
        this.name
    }
    public func GetVertex() : Vertex<V, G> {
        this.vertex
    }
}
/**
 * A hypergraph with an interface. Represents a complete circuit with inputs
 * and outputs.
 */
public class InterfacedHypergraph<V, G>
    <: Identifiable<InterfacedHypergraph<V, G>> & ToString &
            Specifiable & HasName
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let uniqueId : Int64 = GetNextId()
    // The hypergraph being interfaced
    let f : Hypergraph<V, G>
    // Input vertices
    let inputs : Array<InterfaceVertex<V, G>>
    // Input vertices as vertices
    let inputVertices : Array<Vertex<V, G>>
    // Output vertices
    let outputs : Array<InterfaceVertex<V, G>>
    // Output vertices as vertices
    let outputVertices : Array<Vertex<V, G>>
    // Label for the interfaced hypergraph, to be displayed on its edge
    let label : Label<V, G>
    // Associates vertices with their positions in the inputs
    let inputMap : HashMap<Vertex<V, G>, HashSet<Int64>> =
        HashMap<Vertex<V, G>, HashSet<Int64>>()
    // Associates vertices with their positions in the outputs
    let outputMap : HashMap<Vertex<V, G>, HashSet<Int64>> =
        HashMap<Vertex<V, G>, HashSet<Int64>>()
    /**
     * Create an interfaced hypergraph with a given label
     *
     * @param f The hypergraph to input
     * @param inputs The inputs for this hypergraph
     * @param outputs The outputs for this hypergraph
     * @param label The label for this hypergraph
     */
    public init(
        f : Hypergraph<V, G>,
        inputs : Array<InterfaceVertex<V, G>>,
        outputs: Array<InterfaceVertex<V, G>>,
        label : Label<V, G>
    ){
        this.f = f
        this.inputs = inputs
        this.inputVertices = map({ v => v.GetVertex() }, inputs)
        this.outputs = outputs
        this.outputVertices = map({ v => v.GetVertex() }, outputs)
        this.label = label
        for(i in 0..inputs.size){
            let v = inputs[i].GetVertex()
            match(inputMap.get(v)) {
                case None =>
                    let vs = HashSet<Int64>([i])
                    inputMap.put(v, vs)
                case Some(vs) => vs.put(i)
            }
            v.SetAsInput(this, i)
        }
        for(i in 0..outputs.size){
            let v = outputs[i].GetVertex()
            match(outputMap.get(v)) {
                case None =>
                    let vs = HashSet<Int64>([i])
                    outputMap.put(v, vs)
                case Some(vs) => vs.put(i)
            }
            v.SetAsOutput(this, i)
        }
        f.AddInterfacedOwner(this)
    }
    /**
     * Create an interfaced hypergraph with a given string as a name: it
     * will be given a COMPOSITE label with this name
     *
     * @param f The hypergraph to input
     * @param inputs The inputs for this hypergraph
     * @param outputs The outputs for this hypergraph
     * @param name The name to give this hypergraph
     */
    public init(
        f : Hypergraph<V, G>,
        inputs : Array<InterfaceVertex<V, G>>,
        outputs : Array<InterfaceVertex<V, G>>,
        name : String
    ){
        this(
            f, inputs, outputs,
            COMPOSITE(
                Specification(
                    name, map(
                        { iv : InterfaceVertex<V, G> =>
                            Port(iv.GetWidth(), name: iv.GetName() )
                        }, inputs
                    ), map(
                        { iv : InterfaceVertex<V, G> =>
                            Port(iv.GetWidth(), name: iv.GetName() )
                        }, outputs
                    )
                )
            )
        )
    }
    public operator func ==(right: InterfacedHypergraph<V, G>) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : InterfacedHypergraph<V, G>) : Bool {
        this.GetId() != right.GetId()
    }
    public func toString() : String {
        let string = f.toString()
        let inputString = PrintWidthArray(this.GetInputs())
        let outputString = PrintWidthArray(this.GetOutputs())
        "${string} (${inputString} -> ${outputString})"
    }
    public func toLongString() : String {
        let string = f.toLongString()
        "${string}\ninputs ${this.inputs}\noutputs ${this.outputs}"
    }
    public func GetId() : Int64 {
        this.uniqueId
    }
    public func GetLabel() : Label<V, G> {
        this.label
    }
    public func GetGraph() : Hypergraph<V, G> {
        this.f
    }
    public func GetVertices() : HashSet<Vertex<V, G>> {
        this.f.GetVertices()
    }
    public func GetEdges() : HashSet<Edge<V, G>> {
        this.f.GetEdges()
    }
    public func GetInputs() : Array<InterfaceVertex<V, G>> {
        this.inputs
    }
    public func GetInputVertices() : Array<Vertex<V, G>> {
        this.inputVertices
    }
    public func GetOutputs() : Array<InterfaceVertex<V, G>> {
        this.outputs
    }
    public func GetOutputVertices() : Array<Vertex<V, G>> {
        this.outputVertices
    }
    public func GetDelayEdges() : HashSet<Edge<V, G>> {
        this.f.GetDelayEdges()
    }
    public func GetValueEdges() : HashSet<Edge<V, G>> {
        this.f.GetValueEdges()
    }
    public func GetDisconnectedEdges() : HashSet<Edge<V, G>> {
        this.f.GetDisconnectedEdges()
    }
    public func GetFeedbackConnections() : HashSet<EdgeConnection<V, G>> {
        this.f.GetFeedbackConnections()
    }
    public func GetSequentialEdges() : HashSet<Edge<V, G>> {
        this.f.GetSequentialEdges()
    }
    public func IsFeedback(ec : EdgeConnection<V, G>) : Bool {
        this.f.IsFeedback(ec)
    }
    public func IsFeedback(e : Edge<V, G>, i : Int64) : Bool {
        this.f.IsFeedback(e, i)
    }
    /**
     * Add a vertex to a set of traversal elements based on a given
     * traversal direction.
     *
     * @param direction
     * @param v
     */
    public func AddVertexToTraversalElements(
        direction : TraversalDirection,
        v : Vertex<V, G>
    ) : Unit {
       this.f.AddVertexToTraversalElements(direction, v)
    }
    /**
     * Add an edge to a set of traversal elements given a traversal direction.
     *
     * @param direction
     * @param e
     */
    public func AddEdgeToTraversalElements(
        direction : TraversalDirection, e : Edge<V, G>
    ) : Unit {
        this.f.AddEdgeToTraversalElements(direction, e)
    }
    /**
     * Remove an edge from a set of traversal elements based on a given
     * traversal direction.
     *
     * @param direction
     * @param e
     */
    public func RemoveEdgeFromTraversalElements(
        direction : TraversalDirection, e : Edge<V, G>
    ) : Unit {
        this.f.RemoveEdgeFromTraversalElements(direction, e)
    }
    public func GetLeftmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.f.GetLeftmostTraversalElements()
    }
    public func GetRightmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.f.GetRightmostTraversalElements()
    }
    /**
     * @param i
     * @return The ith input interface vertex
     */
    public func GetInput(i : Int64) : InterfaceVertex<V, G> {
        AssertGraphHasMinimumInputs(this, i)
        this.inputs[i]
    }
    /**
     * @param i
     * @return The ith output interface vertex
     */
    public func GetOutput(i : Int64) : InterfaceVertex<V, G> {
        AssertGraphHasMinimumOutputs(this, i)
        this.outputs[i]
    }
    /**
     * @param v
     * @return The indices of v in the inputs
     */
    public func GetInputPositions(v : Vertex<V, G>) : HashSet<Int64> {
        match(this.inputMap.get(v)){
            case None => HashSet<Int64>()
            case Some(ps) => ps
        }
    }
    /**
     * @param v
     * @return The indices of v in the outputs
     */
    public func GetOutputPositions(v : Vertex<V, G>) : HashSet<Int64> {
        match(this.outputMap.get(v)){
            case None => HashSet<Int64>()
            case Some(ps) => ps
        }
    }
    public func GetArity() : Int64 {
        this.inputs.size
    }
    public func GetCoarity() : Int64 {
        this.outputs.size
    }
    public func GetInputPorts() : Array<Port> {
        map({ iv : InterfaceVertex<V, G> => iv.ToPort() }, this.inputs )
    }
    public func GetOutputPorts() : Array<Port> {
        map({ iv : InterfaceVertex<V, G> => iv.ToPort() }, this.outputs )
    }
    /**
     * Perform operations associated with changing a vertex in an interface
     *
     * @param interfaceArray The interface being changed
     * @param interfaceMap The map from vertices to their interface positions
     * @param i The index of the vertex in the interface
     * @param newVertex The new vertex
     */
    func UpdateInterface(
        interfaceArray : Array<InterfaceVertex<V, G>>,
        interfaceVertexArray : Array<Vertex<V, G>>,
        interfaceMap : HashMap<Vertex<V, G>, HashSet<Int64>>,
        i : Int64,
        newVertex : Vertex<V, G>
    ) : Unit {
        let oldVertex = interfaceArray[i]
        interfaceArray[i] = InterfaceVertex(
            newVertex, name: oldVertex.GetName()
        )
        interfaceVertexArray[i] = newVertex
        match(interfaceMap.get(oldVertex.vertex)) {
            case None => ()
            case Some(ps) => ps.remove(i)
        }
        match(interfaceMap.get(newVertex)) {
            case Some(vs) => vs.put(i)
            case None => interfaceMap.put(newVertex, HashSet<Int64>([i]))
        }
    }
    /**
     * Replace the input at a given index with a new one
     *
     * @param i The index of the input
     * @param v The new vertex
     */
    public func ReplaceInput(i : Int64, newInput : Vertex<V, G>) : Unit {
        this.GetInput(i).vertex.RemoveAsInput(this, i)
        UpdateInterface(
            this.inputs, this.inputVertices, this.inputMap, i, newInput
        )
        newInput.SetAsInput(this, i)
        f.AddVertex(newInput)
    }
    /**
     * Replace the output at a given index with a new one
     *
     * @param i The index of the output
     * @param v The new vertex
     */
    public func ReplaceOutput(i : Int64, newOutput : Vertex<V, G>) : Unit {
        this.GetOutput(i).vertex.RemoveAsOutput(this, i)
        UpdateInterface(
            this.outputs, this.outputVertices, this.outputMap, i, newOutput
        )
        newOutput.SetAsOutput(this, i)
        f.AddVertex(newOutput)
    }
    /**
     * Replace all of the output vertices with new vertices.
     *
     * @param vs The array of vertices to replace the current outputs
     */
    public func ReplaceOutputs(vs : Array<Vertex<V, G>>) : Unit {
        for(i in 0..vs.size) {
            ReplaceOutput(i, vs[i])
        }
    }
    public func IsCombinational() : Bool {
        this.f.IsCombinational()
    }
    public func GetName() : String {
        this.label.GetName()
    }
    public func AddEdge(e : Edge<V, G>) : Unit {
        this.f.AddEdge(e)
    }
    public func AddVertex(v : Vertex<V, G>) : Unit {
        this.f.AddVertex(v)
    }
    public func RemoveEdge(e : Edge<V, G>) : Unit {
        this.f.RemoveEdge(e)
    }
    public func RemoveVertex(v : Vertex<V, G>) : Unit {
        this.f.RemoveVertex(v)
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue<V, G>> {
        let issues = f.WellFormednessCheck()
        func InterfaceCheck(
            array : Array<InterfaceVertex<V, G>>,
            notPresent : (Int64, InterfaceVertex<V, G>) ->
                                WellformednessIssue<V, G>
        ) : Unit {
            for (i in 0..array.size) {
                let v = array[i]
                if (!f.GetVertices().contains(v.GetVertex())){
                    issues.append(notPresent(i, v))
                }
            }
        }
        InterfaceCheck(this.inputs, { i, v => InputNotInGraph(i, v) })
        InterfaceCheck(this.outputs, { i, v => OutputNotInGraph(i, v) })
        issues
    }
    /**
     * Clone the underlying contents of this interfaced hypergraph.
     *
     * @return A tuple containing:
     *            1) The new hypergraph
     *            2) The new input vertices
     *            3) The new output vertices
     *            4) The map from old vertices to new vertices
     *            5) The map from old edges to new edges
     */
    public func CloneGraph()
        : (Hypergraph<V, G>,
            Array<InterfaceVertex<V, G>>,
            Array<InterfaceVertex<V, G>>,
            HashMap<Vertex<V, G>, Vertex<V, G>>,
            HashMap<Edge<V, G>, Edge<V, G>>
        ) {
        let (newF, vertexMap, edgeMap) = f.Clone()
        /**
        * Given an array of vertices, create an array of the corresponding
        * vertices in a cloned hypergraph
        * @param ws The array of vertices
        */
        func TranslateVertices(
            ws : Array<InterfaceVertex<V, G>>
        ) : Array<InterfaceVertex<V, G>> {
            map({ iv : InterfaceVertex<V, G> =>
                let v = vertexMap[iv.GetVertex()]
                let name = iv.GetName()
                InterfaceVertex(v, name: name)
            }, ws)
        }
        let newInputs = TranslateVertices(this.inputs)
        let newOutputs = TranslateVertices(this.outputs)
        (newF, newInputs, newOutputs, vertexMap, edgeMap)
    }
    /**
     * Clone this interfaced hypergraph
     *
     * @return The new interfaced hypergraph
     */
    public func Clone() : InterfacedHypergraph<V, G> {
        let (newGraph, newInputs, newOutputs, vertexMap, edgeMap) =
            this.CloneGraph()
        InterfacedHypergraph(newGraph, newInputs, newOutputs, this.GetLabel())
    }
    /**
     * Given arrays of inputs and outputs, collapse a subgraph of this graph
     * into its own edge with a given label
     *
     * @param inputs
     * @param outputs
     * @param label
     */
    public func CollapseSubgraph(
        inputs : Array<TentacleOrigin<V, G>>,
        outputs : Array<TentacleOrigin<V, G>>,
        label : Label<V, G>
    ) : (InterfacedHypergraph<V, G>, Edge<V, G>) {
        this.GetGraph().CollapseSubgraph(inputs, outputs, label)
    }
    /**
     * Given arrays of inputs and outputs, collapse a subgraph of this graph
     * into its own edge, labelled with a COMPOSITE label.
     *
     * @param inputs
     * @param outputs
     * @param name The name of the COMPOSITE label
     */
    public func CollapseSubgraph(
        inputs : Array<TentacleOrigin<V, G>>,
        outputs : Array<TentacleOrigin<V, G>>,
        name : String
    ) : (InterfacedHypergraph<V, G>, Edge<V, G>) {
        this.GetGraph().CollapseSubgraph(inputs, outputs, name)
    }
    /**
     * Given some edge connections, collapse a subgraph with inputs these
     * edge connections and the inputs of the graph, and outputs these edge
     * connections and the outputs of the graph.
     *
     * @param connections
     * @param label
     * @return A tuple containing:
     *           1) The array of vertices isolated from the subgraph
     *           2) The newly collapsed edge
     *           3) The collapsed subgraph
     */
    public func IsolateTentacles(
        connections : Array<EdgeConnection<V, G>>,
        label : String
    ) : (Array<Vertex<V, G>>, Edge<V, G>, InterfacedHypergraph<V, G>) {
        // Slice the relevant connections first so that the collapsing of
        // the subgraph does not interfere with their identities
        let slicedVertices = map(SliceTentacle<V, G>, connections)
        let subgraphArity = connections.size + this.GetArity()
        let subgraphCoarity = connections.size + this.GetCoarity()
        let subgraphInputs = concat(
            slicedVertices,
            { vv : (Vertex<V, G>, Vertex<V, G>) => FROM_VERTEX(vv[1]) },
            this.GetInputs(),
            { iv : InterfaceVertex<V, G> => FROM_VERTEX(iv.GetVertex()) }
        )
        let subgraphOutputs = concat(
            slicedVertices,
            { vv : (Vertex<V, G>, Vertex<V, G>) => FROM_VERTEX(vv[0]) },
            this.GetOutputs(),
            { iv : InterfaceVertex<V, G> => FROM_VERTEX(iv.GetVertex()) }
        )
        let (newGraph, newEdge) = this.CollapseSubgraph(
            subgraphInputs, subgraphOutputs, label
        )
        // Now that the subgraph has been collapsed, we can merge the
        // vertices back together
        let mergedVertices = Array<Vertex<V, G>>(slicedVertices.size){
            i : Int64 =>
                let primaryVertex = newEdge.GetSource(i)
                primaryVertex.MergeVertex(newEdge.GetTarget(i))
                primaryVertex
        }
        for(i in 0..connections.size) {
            let ec = connections[i]
            newGraph.GetGraph().RemoveFeedback(ec)
            this.GetGraph().AddFeedback(newEdge, i)
        }
        (mergedVertices, newEdge, newGraph)
    }
}
public interface HasInterfacedGraph<V, G> <: HasGraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func GetInterfacedGraph() : InterfacedHypergraph<V, G>
    func GetGraph() : Hypergraph<V, G> {
        this.GetInterfacedGraph().GetGraph()
    }
    func GetInput(i : Int64) : InterfaceVertex<V, G> {
        this.GetInterfacedGraph().GetInput(i)
    }
    func GetOutput(i : Int64) : InterfaceVertex<V, G> {
        this.GetInterfacedGraph().GetOutput(i)
    }
}
extend InterfacedHypergraph<V, G> <: HasInterfacedGraph<V, G> {
    public func GetInterfacedGraph() : InterfacedHypergraph<V, G> {
        this
    }
}
public func AssertHasInputs<V, G>(
    f : InterfacedHypergraph<V, G>, m : Int64
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    AssertHasLength(f.GetInputs(), m)
}
public func AssertHasOutputs<V, G>(
    f : InterfacedHypergraph<V, G>, n : Int64
) : Unit where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G> {
    AssertHasLength(f.GetOutputs(), n)
}