/**
 * graphs/interfaced.cj
 *
 * Definition of interfaced hypergraphs
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

import syntax.*

public class InterfaceVertex<V, G> <: Socket & HasTentacle<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public InterfaceVertex(
        public let vertex : Vertex<V, G>,
        public let name : Option<String>
    ){}
    public init(
        w : Int64,
        name : Option<String>
    ){
        this(Vertex(w), name)
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
    public operator func ==(rhs : Socket) : Bool {
        this.GetWidth() == rhs.GetWidth() && this.GetName() == rhs.GetName()
    }
    public operator func !=(rhs : Socket) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        let nameString = match (this.name) {
            case None => ""
            case Some(n) => " (${n})"
        }
        "${vertex}${nameString}"
    }
    public func ToPort() : Port<V> {
        Port(vertex.GetWidth(), name: name)
    }
    public func IsFeedback() : Bool {
        false
    }
    public func IsDelay() : Bool {
        false
    }
}
func AddToInterfaceMap<V, G>(v : Vertex<V, G>, i : Int64, interfaceMap : HashMap<Vertex<V, G>, HashSet<Int64>>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    match(interfaceMap.get(v)) {
        case None =>
            let vs = HashSet<Int64>()
            vs.put(i)
            interfaceMap.put(v, vs)
        case Some(vs) => vs.put(i)
    }
}
/**
    A hypergraph with an interface. Represents a complete circuit with inputs
    and outputs. Interfaced hypergraphs are *immutable*.
 */
