/**
 * graphs/hypergraph.cj
 * 
 * @author George Kaye
 * @since 0.1
 */

package graphs

import prelude.*

from std import collection.ArrayList
from std import collection.HashMap
from std import collection.HashSet

public enum WellformednessIssue {
    | InputNotAssigned(Int64)
    | OutputNotAssigned(Int64)
    | InputNotInGraph(Int64, InterfaceVertex)
    | OutputNotInGraph(Int64, InterfaceVertex)
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

/**
 * A hypergraph contains a set of (hyper)edges and vertices.
 * These hypergraphs are not interfaced.
 */
public class Hypergraph <: Identifiable & ToString & Equatable<Hypergraph> & Hashable {
    
    let id : Int64 = GetNextId()
    let name : String
    let vertices : HashSet<Vertex>
    let edges : HashSet<Edge>

    public init (vertices : HashSet<Vertex>, edges : HashSet<Edge>){
        this.vertices = vertices
        this.edges = edges
        this.name = "h${this.id}"

        for (v in this.vertices) {
            v.SetOwner(this)
        }
        for (e in this.edges) {
            e.SetOwner(this)
        }
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetEdges() : HashSet<Edge> {
        this.edges
    }
    public func AddEdge(e : Edge) : Unit {
        this.edges.put(e)
        e.ForEachSourceAndTarget({ v : Vertex, i : Int64 => this.vertices.put(v)})
        e.SetOwner(this)
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
        issues.size == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {

        let issues = ArrayList<WellformednessIssue>()

        func EdgeVertexCheck(
            e : Edge,
            array : Array<Vertex>,
            notPresent : (Edge, Int64, Vertex) -> WellformednessIssue
        ){
            for (i in 0..array.size) {
                let v = array[i]
                if (!this.vertices.contains(v)) {
                    issues.append(notPresent(e, i, v))
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
        this.GetName()
    }
    public func toLongString() : String {
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
        this.id
    }
    public func GetName() : String {
        "hg${this.id}"
    }
    public operator func ==(right: Hypergraph) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Hypergraph) : Bool {
        this.GetId() != right.GetId()
    }
    /**
     * Create a brand new hypergraph with the same connectivity as the
     * original but with new vertices and edges
     * @return A tuple (hypergraph, vertex map, edge map) where the two hashmaps
     * relate the original versions of vertices/edges with the new copies
     */
    public func Clone() : (Hypergraph, HashMap<Vertex, Vertex>, HashMap<Edge, Edge>) {
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
            let newEdge = Edge(edge.GetLabel(), newSources, newTargets, edge.GetSubgraph())
            newEdges.put(newEdge)
            edgeMap.put(edge, newEdge)
        }
        (Hypergraph(newVertices, newEdges), vertexMap, edgeMap)
    }
}

/** 
 * Given an array of vertices, produce a new hypergraph that contains all the
 * elements of their owners.
 *
 * @param vs The array of vertices
 * @return The new hypergraph containing the elements of the owners
 */
public func CombineGraphs<T>(vs : Array<T>) : Hypergraph where T <: ContainsVertex {
    // Find all the owners
    let owners = HashSet<Hypergraph>()
    for (v in vs) {
        let owner = AssertOwned(v.GetVertex())
        owners.put(owner)
    }
    // Collect together the vertices and edges in the owners
    let vertices = HashSet<Vertex>()
    let edges = HashSet<Edge>()
    for (owner in owners) {
        let currentVertices = owner.GetVertices()
        let currentEdges = owner.GetEdges()
        // Remove the old owner of the vertices
        for(v in currentVertices) {
            v.RemoveOwner()
        }
        vertices.putAll(currentVertices)
        // Remove the old owner of the edges
        for(e in currentEdges){
            e.RemoveOwner()
        }
        edges.putAll(currentEdges)
    }
    Hypergraph(vertices, edges)
}