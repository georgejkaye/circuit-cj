package graphs

import prelude.*

from std import collection.ArrayList
from std import collection.HashMap
from std import collection.HashSet

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
        e.ForEachSourceAndTarget({ v : Vertex, i : Int64 => this.vertices.put(v)})
        e.RemoveAndSetOwner(this)
    }
    public func GetVertices() : HashSet<Vertex> {
        this.vertices
    }
    public func AddVertex(v : Vertex) : Unit {
        this.vertices.put(v)
    }
    public func RemoveVertex(v : Vertex) : Unit {
        this.vertices.remove(v)
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size() == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {

        let issues = ArrayList<WellformednessIssue>()

        func EdgeVertexCheck(
            e : Edge,
            array : Array<Vertex>,
            notPresent : (Edge, Int64, Vertex) -> WellformednessIssue
        ){
            for (i in 0..array.size()) {
                let v = array[i]
                if (!this.vertices.contains(v)) {
                    issues.add(notPresent(e, i, v))
                }
            }
        }
        for (e in this.edges) {
            EdgeVertexCheck(
                e, 
                e.GetSources(), 
                { e, i, v => SourceNotInGraph(e,i,v)}
            )
            EdgeVertexCheck(
                e, 
                e.GetTargets(), 
                { e, i, v => TargetNotInGraph(e,i,v) }
            )
        }
        issues
    }
    public func ReplaceVertex(v : Vertex, w : Vertex) : Unit {
        this.vertices.remove(v)
        this.vertices.put(w)
    }
    public func toString() : String {
        let vertexString = this.vertices.toString()
        let edgeString = this.edges.toString()
        let sourceTargetString = fold_left(
            { acc : String , e : Edge => 
                func EdgeVertexString (
                    name : String,
                    array: Array<Vertex>
                ){
                    foldi_left(
                        { acc : String , v : Vertex, i : Int64 => 
                            let str = "${v}"
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
    public func Clone() : (Hypergraph, HashMap<Vertex,Vertex>, HashMap<Edge,Edge>) {
        let newVertices = HashSet<Vertex>()
        let vertexMap = HashMap<Vertex,Vertex>()
        let newEdges = HashSet<Edge>()
        let edgeMap = HashMap<Edge,Edge>()

        for (vertex in this.vertices) {
            let newVertex = Vertex(vertex.GetWidth())
            newVertices.put(newVertex)
            vertexMap.put(vertex, newVertex)
        }
        for (edge in this.edges) {
            let newSources = map({ v : Vertex => unsafeGet(vertexMap, v)}, edge.GetSources())
            let newTargets = map({ v : Vertex => unsafeGet(vertexMap, v)}, edge.GetTargets())
            let newEdge = Edge(edge.GetLabel(), newSources, newTargets)
            newEdges.put(newEdge)
            edgeMap.put(edge, newEdge)
        }
        (Hypergraph(newVertices, newEdges), vertexMap, edgeMap)
    }
}

public func CombineGraphs(vs : Array<Vertex>) : Hypergraph {
    let owners = ArrayList<Hypergraph>()
    for (v in vs) {
        let owner = v.GetOwner()
        match(owner) {
            case None => throw NotOwnedException("CombineGraphs", v)
            case Some(o) => 
                if (!owners.contains(o)) {
                    owners.add(o)
                }
        }
    }

    let vertices = HashSet<Vertex>()
    let edges = HashSet<Edge>()

    for (owner in owners) {
        let currentVertices = owner.GetVertices()
        let currentEdges = owner.GetEdges()
        for(v in currentVertices) {
            v.RemoveOwner()
        }
        vertices.putAll(currentVertices)
        for(e in currentEdges){
            e.RemoveOwner()
        }
        edges.putAll(currentEdges)
    }
    Hypergraph(vertices, edges)
}

/**
    A hypergraph with an interface. Represents a complete circuit with inputs
    and outputs. Interfaced hypergraphs are *immutable* and their elements are
    cloned on creation so that users cannot inadvertently modify their structure
 */
public class InterfacedHypergraph <: Identifiable & ToString & Nameable & InputOutput & Equatable<InterfacedHypergraph> {

    let uniqueId : Identifier = Identifier()
    let f : Hypergraph
    let inputs : Array<Vertex>
    let outputs : Array<Vertex>

    public init(f : Hypergraph, inputs : Array<Vertex>, outputs: Array<Vertex>){
        let (newF, vertexMap, edgeMap) = f.Clone()
        this.f = newF

        func translateVertices(vs : Array<Vertex>, exn : ((Vertex) -> Exception)) : Array<Vertex> {
            map({v : Vertex => unsafeGet(vertexMap, v, exn)}, vs)
        }

        this.inputs = translateVertices(inputs, { v : Vertex => InputNotInHypergraphException("InterfacedHypergraph", f, v)})
        this.outputs = translateVertices(outputs, { v : Vertex => OutputNotInHypergraphException("InterfacedHypergraph", f, v)})
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
    public func GetInputVertices() : Array<Vertex> {
        this.inputs
    }
    public func GetOutputVertices() : Array<Vertex> {
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
}