public class InterfacedHypergraph<V, G>
    <: Hashable & Identifiable & ToString & Specifiable<V> & Equatable<InterfacedHypergraph<V, G>> & HasName
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let uniqueId : Int64 = GetNextId()
    // The hypergraph being interfaced
    let f : Hypergraph<V, G>
    // Input vertices
    let inputs : Array<InterfaceVertex<V, G>>
    // Output vertices
    let outputs : Array<InterfaceVertex<V, G>>
    // Label for the interfaced hypergraph, to be displayed on its edge
    let label : Label<V, G>
    // Input vertices, vertices with no in edge, edges with no sources
    let leftmostTraversalElements : HashSet<TraversalElement<V, G>> = HashSet<TraversalElement<V, G>>()
    // Output vertices, vertices with no out edges, edges with no targets
    let rightmostTraversalElements : HashSet<TraversalElement<V, G>> = HashSet<TraversalElement<V, G>>()
    // Associates vertices with their positions in the inputs
    let inputMap : HashMap<Vertex<V, G>, HashSet<Int64>> = HashMap<Vertex<V, G>, HashSet<Int64>>()
    // Associates vertices with their positions in the outputs
    let outputMap : HashMap<Vertex<V, G>, HashSet<Int64>> = HashMap<Vertex<V, G>, HashSet<Int64>>()
    // The 'heads' of the circuit: the waveforms that have been computed by rewriting
    let headWaveforms : Array<Option<Edge<V, G>>>
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
        this.outputs = outputs
        this.headWaveforms = Array<Option<Edge<V, G>>>(outputs.size){
            i : Int64 => None
        }
        this.label = label
        this.leftmostTraversalElements.putAll(f.GetLeftmostTraversalElements())
        this.rightmostTraversalElements.putAll(f.GetRightmostTraversalElements())
        for(i in 0..inputs.size){
            let v = inputs[i].GetVertex()
            this.leftmostTraversalElements.put(VERTEX(v))
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
            this.rightmostTraversalElements.put(VERTEX(v))
            match(outputMap.get(v)) {
                case None =>
                    let vs = HashSet<Int64>([i])
                    outputMap.put(v, vs)
                case Some(vs) => vs.put(i)
            }
            v.SetAsOutput(this, i)
            match(v.GetInEdge()){
                case None => ()
                case Some(ec) =>
                    let e = ec.GetEdge()
                    match(e.GetLabel()) {
                        case OPEN_WAVEFORM(signals) => this.headWaveforms[i] = Some(e)
                        case _ => ()
                    }

            }
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
            f,
            inputs,
            outputs,
            COMPOSITE(
                Specification<V>(
                    name,
                    map({ iv : InterfaceVertex<V, G> => Port<V>(iv.GetWidth(), name: iv.GetName() )}, inputs),
                    map({ iv : InterfaceVertex<V, G> => Port<V>(iv.GetWidth(), name: iv.GetName() )}, outputs)
                )
            )
        )
    }
    public func hashCode() : Int64 {
        this.uniqueId
    }
    public func GetId() : Int64 {
        this.uniqueId
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
    public func GetOutputs() : Array<InterfaceVertex<V, G>> {
        this.outputs
    }
    func AddVertexToTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        v : Vertex<V, G>
    ) : Unit {
        traversalElements.put(VERTEX(v))
    }
    public func AddVertexToTraversalElements(
        direction : TraversalDirection,
        v : Vertex<V, G>
    ) : Unit {
        AddVertexToTraversalElements(
            GetTraversalElements(direction),
            v
        )
    }
    func RemoveVertexFromTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        v : Vertex<V, G>
    ) : Unit {
        traversalElements.remove(VERTEX(v))
    }
    public func RemoveVertexFromTraversalElements(
        direction : TraversalDirection,
        v : Vertex<V, G>
    ) : Unit {
        RemoveVertexFromTraversalElements(
            GetTraversalElements(direction),
            v
        )
    }
    func RemoveEdgeFromTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        e : Edge<V, G>
    ) : Unit {
        traversalElements.remove(EDGE(e))
    }
    public func RemoveEdgeFromTraversalElements(
        direction : TraversalDirection,
        e : Edge<V, G>
    ) : Unit {
        RemoveEdgeFromTraversalElements(
            GetTraversalElements(direction),
            e
        )
    }
    func AddEdgeToTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        e : Edge<V, G>
    ) : Unit {
        traversalElements.put(EDGE(e))
    }
    public func AddEdgeToTraversalElements(
        direction : TraversalDirection,
        e : Edge<V, G>
    ) : Unit {
        let elem = EDGE(e)
        match(direction) {
            case LEFT_TO_RIGHT =>
                this.GetLeftmostTraversalElements().put(elem)
            case RIGHT_TO_LEFT =>
                this.GetRightmostTraversalElements().put(elem)
            case BOTH_DIRECTIONS =>
                this.GetLeftmostTraversalElements().put(elem)
                this.GetRightmostTraversalElements().put(elem)
        }
    }
    public func GetLeftmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.leftmostTraversalElements
    }
    public func GetRightmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.rightmostTraversalElements
    }
    public func GetTraversalElements(direction : TraversalDirection) : HashSet<TraversalElement<V, G>> {
        let traversalElements = HashSet<TraversalElement<V, G>>()
        match(direction) {
            case LEFT_TO_RIGHT =>
                traversalElements.putAll(this.GetLeftmostTraversalElements())
            case RIGHT_TO_LEFT =>
                traversalElements.putAll(this.GetRightmostTraversalElements())
            case BOTH_DIRECTIONs =>
                traversalElements.putAll(this.GetLeftmostTraversalElements())
                traversalElements.putAll(this.GetRightmostTraversalElements())
        }
        traversalElements
    }
    public func GetSequentialData() : SequentialData<V, G> {
        this.f.GetSequentialData()
    }
    public func HasNonDelayGuardedFeedback() : Bool {
        this.GetSequentialData().feedbackConnections.size != 0
    }
    public func GetInput(i : Int64) : InterfaceVertex<V, G> {
        AssertGraphHasMinimumInputs(this, i)
        this.inputs[i]
    }
    public func GetOutput(i : Int64) : InterfaceVertex<V, G> {
        AssertGraphHasMinimumOutputs(this, i)
        this.outputs[i]
    }
    public func GetInputPositions(v : Vertex<V, G>) : HashSet<Int64> {
        match(this.inputMap.get(v)){
            case None => HashSet<Int64>()
            case Some(ps) => ps
        }
    }
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
    public func GetInputPorts() : Array<Port<V>> {
        map({ iv : InterfaceVertex<V, G> => iv.ToPort() }, this.inputs )
    }
    public func GetOutputPorts() : Array<Port<V>> {
        map({ iv : InterfaceVertex<V, G> => iv.ToPort() }, this.outputs )
    }
    /**
     * Perform operations associated with changing a vertex in an interface
     *
     * @param interfaceArray The interface being changed
     * @param interfaceMap The map from vertices to their positions in the interface
     * @param i The index of the vertex in the interface
     * @param newVertex The new vertex
     */
    func UpdateInterface(
        interfaceArray : Array<InterfaceVertex<V, G>>,
        interfaceMap : HashMap<Vertex<V, G>, HashSet<Int64>>,
        traversalElements : HashSet<TraversalElement<V, G>>,
        i : Int64,
        newVertex : Vertex<V, G>
    ) : Unit {
        let oldVertex = interfaceArray[i]
        interfaceArray[i] = InterfaceVertex(newVertex, oldVertex.name)
        match(interfaceMap.get(oldVertex.vertex)) {
            case None => ()
            case Some(ps) => ps.remove(i)
        }
        match(interfaceMap.get(newVertex)) {
            case Some(vs) => vs.put(i)
            case None => interfaceMap.put(newVertex, HashSet<Int64>([i]))
        }
        traversalElements.remove(VERTEX(oldVertex.vertex))
        traversalElements.put(VERTEX(newVertex))
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
            this.inputs,
            this.inputMap,
            this.leftmostTraversalElements,
            i,
            newInput
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
            this.outputs,
            this.outputMap,
            this.rightmostTraversalElements,
            i,
            newOutput
        )
        newOutput.SetAsOutput(this, i)
        f.AddVertex(newOutput)
        match(newOutput.GetInEdge()) {
            case None => this.headWaveforms[i] = None
            case Some(ec) =>
                let edge = ec.GetEdge()
                match(edge.GetLabel()) {
                    case OPEN_WAVEFORM(signals) => this.headWaveforms[i] = Some(edge)
                    case _ => this.headWaveforms[i] = None
                }
        }
    }
    public func ReplaceOutputs(vs : ArrayList<Vertex<V, G>>) {
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
    public func AddEdgeAndVertices(e : Edge<V, G>) : Unit {
        this.f.AddEdgeAndVertices(e)
    }
    public func RemoveEdge(e : Edge<V, G>) : Unit {
        this.f.RemoveEdge(e)
    }
    public func RemoveVertex(v : Vertex<V, G>) : Unit {
        this.f.RemoveVertex(v)
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
    public func ReplaceOutputVertices(newOutputs : ArrayList<Vertex<V, G>>) : Unit {
        for(i in 0..this.outputs.size) {
            let currentOutput = this.outputs[i]
            this.outputs.set(i, InterfaceVertex(newOutputs[i], currentOutput.name))
        }
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue<V, G>> {
        let issues = f.WellFormednessCheck()

        func InterfaceCheck(
            array : Array<InterfaceVertex<V, G>>,
            notPresent : (Int64, InterfaceVertex<V, G>) -> WellformednessIssue<V, G>
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
    public operator func ==(right: InterfacedHypergraph<V, G>) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : InterfacedHypergraph<V, G>) : Bool {
        this.GetId() != right.GetId()
    }
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
        func translateVertices(ws : Array<InterfaceVertex<V, G>>) : Array<InterfaceVertex<V, G>> {
            map({ iv : InterfaceVertex<V, G> =>
                let v = vertexMap[iv.GetVertex()]
                let name = v.GetName()
                InterfaceVertex(v, name)
            }, ws)
        }
        let newInputs = translateVertices(this.inputs)
        let newOutputs = translateVertices(this.outputs)
        (newF, newInputs, newOutputs, vertexMap, edgeMap)
    }
    public func Clone() : InterfacedHypergraph<V, G> {
        let (newGraph, newInputs, newOutputs, vertexMap, edgeMap) = this.CloneGraph()
        InterfacedHypergraph(newGraph, newInputs, newOutputs, this.GetName())
    }
    public func GetLabel() : Label<V, G> {
        this.label
    }
    public func GetShortestHead() : Int64 {
        fold_left(
            { acc : Int64, cur : InterfaceVertex<V, G> =>
                match(cur.GetVertex().GetInEdge()){
                    case None => 0
                    case Some(ec) =>
                        let edge = ec.GetEdge()
                        match(edge.GetLabel()) {
                            case OPEN_WAVEFORM(signals) => signals.size
                            case _ => 0
                        }
                }
            },
            MAX_INT64,
            this.GetOutputs()
        )
    }
    public func GetHeadWaveform(i : Int64) : Option<Edge<V, G>> {
        this.headWaveforms[i]
    }
}