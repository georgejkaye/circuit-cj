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

public func GetTraversalEdges(
    f : InterfacedHypergraph,
    currentDepth : Int64,
    nexts : ArrayList<EdgeAtDepth>
) : Unit {
    for(v in f.GetTraversalVertices()){
        match(v.GetInEdge()){
            case None =>
                for(ec in v.GetOutEdges()) {
                    AddEdgeConnection(ec, nexts, currentDepth)
                }
            case Some(ec) => AddEdgeConnection(ec, nexts, currentDepth)
        }
    }
}

func AddEdgeConnection(ec : EdgeConnection, nexts : ArrayList<EdgeAtDepth>, currentDepth : Int64) {
    let ed = EdgeAtDepth(ec.edge, currentDepth)
    if (!nexts.contains(ed)){
        nexts.append(ed)
    }
}

public func Traverse(f : InterfacedHypergraph, maxDepth : Int64) {
    let frontier = ArrayList<EdgeAtDepth>()
    GetTraversalEdges(f, 0, frontier)
    let visitedVertices = ArrayList<Vertex>()
    let visitedEdges = ArrayList<Edge>()
    let vertexMap = HashMap<Vertex, Vertex>()
    let actionAtEdge = { ed : EdgeAtDepth, data : TraversalData =>
        let edge = ed.edge
        let depth = ed.depth
        let nexts = ArrayList<EdgeAtDepth>()
        match(edge.GetSubgraph()) {
            case None => ()
            case Some(g) =>
                if (depth < data.maxDepth) {
                    EnterSubgraph(edge, g, data)
                    GetTraversalEdges(g, depth + 1, nexts)
                }
        }
        for (v in edge.GetTargets()){
            for (ec in v.GetOutEdges()){
                AddEdgeConnection(ec, nexts, depth)
            }
        }
        nexts
    }
    let data = TraversalData(
        frontier,
        visitedVertices,
        visitedEdges,
        vertexMap,
        maxDepth,
        actionAtEdge
    )
    PerformTraversal(data)
}

public struct TraversalData{
    public TraversalData(
        let frontier : ArrayList<EdgeAtDepth>,
        let visitedVertices : ArrayList<Vertex>,
        let visitedEdges : ArrayList<Edge>,
        let vertexMap : HashMap<Vertex, Vertex>,
        let maxDepth : Int64,
        let actionAtEdge : (EdgeAtDepth, TraversalData) -> ArrayList<EdgeAtDepth>
    ){}
}

func VisitEdge(ed : EdgeAtDepth, data : TraversalData) {
    println("${data.visitedEdges.size}: ${ed}")
    data.visitedEdges.append(ed.edge)
    let nexts = data.actionAtEdge(ed, data)
    for(edd in nexts) {
        if(!data.frontier.contains(edd) && !data.visitedEdges.contains(edd.edge)) {
            data.frontier.append(edd)
        }
    }
}

func PerformTraversal(
    data : TraversalData
){
    while(data.frontier.size != 0){
        let currentEdge = data.frontier.remove(0)
        VisitEdge(currentEdge, data)
    }
}

