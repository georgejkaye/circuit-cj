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
public struct SequentialData {
    public let delayEdges : HashSet<Edge> = HashSet<Edge>()
    public let valueEdges : HashSet<Edge> = HashSet<Edge>()
    public let sequentialEdges : HashSet<Edge> = HashSet<Edge>()
    public let feedbackConnections : HashSet<EdgeConnection> = HashSet<EdgeConnection>()
    public let combinationalEdges : HashSet<Edge> = HashSet<Edge>()
    public func IsCombinational() : Bool {
        delayEdges.size() == 0 &&
            valueEdges.size() == 0 &&
            feedbackConnections.size() == 0 &&
            sequentialEdges.size() == 0
    }
}

func AddEdgeToHypergraphData(
    startingEdges : HashSet<Edge>,
    sequentialData : SequentialData,
    e : Edge
) {
    // We keep track of edges with no sources so that we can
    // start traversing the graph from there later
    if(e.GetNoSources() == 0) {
        startingEdges.put(e)
    }
    // We keep track of delay and value edges since these represent
    // sequential components
    match(e.GetLabel()){
        case DELAY(_, _) => sequentialData.delayEdges.put(e)
        case VALUE(_) => sequentialData.valueEdges.put(e)
        case VALUES(_) => sequentialData.valueEdges.put(e)
        case _ =>
            match(e.GetSubgraph()){
                case Some(g) => if(g.IsCombinational()) {
                    sequentialData.combinationalEdges.put(e)
                } else {
                    sequentialData.sequentialEdges.put(e)
                }
                case None => sequentialData.combinationalEdges.put(e)
            }
    }
    // We keep track of any tentacle that has been marked as a feedback loop
    for(i in 0..e.GetNoSources()) {
        let t = e.GetSource(i)
        if(t.feedback) {
            sequentialData.feedbackConnections.put(EdgeConnection(e, i, SOURCE))
        }
    }
}
func RemoveEdgeFromHypergraphData(
    startingEdges : HashSet<Edge>,
    sequentialData : SequentialData,
    e : Edge
) {
    startingEdges.remove(e)
    sequentialData.delayEdges.remove(e)
    sequentialData.valueEdges.remove(e)
    sequentialData.sequentialEdges.remove(e)
    sequentialData.feedbackConnections.removeIf({ ec : EdgeConnection => ec.edge == e})
    sequentialData.combinationalEdges.remove(e)
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
    // We keep track of edges with no sources, as these
    // are where we begin traversing the graph
    let startingEdges : HashSet<Edge> = HashSet<Edge>()
    // We also keep track of 'sequential' components as
    // these have different status when rewriting
    let sequentialData : SequentialData = SequentialData()
    public init (vertices : HashSet<Vertex>, edges : HashSet<Edge>){
        this.vertices = vertices
        this.edges = edges
        this.name = "h${this.id}"
        for (v in this.vertices) {
            v.SetOwner(this)
        }
        for (e in this.edges) {
            e.SetOwner(this)
            AddEdgeToHypergraphData(startingEdges, sequentialData, e)
        }
    }
    public init () {
        this(HashSet<Vertex>(), HashSet<Edge>())
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetEdges() : HashSet<Edge> {
        this.edges
    }
    public func GetStartingEdges() : HashSet<Edge> {
        this.startingEdges
    }
    public func GetSequentialData() : SequentialData {
        this.sequentialData
    }
    public func AddEdgeAndVertices(e : Edge) : Unit {
        this.IncludeHypergraph(e.GetOwner())
        // AddEdge(e)
        // e.ForEachSourceAndTarget({ v : Vertex, i : Int64 => AddVertex(v)})
    }
    public func AddEdge(e : Edge) : Unit {
        this.edges.put(e)
        e.SetOwner(this)
        AddEdgeToHypergraphData(startingEdges, sequentialData, e)
    }
    public func AddEdges(es : Iterable<Edge>) {
        for (e in es) {
            this.AddEdge(e)
        }
    }
    public func GetVertices() : HashSet<Vertex> {
        this.vertices
    }
    public func AddVertex(v : Vertex) : Unit {
        this.vertices.put(v)
        v.SetOwner(this)
    }
    public func RemoveVertex(v : Vertex) : Unit {
        this.vertices.remove(v)
    }
    public func RemoveFeedbackConnection(ec : EdgeConnection) : Unit {
        this.sequentialData.feedbackConnections.remove(ec)
    }
    func RemoveEdge(e : Edge, removeVertices : Bool) {
        this.edges.remove(e)
        RemoveEdgeFromHypergraphData(this.startingEdges, this.sequentialData, e)
        for(t in e.GetSources()){
            let v = t.GetVertex()
            v.RemoveOutEdge(e)
            if(removeVertices){
                this.RemoveVertex(v)
            }
        }
        for(t in e.GetTargets()){
            let v = t.GetVertex()
            v.RemoveInEdge(e)
            if(removeVertices){
                this.RemoveVertex(v)
            }
        }
    }
    public func RemoveEdge(e : Edge) : Unit {
        RemoveEdge(e, true)
    }
    public func RemoveEdgeWithoutVertices(e : Edge) : Unit {
        RemoveEdge(e, false)
    }
    public func IsCombinational() : Bool {
        this.sequentialData.IsCombinational()
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size() == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue> {

        let issues = ArrayList<WellformednessIssue>()

        func EdgeVertexCheck(
            e : Edge,
            array : Array<Tentacle>,
            notPresent : (Edge, Int64, Vertex) -> WellformednessIssue
        ){
            for (i in 0..array.size()) {
                let v = array[i].GetVertex()
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
    public func IncludeHypergraph(f : Hypergraph) : Unit {
        for(e in f.GetEdges()) {
            this.AddEdge(e)
        }
        for(v in f.GetVertices()) {
            this.AddVertex(v)
        }
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
                    array: Array<Tentacle>
                ){
                    foldi_left(
                        { acc : String , t : Tentacle, i : Int64 =>
                            let str = "${t.GetVertex()}"
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
        "h${this.id}\nV = ${vertexString}\nE = ${edgeString}"
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
        Debug("Cloning ${this}")
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
            let newSources = map(
                { t : Tentacle => Tentacle(unsafeGet(vertexMap, t.GetVertex()), t.feedback, t.delay)},
                edge.GetSources()
            )
            let newTargets = map(
                { t : Tentacle => Tentacle(unsafeGet(vertexMap, t.GetVertex()), t.feedback, t.delay)},
                edge.GetTargets()
            )
            let newEdge = Edge(edge.GetLabel(), newSources, newTargets, edge.GetSubgraph())
            newEdges.put(newEdge)
            edgeMap.put(edge, newEdge)
        }
        (Hypergraph(newVertices, newEdges), vertexMap, edgeMap)
    }
}
public func EmptyGraph() : Hypergraph {
    Hypergraph(
        HashSet<Vertex>(),
        HashSet<Edge>()
    )
}
