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

public class InterfaceVertex <: Socket & HasTentacle {
    public InterfaceVertex(
        public let vertex : Vertex,
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
    public func GetVertex() : Vertex {
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
    public func ToPort() : Port {
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
public class InterfacedHypergraph <: Identifiable & ToString & Specifiable & Equatable<InterfacedHypergraph> & HasName {
    let uniqueId : Int64 = GetNextId()
    let f : Hypergraph
    let inputs : Array<InterfaceVertex>
    let outputs : Array<InterfaceVertex>
    let label : Label
    let name : String
    // These are the edges that we start traversing this graph from
    let startingEdges : HashSet<Edge> = HashSet<Edge>()
    // For easy checking if a vertex is in the interface
    let inputMap : HashMap<Vertex, ArrayList<Int64>> = HashMap<Vertex, ArrayList<Int64>>()
    let outputMap : HashMap<Vertex, ArrayList<Int64>> = HashMap<Vertex, ArrayList<Int64>>()
    public init(
        f : Hypergraph,
        inputs : Array<InterfaceVertex>,
        outputs: Array<InterfaceVertex>,
        label : Label
    ){
        this.f = f
        this.inputs = inputs
        this.outputs = outputs
        this.name = label.GetName()
        this.label = label
        this.startingEdges.putAll(f.GetStartingEdges())
        for(i in 0..inputs.size()){
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
        for(i in 0..outputs.size()){
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
        f : Hypergraph,
        inputs : Array<InterfaceVertex>,
        outputs : Array<InterfaceVertex>,
        name : String
    ){
        this(
            f,
            inputs,
            outputs,
            COMPOSITE(
                Specification(
                    name,
                    map({ iv : InterfaceVertex => Port(iv.GetWidth(), name: iv.GetName() )}, inputs),
                    map({ iv : InterfaceVertex => Port(iv.GetWidth(), name: iv.GetName() )}, outputs)
                )
            )
        )
    }
    public func GetId() : Int64 {
        this.uniqueId
    }
    public func GetGraph() : Hypergraph {
        this.f
    }
    public func GetVertices() : HashSet<Vertex> {
        this.f.GetVertices()
    }
    public func GetEdges() : HashSet<Edge> {
        this.f.GetEdges()
    }
    public func GetInputVertices() : Array<InterfaceVertex> {
        this.inputs
    }
    public func GetOutputVertices() : Array<InterfaceVertex> {
        this.outputs
    }
    public func GetStartingEdges() : HashSet<Edge> {
        this.startingEdges
    }
    public func GetSequentialData() : SequentialData {
        this.f.GetSequentialData()
    }
    public func HasNonDelayGuardedFeedback() : Bool {
        this.GetSequentialData().feedbackConnections.size() != 0
    }
    public func GetInput(i : Int64) : InterfaceVertex {
        AssertGraphHasMinimumInputs(this, i)
        this.inputs[i]
    }
    public func GetOutput(i : Int64) : InterfaceVertex {
        AssertGraphHasMinimumOutputs(this, i)
        this.outputs[i]
    }
    public func GetInputPositions(v : Vertex) : ArrayList<Int64> {
        match(this.inputMap.get(v)){
            case None => ArrayList<Int64>()
            case Some(ps) => ps
        }
    }
    public func GetOutputPositions(v : Vertex) : ArrayList<Int64> {
        match(this.outputMap.get(v)){
            case None => ArrayList<Int64>()
            case Some(ps) => ps
        }
    }
    public func GetInputs() : Int64 {
        this.inputs.size()
    }
    public func GetOutputs() : Int64 {
        this.outputs.size()
    }
    public func GetInputPorts() : Array<Port> {
        map({ iv : InterfaceVertex => iv.ToPort() }, this.inputs )
    }
    public func GetOutputPorts() : Array<Port> {
        map({ iv : InterfaceVertex => iv.ToPort() }, this.outputs )
    }
    public func ReplaceInput(i : Int64, v : Vertex) : Unit {
        let iv = this.GetInput(i)
        this.inputs[i] = InterfaceVertex(v, iv.name)
    }
    public func ReplaceOutput(i : Int64, v : Vertex) : Unit {
        let iv = this.GetOutput(i)
        this.outputs[i] = InterfaceVertex(v, iv.name)
    }
    public func ReplaceOutputs(vs : ArrayList<Vertex>) {
        for(i in 0..vs.size()) {
            ReplaceOutput(i, vs[i])
        }
    }
    public func IsCombinational() : Bool {
        this.f.IsCombinational()
    }
    public func GetName() : String {
        this.name
    }
    public func AddEdge(e : Edge) : Unit {
        this.f.AddEdge(e)
    }
    public func AddEdgeAndVertices(e : Edge) : Unit {
        this.f.AddEdgeAndVertices(e)
    }
    public func RemoveEdge(e : Edge) : Unit {
        this.f.RemoveEdge(e)
    }
    public func toString() : String {
        let string = f.toString()
        "${string} (${this.inputs} -> ${this.outputs})"
    }
    public func toLongString() : String {
        let string = f.toLongString()
        "${string}\ninputs ${this.inputs}\noutputs ${this.outputs}"
    }
    public func ReplaceOutputVertices(newOutputs : ArrayList<Vertex>) : Unit {
        for(i in 0..this.outputs.size()) {
            let currentOutput = this.outputs[i]
            this.outputs.set(i, InterfaceVertex(newOutputs[i], currentOutput.name))
        }
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size() == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {
        let issues = f.WellFormednessCheck()

        func InterfaceCheck(
            array : Array<InterfaceVertex>,
            notPresent : (Int64, InterfaceVertex) -> WellformednessIssue
        ) : Unit {
            for (i in 0..array.size()) {
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
    public operator func ==(right: InterfacedHypergraph) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : InterfacedHypergraph) : Bool {
        this.GetId() != right.GetId()
    }
    public func Clone()
        : (Hypergraph, Array<InterfaceVertex>, Array<InterfaceVertex>, HashMap<Vertex, Vertex>, HashMap<Edge, Edge>) {
         let (newF, vertexMap, edgeMap) = f.Clone()
        /**
        * Given an array of vertices, create an array of the corresponding
        * vertices in a cloned hypergraph
        * @param ws The array of vertices
        */
        func translateVertices(ws : Array<InterfaceVertex>) : Array<InterfaceVertex> {
            map({ iv : InterfaceVertex =>
                let v = vertexMap[iv.GetVertex()]
                let name = v.GetName()
                InterfaceVertex(v, name)
            }, ws)
        }
        let newInputs = translateVertices(this.inputs)
        let newOutputs = translateVertices(this.outputs)
        (newF, newInputs, newOutputs, vertexMap, edgeMap)
    }
    public func CloneGraph() : (InterfacedHypergraph, HashMap<Vertex, Vertex>, HashMap<Edge, Edge>) {
        let (newGraph, newInputs, newOutputs, vertexMap, edgeMap) = this.Clone()
        let graph = InterfacedHypergraph(newGraph, newInputs, newOutputs, this.name)
        (graph, vertexMap, edgeMap)
    }
    public func GetLabel() : Label {
        this.label
    }
}