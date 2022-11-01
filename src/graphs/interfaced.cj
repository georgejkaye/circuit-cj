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

/**
    A hypergraph with an interface. Represents a complete circuit with inputs
    and outputs. Interfaced hypergraphs are *immutable*.
 */
public class InterfacedHypergraph<V, G> <: Identifiable & ToString & Specifiable<V> & Equatable<InterfacedHypergraph<V, G>> & HasName
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let uniqueId : Int64 = GetNextId()
    let f : Hypergraph<V, G>
    let inputs : Array<InterfaceVertex<V, G>>
    let outputs : Array<InterfaceVertex<V, G>>
    let label : Label<V, G>
    let name : String
    // These are the edges that we start traversing this graph from
    let startingEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    // For easy checking if a vertex is in the interface
    let inputMap : HashMap<Vertex<V, G>, ArrayList<Int64>> = HashMap<Vertex<V, G>, ArrayList<Int64>>()
    let outputMap : HashMap<Vertex<V, G>, ArrayList<Int64>> = HashMap<Vertex<V, G>, ArrayList<Int64>>()
    public init(
        f : Hypergraph<V, G>,
        inputs : Array<InterfaceVertex<V, G>>,
        outputs: Array<InterfaceVertex<V, G>>,
        label : Label<V, G>
    ){
        this.f = f
        this.inputs = inputs
        this.outputs = outputs
        this.name = label.GetName()
        this.label = label
        this.startingEdges.putAll(f.GetStartingEdges())
        for(i in 0..inputs.size){
            let v = inputs[i].GetVertex()
            for(ec in v.GetOutEdges()){
                startingEdges.put(ec.edge)
            }
            match(inputMap.get(v)) {
                case None =>
                    let vs = ArrayList<Int64>()
                    vs.append(i)
                    inputMap.put(v, vs)
                case Some(vs) => vs.append(i)
            }
        }
        for(i in 0..outputs.size){
            let v = outputs[i].GetVertex()
            match(outputMap.get(v)) {
                case None =>
                    let vs = ArrayList<Int64>()
                    vs.append(i)
                    inputMap.put(v, vs)
                case Some(vs) => vs.append(i)
            }
        }
    }
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
    public func GetStartingEdges() : HashSet<Edge<V, G>> {
        this.startingEdges
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
    public func GetInputPositions(v : Vertex<V, G>) : ArrayList<Int64> {
        match(this.inputMap.get(v)){
            case None => ArrayList<Int64>()
            case Some(ps) => ps
        }
    }
    public func GetOutputPositions(v : Vertex<V, G>) : ArrayList<Int64> {
        match(this.outputMap.get(v)){
            case None => ArrayList<Int64>()
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
    func UpdateInterfaceMap(
        map : HashMap<Vertex<V, G>, ArrayList<Int64>>,
        i : Int64,
        newVertex : Vertex<V, G>,
        oldVertex : Vertex<V, G>
    ) : Unit {
        match(map.get(oldVertex)) {
            case None => ()
            case Some(ps) => ps.remove(i)
        }
        match(map.get(newVertex)) {
            case Some(vs) => vs.append(i)
            case None => map.put(newVertex, ArrayList<Int64>([i]))
        }
    }
    public func ReplaceInput(i : Int64, v : Vertex<V, G>) : Unit {
        let iv = this.GetInput(i)
        this.inputs[i] = InterfaceVertex(v, iv.name)
        UpdateInterfaceMap(inputMap, i, v, iv.vertex)
    }
    public func ReplaceOutput(i : Int64, v : Vertex<V, G>) : Unit {
        let iv = this.GetOutput(i)
        this.outputs[i] = InterfaceVertex(v, iv.name)
        UpdateInterfaceMap(outputMap, i, v, iv.vertex)
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
        this.name
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
    public func RemoveEdge(e : Edge<V, G>, removeVertices : Bool) : Unit {
        this.f.RemoveEdge(e, removeVertices)
    }
    public func RemoveEdge(e : Edge<V, G>, removeSources : Bool, removeTargets : Bool) : Unit {
        this.f.RemoveEdge(e, removeSources, removeTargets)
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
    public func Clone()
        : (Hypergraph<V, G>,
            Array<InterfaceVertex<V, G>>,
            Array<InterfaceVertex<V, G>>,
            HashMap<Vertex<V, G>,
            Vertex<V, G>>,
            HashMap<Edge<V, G>,
            Edge<V, G>>
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
    public func CloneGraph() : (InterfacedHypergraph<V, G>, HashMap<Vertex<V, G>, Vertex<V, G>>, HashMap<Edge<V, G>, Edge<V, G>>) {
        let (newGraph, newInputs, newOutputs, vertexMap, edgeMap) = this.Clone()
        let graph = InterfacedHypergraph(newGraph, newInputs, newOutputs, this.name)
        (graph, vertexMap, edgeMap)
    }
    public func GetLabel() : Label<V, G> {
        this.label
    }
}