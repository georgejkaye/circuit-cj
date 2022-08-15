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

/**
 * Clone a(n uninterfaced) hypergraph with some given input and output arrays
 *
 * @param f The uninterfaced hypergraph
 * @param inputs The array of inputs
 * @param outputs The array of outputs
 * @return A tuple (hypergraph, inputs, outputs)
 */
public func CloneWithInterfaces<T>(
    f : Hypergraph,
    inputs: Array<T>,
    outputs: Array<T>
) : (Hypergraph, Array<InterfaceVertex>, Array<InterfaceVertex>) where
  T <: ContainsVertex, T <: Socket {
    let (newF, vertexMap, edgeMap) = f.Clone()

    /**
     * Given an array of vertices, create an array of the corresponding
     * vertices in a cloned hypergraph
     * @param ws The array of vertices
     */
    func translateVertices(ws : Array<T>) : Array<InterfaceVertex> {
        map({ t : T =>
            let v = vertexMap[t.GetVertex()]
            let name = t.GetName()
            InterfaceVertex(v, name)
        }, ws)
    }
    let newInputs = translateVertices(inputs)
    let newOutputs = translateVertices(outputs)
    (newF, newInputs, newOutputs)
}

public class InterfaceVertex <: Socket & ContainsVertex {
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
        "${vertex} (${name})"
    }
}

/**
    A hypergraph with an interface. Represents a complete circuit with inputs
    and outputs. Interfaced hypergraphs are *immutable*.
 */
public class InterfacedHypergraph <: Identifiable & ToString & Specifiable & Equatable<InterfacedHypergraph> {
    let uniqueId : Int64 = GetNextId()
    let f : Hypergraph
    let inputs : Array<InterfaceVertex>
    let outputs : Array<InterfaceVertex>
    let label : Label
    let name : Option<String>
    public init(
        f : Hypergraph,
        inputs : Array<InterfaceVertex>,
        outputs: Array<InterfaceVertex>,
        label : Label
    ){
        this.f = f
        this.inputs = inputs
        this.outputs = outputs
        this.name = match(label.GetName()) {
            case None => "h${uniqueId}"
            case Some(s) => s
        }
        this.label = label
    }
    public init(
        f : Hypergraph,
        inputs : Array<InterfaceVertex>,
        outputs : Array<InterfaceVertex>,
        name : Option<String>
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
    public func GetInput(i : Int64) : InterfaceVertex {
        AssertGraphHasMinimumInputs(this, i)
        this.inputs[i]
    }
    public func GetOutput(i : Int64) : InterfaceVertex {
        AssertGraphHasMinimumOutputs(this, i)
        this.outputs[i]
    }
    public func GetInputs() : Int64 {
        this.inputs.size
    }
    public func GetOutputs() : Int64 {
        this.outputs.size
    }
    public func GetInputPorts() : Array<Socket> {
        (this.inputs as Array<Socket>).getOrThrow()
    }
    public func GetOutputPorts() : Array<Socket> {
        (this.outputs as Array<Socket>).getOrThrow()
    }
    public func GetName() : Option<String> {
        this.name
    }
    public func toString() : String {
        let string = f.toString()
        "${string}\ninputs ${this.inputs}\noutputs ${this.outputs}"
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {
        let issues = f.WellFormednessCheck()

        func InterfaceCheck(
            array : Array<InterfaceVertex>,
            notPresent : (Int64, InterfaceVertex) -> WellformednessIssue
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
    public operator func ==(right: InterfacedHypergraph) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : InterfacedHypergraph) : Bool {
        this.GetId() != right.GetId()
    }
    public func Clone() : (Hypergraph, Array<InterfaceVertex>, Array<InterfaceVertex>) {
         CloneWithInterfaces<InterfaceVertex>(this.f, this.inputs, this.outputs)
    }
    public func CloneGraph() : InterfacedHypergraph {
        let (newGraph, newInputs, newOutputs) = this.Clone()
        InterfacedHypergraph(newGraph, newInputs, newOutputs, this.name)
    }
    public func GetLabel() : Label {
        this.label
    }
}