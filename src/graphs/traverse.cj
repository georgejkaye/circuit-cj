/**
 * graph/traverse.cj
 *
 * Graph traversal algorithm
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs


public struct EdgeAtDepth <: Equatable<EdgeAtDepth> & ToString {
    public EdgeAtDepth(
        let edge : Edge,
        let depth : Int64
    ){}
    public operator func ==(rhs : EdgeAtDepth) : Bool {
        this.edge == rhs.edge
    }
    public operator func !=(rhs : EdgeAtDepth) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "${edge} (${depth})"
    }
}

public func EnterSubgraph(parent : Edge, child : InterfacedHypergraph, data : TraversalData) {
    for(i in 0..parent.GetNoTargets()) {
        let source = parent.GetTarget(i)
        let output = child.GetOutput(i).GetVertex()
        data.vertexMap.put(output, source)
    }
}

public func GetTraversalVertices(f : InterfacedHypergraph, currentDepth : Int64, data : TraversalData) : Unit {
    for(v in f.GetTraversalVertices()){
        match(v.GetInEdge()){
            case None     =>
                for(ec in v.GetOutEdges()) {
                    data.frontier.append(EdgeAtDepth(ec.edge, currentDepth))
                }
            case Some(ec) => data.frontier.append(EdgeAtDepth(ec.edge, currentDepth))
        }
    }
}

public func Traverse(f : InterfacedHypergraph, maxDepth : Int64) {
    let frontier = ArrayList<EdgeAtDepth>()
    let visitedVertices = ArrayList<Vertex>()
    let visitedEdges = ArrayList<Edge>()
    let vertexMap = HashMap<Vertex, Vertex>()
    let actionAtEdge = { e : Edge, i : Int64, data : TraversalData =>
        match(e.GetSubgraph()){
            case None => ()
            case Some(g) =>
                if (i < maxDepth) {
                    EnterSubgraph(e, g, data)
                }

                e.GetTargets()
        }
        ArrayList<Vertex>()
    }
    let actionAtVertex = { v : Vertex, i : Int64, data : TraversalData =>
        map({ ec : EdgeConnection => EdgeAtDepth(ec.edge, 0) }, v.GetOutEdges())
    }
    let data = TraversalData(
        frontier,
        visitedVertices,
        visitedEdges,
        vertexMap,
        maxDepth,
        actionAtEdge,
        actionAtVertex
    )
    GetTraversalVertices(f, 0, data)
    PerformTraversal(data)
}

public struct TraversalData{
    public TraversalData(
        let frontier : ArrayList<EdgeAtDepth>,
        let visitedVertices : ArrayList<Vertex>,
        let visitedEdges : ArrayList<Edge>,
        let vertexMap : HashMap<Vertex, Vertex>,
        let maxDepth : Int64,
        let actionAtEdge : (Edge, Int64, TraversalData) -> ArrayList<Vertex>,
        let actionAtVertex : (Vertex, Int64, TraversalData) -> ArrayList<EdgeAtDepth>
    ){}
}

func UpdateFrontier(
    vs : Iterable<Vertex>,
    depth : Int64,
    data : TraversalData
) {
    // for(v in vs) {
    //     if(!data.frontier.contains(VertexAtDepth(v, depth)) && !data.visitedVertices.contains(v)) {
    //         data.frontier.append(VertexAtDepth(v, depth))
    //     }
    // }
}

func VisitEdge(e : Edge, depth : Int64, data : TraversalData) {
    println("${e}")
    data.visitedEdges.append(e)
    for(v in data.actionAtEdge(e, depth, data)) {
        VisitVertex(v, depth, data)
    }
}

func VisitVertex(v : Vertex, depth : Int64, data : TraversalData) {
    println("${v}")
    data.visitedVertices.append(v)
    data.frontier.appendAll(data.actionAtVertex(v, depth, data))
}

func PerformTraversal(
    data : TraversalData
){
    while(data.frontier.size != 0){
        let currentEdge = data.frontier.remove(0)
        VisitEdge(currentEdge.edge, currentEdge.depth, data)
    }
}

