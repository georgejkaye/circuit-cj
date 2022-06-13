package graphs

import prelude.*

from std import collection.HashSet
from std import collection.ArrayList

public enum WellformednessIssue {
    | InputNotAssigned(Int64)
    | OutputNotAssigned(Int64)
    | InputNotInGraph(Int64, Vertex)
    | OutputNotInGraph(Int64, Vertex)
    | SourceNotAssigned(Edge, Int64)
    | TargetNotAssigned(Edge, Int64)
    | SourceNotInGraph(Edge, Int64, Vertex)
    | TargetNotInGraph(Edge, Int64, Vertex)
}

extend WellformednessIssue <: ToString {
    public func toString() : String {
        match(this) {
            case InputNotAssigned(i) => "Input ${i} is unassigned"
            case OutputNotAssigned(i) => "Output ${i} is unassigned"
            case InputNotInGraph(i, v) => "Input ${i} (${v}) not in this graph"
            case OutputNotInGraph(i, v) => "Output ${i} (${v}) not in this graph"
            case SourceNotAssigned(e, i) => "Source ${i} of edge ${e} is unassigned"
            case TargetNotAssigned(e, i) => "Target ${i} of edge ${e} is unassigned"
            case SourceNotInGraph(e, i, v) => "Source ${i} of edge ${e} (${v}) is not in this graph"
            case TargetNotInGraph(e, i, v) => "Target ${i} of edge ${e} (${v}) is not in this graph"
        }
    }
}

public class Hypergraph <: Identifiable & ToString & Nameable & Equatable<Hypergraph> {
    
    let uniqueId : Identifier = Identifier()
    let name : String
    let vertices : HashSet<Vertex>
    let edges : HashSet<Edge>

    var active : Bool = true

    public init (vertices : HashSet<Vertex>, edges : HashSet<Edge>){
        this.vertices = vertices
        this.edges = edges
        this.name = "h${this.uniqueId}"

        for (v in this.vertices) {
            v.SetOwner(this)
        }
        for (e in this.edges) {
            e.RemoveAndSetOwner(this)
        }
    }

    public func IsActive() : Bool {
        this.active
    }
    public func Deactivate() : Unit {
        this.active = false
        for (e in edges) {
            e.RemoveOwner()
        }
        for (v in vertices) {
            v.RemoveOwner()
        }
    }
    public func GetEdges() : HashSet<Edge> {
        this.edges
    }
    public func AddEdge(e : Edge) : Unit {
        this.edges.put(e)
        e.ForEachSourceAndTarget({ v : Vertex => this.vertices.put(v)})
        e.RemoveAndSetOwner(this)
    }
    public func GetVertices() : HashSet<Vertex> {
        this.vertices
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size() == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {

        let issues = ArrayList<WellformednessIssue>()

        func EdgeVertexCheck(
            e : Edge,
            array : Array<Option<Vertex>>,
            notAssigned : (Edge, Int64) -> WellformednessIssue, 
            notPresent : (Edge, Int64, Vertex) -> WellformednessIssue
        ){
            for (i in 0..array.size()) {
                let vOpt : Option<Vertex> = array[i]
                match(vOpt) {
                    case None    => issues.add(notAssigned(e, i))
                    case Some(v) =>
                        if (!this.vertices.contains(v)) {
                            issues.add(notPresent(e, i, v))
                        }
                }
            }
        }
        for (e in this.edges) {
            EdgeVertexCheck(
                e, 
                e.GetSources(), 
                { e, i => SourceNotAssigned(e,i) }, 
                { e, i, v => SourceNotInGraph(e,i,v)}
            )
            EdgeVertexCheck(
                e, 
                e.GetTargets(), 
                { e, i => TargetNotAssigned(e,i) },
                { e, i, v => TargetNotInGraph(e,i,v) }
            )
        }
        issues
    }
    public func toString() : String {
        let vertexString = this.vertices.toString()
        let edgeString = this.edges.toString()
        let sourceTargetString = fold_left(
            { acc : String , e : Edge => 
                func EdgeVertexString (
                    name : String,
                    array: Array<Option<Vertex>>
                ){
                    foldi_left(
                        { acc : String , v : Option<Vertex>, i : Int64 => 
                            let str = match(v) {
                                case None => "-"
                                case Some(v1) => "${v1}"
                            }
                            let acc = if (acc == "") {
                                ""
                            } else {
                                "${acc}  "
                            }
                            "${acc}${name}(${e},${i}) = ${str}"},
                        "",
                        array
                    )
                }
                let sources = EdgeVertexString("s", e.GetSources())
                let targets = EdgeVertexString("t", e.GetTargets())
                let edgeVertexString = "${sources}  ${targets}"
                if (acc == "") {
                    "${edgeVertexString}"
                } else {
                    "${acc}\n${edgeVertexString}"
                }
            },
            "",
            this.edges
        )
        "V = ${vertexString}\nE = ${edgeString}"
    }
    public func GetId() : Int64 {
        this.uniqueId.GetId()
    }
    public func GetName() : String {
        "hg${this.uniqueId.GetId()}"
    }
    public operator func ==(right: Hypergraph) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Hypergraph) : Bool {
        this.GetId() != right.GetId()
    }
}

public class InterfacedHypergraph <: Identifiable & ToString & Nameable & InputOutput & Equatable<InterfacedHypergraph> {

    let uniqueId : Identifier = Identifier()
    let f : Hypergraph
    let inputs : Array<Option<Vertex>>
    let outputs : Array<Option<Vertex>>

    public init(f : Hypergraph, inputs : Array<Option<Vertex>>, outputs: Array<Option<Vertex>>){
        this.f = f
        this.inputs = inputs
        this.outputs = outputs
    }
    public init(f : Hypergraph, inputs : Array<Vertex>, outputs : Array<Vertex>){
        this(
            f,
            map({ v : Vertex => Some(v) }, inputs),
            map({ v : Vertex => Some(v) }, outputs)
        )
    }
    public func GetId() : Int64 {
        this.uniqueId.GetId()
    }
    public func GetVertices() : HashSet<Vertex> {
        this.f.GetVertices()
    }
    public func GetEdges() : HashSet<Edge> {
        this.f.GetEdges()
    }
    public func GetInputVertices() : Array<Option<Vertex>> {
        this.inputs
    }
    public func GetOutputVertices() : Array<Option<Vertex>> {
        this.outputs
    }
    public func GetInputs() : Int64 {
        this.inputs.size()
    }
    public func GetOutputs() : Int64 {
        this.outputs.size()
    }
    public func GetName() : String {
        this.f.name
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
            list : Array<Option<Vertex>>,
            notAssigned : (Int64) -> WellformednessIssue,
            notPresent : (Int64, Vertex) -> WellformednessIssue
        ) : Unit {
            for (i in 0..list.size()) {
                match (list[i]) {
                    case None => issues.add(notAssigned(i))
                    case Some(v) =>
                        if (!f.GetVertices().contains(v)){
                            issues.add(notPresent(i, v))
                        }
                }
            }
        }
        InterfaceCheck(this.inputs, { i => InputNotAssigned(i) }, { i, v => InputNotInGraph(i, v) })
        InterfaceCheck(this.outputs, {i => InputNotAssigned(i) }, { i, v => OutputNotInGraph(i, v) })

        issues
    }
    public operator func ==(right: InterfacedHypergraph) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : InterfacedHypergraph) : Bool {
        this.GetId() != right.GetId()
    }
}