/**
 * graph/traverse.cj
 *
 * Graph traversal algorithm
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs


public struct VertexAtDepth <: Equatable<VertexAtDepth> & ToString {
    public VertexAtDepth(
        let vertex : Vertex,
        let depth : Int64
    ){}
    public operator func ==(rhs : VertexAtDepth) : Bool {
        this.vertex == rhs.vertex
    }
    public operator func !=(rhs : VertexAtDepth) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "${vertex} (${depth})"
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
            case None     => data.frontier.append(VertexAtDepth(v, currentDepth))
            case Some(ec) =>
                if(currentDepth < data.maxDepth) {
                    let edge = ec.edge
                    match(edge.GetSubgraph()){
                        case None => data.frontier.append(VertexAtDepth(v, currentDepth))
                        case Some(g) => 
                            EnterSubgraph(edge, g, data)
                            GetTraversalVertices(g, currentDepth + 1, data)
                    }
                } else {
                    data.frontier.append(VertexAtDepth(v, currentDepth))
                }
        }
    }
}

public func Traverse(f : InterfacedHypergraph, maxDepth : Int64) {
    let frontier = ArrayList<VertexAtDepth>()
    let visitedVertices = ArrayList<Vertex>()
    let visitedEdges = ArrayList<Edge>()
    let vertexMap = HashMap<Vertex, Vertex>()
    let data = TraversalData(
        frontier,
        visitedVertices,
        visitedEdges,
        vertexMap,
        maxDepth
    )
    GetTraversalVertices(f, 0, data)
    PerformTraversal(
        TraversalData(
            frontier,
            visitedVertices,
            visitedEdges,
            HashMap<Vertex, Vertex>(),
            maxDepth
        )
    )
}

public struct TraversalData{
    public TraversalData(
        let frontier : ArrayList<VertexAtDepth>,
        let visitedVertices : ArrayList<Vertex>,
        let visitedEdges : ArrayList<Edge>,
        let vertexMap : HashMap<Vertex, Vertex>,
        let maxDepth : Int64
    ){}
}



func UpdateFrontier(
    vs : Iterable<Vertex>,
    depth : Int64,
    data : TraversalData
) {
    for(v in vs) {
        if(!data.frontier.contains(VertexAtDepth(v, depth)) && !data.visitedVertices.contains(v)) {
            data.frontier.append(VertexAtDepth(v, depth))
        }
    }
}

func VisitEdge(e : Edge, depth : Int64, data : TraversalData) {
    println("${e}")
    data.visitedEdges.append(e)
    UpdateFrontier(e.GetTargets(), depth, data)
}

func VisitVertex(v : Vertex, depth : Int64, data : TraversalData) {
    data.visitedVertices.append(v)
    let edges = v.GetOutEdges()
    for (ec in edges) {
        let e = ec.edge
        if(!data.visitedEdges.contains(e)) {
            if(depth == data.maxDepth) {
                VisitEdge(e, depth, data)
            } else {
                match(e.GetSubgraph()) {
                    case None => VisitEdge(e, depth, data)
                    case Some(f) =>
                        let outputs = f.GetOutputVertices()
                        EnterSubgraph(e, f, data)
                        UpdateFrontier(f.GetTraversalVertices(), depth + 1, data)
                }
            }
        }
    }
    match(data.vertexMap.get(v)){
        case Some(vv) => data.frontier.append(VertexAtDepth(vv, depth - 1))
        case None    => ()
    }
}

func PerformTraversal(
    data : TraversalData
){
    while(data.frontier.size != 0){
        let vd = data.frontier.remove(0)
        VisitVertex(vd.vertex, vd.depth, data)
    }
}

