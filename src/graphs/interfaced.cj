package graphs

import syntax.*

public func CloneWithInterfaces(f : Hypergraph, inputs: Array<Vertex>, outputs: Array<Vertex>) : (Hypergraph, Array<Vertex>, Array<Vertex>) {
    let (newF, vertexMap, edgeMap) = f.Clone()

    func translateVertices(ws : Array<Vertex>, exn : ((Vertex) -> Exception)) : Array<Vertex> {
        map({w : Vertex => unsafeGet(vertexMap, w, exn)}, ws)
    }

    let newInputs = translateVertices(inputs, { v : Vertex => InputNotInHypergraphException("InterfacedHypergraph", f, v)})
    let newOutputs = translateVertices(outputs, { v : Vertex => OutputNotInHypergraphException("InterfacedHypergraph", f, v)})

    (newF, newInputs, newOutputs)
}

/**
    A hypergraph with an interface. Represents a complete circuit with inputs
    and outputs. Interfaced hypergraphs are *immutable*.
 */
public class InterfacedHypergraph <: Identifiable & ToString & Specifiable & Equatable<InterfacedHypergraph> {
    let uniqueId : Identifier = Identifier()
    let f : Hypergraph
    let inputs : Array<Vertex>
    let outputs : Array<Vertex>
    let spec : Specification

    public init(
        f : Hypergraph,
        spec : Specification,
        inputs : Array<Vertex>,
        outputs: Array<Vertex>
    ){
        CheckLabelCompatibility(spec, inputs, outputs)
        this.f = f
        this.inputs = inputs
        this.outputs = outputs
        this.spec = spec
    }
    public func GetId() : Int64 {
        this.uniqueId.GetId()
    }
    public func GetSpecification() : Specification {
        this.spec
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
        if (i >= this.inputs.size()) {
            throw NotEnoughInputsException("GetInput", i, this)
        }
        this.inputs[i]
    }
    public func GetOutput(i : Int64) : Vertex {
        if (i >= this.outputs.size()) {
            throw NotEnoughOutputsException("GetOutput", i, this)
        }
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
        this.spec.name
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