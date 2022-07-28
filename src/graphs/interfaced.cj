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
public func CloneWithInterfaces(
    f : Hypergraph,
    inputs: Array<Vertex>,
    outputs: Array<Vertex>
) : (Hypergraph, Array<Vertex>, Array<Vertex>) {
    let (newF, vertexMap, edgeMap) = f.Clone()

    /**
     * Given an array of vertices, create an array of the corresponding
     * vertices in a cloned hypergraph
     * @param ws The array of vertices
     */
    func translateVertices(ws : Array<Vertex>) : Array<Vertex> {
        map({ w : Vertex => vertexMap[w] }, ws)
    }
    let newInputs = translateVertices(inputs)
    let newOutputs = translateVertices(outputs)
    (newF, newInputs, newOutputs)
}

/**
    A hypergraph with an interface. Represents a complete circuit with inputs
    and outputs. Interfaced hypergraphs are *immutable*.
 */
public class InterfacedHypergraph <: Identifiable & ToString & Specifiable & Equatable<InterfacedHypergraph> {
    let uniqueId : Int64 = GetNextId()
    let f : Hypergraph
    let inputs : Array<Vertex>
    let outputs : Array<Vertex>
    let spec : Specifiable
    public init(
        f : Hypergraph,
        spec : Specifiable,
        inputs : Array<Vertex>,
        outputs: Array<Vertex>
        
    ){
        CheckSpecCompatibility(spec, inputs, outputs)
        this.f = f
        this.inputs = inputs
        this.outputs = outputs
        this.spec = spec
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
    public func GetInputVertices() : Array<Vertex> {
        this.inputs
    }
    public func GetOutputVertices() : Array<Vertex> {
        this.outputs
    }
    public func GetInput(i : Int64) : Vertex {
        AssertGraphHasMinimumInputs(this, i)
        this.inputs[i]
    }
    public func GetOutput(i : Int64) : Vertex {
        AssertGraphHasMinimumOutputs(this, i)
        this.outputs[i]
    }
    public func GetInputs() : Int64 {
        this.inputs.size()
    }
    public func GetOutputs() : Int64 {
        this.outputs.size()
    }
    public func GetInputPorts() : Array<Port> {
        this.spec.GetInputPorts()
    }
    public func GetOutputPorts() : Array<Port> {
        this.spec.GetOutputPorts()
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func toString() : String {
        let string = f.toString()
        "${string}\ninputs ${this.inputs}\noutputs ${this.outputs}"
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size() == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {
        let issues = f.WellFormednessCheck()

        func InterfaceCheck(
            array : Array<Vertex>,
            notPresent : (Int64, Vertex) -> WellformednessIssue
        ) : Unit {
            for (i in 0..array.size()) {
                let v = array[i]
                if (!f.GetVertices().contains(v)){
                    issues.add(notPresent(i, v))
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
    public func Clone() : (Hypergraph, Array<Vertex>, Array<Vertex>) {
         CloneWithInterfaces(this.f, this.inputs, this.outputs)
    }
    public func CloneGraph() : InterfacedHypergraph {
        let (newGraph, newInputs, newOutputs) = this.Clone()    
        InterfacedHypergraph(newGraph, this.spec, newInputs, newOutputs)
    }
}