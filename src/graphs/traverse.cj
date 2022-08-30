/**
 * graph/traverse.cj
 *
 * Graph traversal algorithm
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

/**
 * An edge and the depth it occupies
 */
public struct EdgeAtDepth <: Equatable<EdgeAtDepth> & ToString {
    public EdgeAtDepth(
        public let edge : Edge,
        public let depth : Int64
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
/**
 * Fill an arraylist with the 'starting' edges of this graph. A starting edge
 * is an edge that the inputs of the graph are sources of, or it is an edges with
 * 0 sources.
 *
 * @param f The interfaced hypergraph to get the edges from
 * @param currentDepth The depth of this graph
 * @param nexts The arraylist to fill
 */
func GetStartingEdges(
    f : InterfacedHypergraph,
    currentDepth : Int64,
    nexts : ArrayList<EdgeAtDepth>
) : Unit {
    for(e in f.GetStartingEdges()){
        AddEdge(e, nexts, currentDepth)
    }
}
public func GetUniqueNextEdges(
    ed : EdgeAtDepth,
    nexts : ArrayList<EdgeAtDepth>
) : Unit {
    for(v in ed.edge.GetTargets()){
        for(e in v.GetVertex().GetOutEdges()){
            let edd = EdgeAtDepth(e.edge, ed.depth)
            if(!nexts.contains(edd)){
                nexts.append(edd)
            }
        }
    }
}
public func GetUniqueNextEdges(
    e : Edge,
    nexts : ArrayList<Edge>
) : Unit {
    for(v in e.GetTargets()) {
        for(ec in v.GetVertex().GetOutEdges()) {
            if(!nexts.contains(ec.edge)) {
                nexts.append(ec.edge)
            }
        }
    }
}
/**
 * Add an edge and its depth to some arraylist
 * @param e The edge
 * @param nexts The arraylist to append the edge and depth to
 * @param currentDepth The current depth
 */
func AddEdge(
    e : Edge,
    nexts : ArrayList<EdgeAtDepth>,
    currentDepth : Int64
) : Unit {
    let ed = EdgeAtDepth(e, currentDepth)
    if (!nexts.contains(ed)){
        nexts.append(ed)
    }
}
/**
 * Add an edge connection and its depth to some arraylist
 * @param ec The edge connection
 * @param nexts The arraylist to append the edge and depth to
 * @param currentDepth The current depth
 */
func AddEdgeConnection(
    ec : EdgeConnection,
    nexts : ArrayList<EdgeAtDepth>,
    currentDepth : Int64
) : Unit {
    AddEdge(ec.edge, nexts, currentDepth)
}
/**
 * Traverse every edge of this hypergraph from left to right up to a given depth,
 * performing some action at each edge.
 *
 * @param f The interfaced hypergraph to traverse
 * @param edgeAction A function that, given an edge and its depth, performs some action
 * @param maxDepth The maximum depth, i.e. how many layers of edges to expand
 */
public func TraverseAll(
    f : InterfacedHypergraph,
    edgeAction : (Edge, Int64) -> Unit,
    maxDepth : Int64
) : Unit {
    let actionAtEdge = { ed : EdgeAtDepth, data : TraversalData =>
        let edge = ed.edge
        let depth = ed.depth
        // Perform user specified edge action
        edgeAction(ed.edge, ed.depth)
        // Compute next edges
        let nexts = ArrayList<EdgeAtDepth>()
        // Check if there is a subgraph inside this edge
        match(edge.GetSubgraph()) {
            case None => ()
            case Some(g) =>
                // Explore it if we are not at max depth already
                if (depth < data.maxDepth) {
                    // Get the starting edges at a deeper level
                    GetStartingEdges(g, depth + 1, nexts)
                }
        }
        // Add all the edges connected to targets of this edge
        for (t in edge.GetTargets()){
            let v = t.vertex
            for (ec in v.GetOutEdges()){
                AddEdgeConnection(ec, nexts, depth)
            }
        }
        nexts
    }
    Traverse(
        f,
        maxDepth,
        actionAtEdge
    )
}
/**
 * Data to keep track of while traversing a graph
 */
public struct TraversalData {
    public TraversalData(
        // Edges to explore next
        let frontier : ArrayList<EdgeAtDepth>,
        // Edges that have been visited, and therefore not to visit again
        let visitedEdges : ArrayList<Edge>,
        // Maximum depth to explore
        let maxDepth : Int64,
        // The action to perform at each edge
        let actionAtEdge : (EdgeAtDepth, TraversalData) -> ArrayList<EdgeAtDepth>
    ){}
}
/**
 * Generic actions to perform when visiting an edge
 *
 * @param ed The edge to visit and its depth
 * @param data The traversal data
 */
func VisitEdge(ed : EdgeAtDepth, data : TraversalData) : Unit {
    data.visitedEdges.append(ed.edge)
    let nexts = data.actionAtEdge(ed, data)
    for(edd in nexts) {
        if(!data.frontier.contains(edd)) {
            data.frontier.append(edd)
        }
    }
}
/**
 * Perform a traversal given some parameters.
 *
 * @param data The traversal data
 */
func PerformTraversal(
    data : TraversalData
) : Unit {
    while(data.frontier.size() != 0){
        let currentEdge = data.frontier.remove(0)
        VisitEdge(currentEdge, data)
    }
}
public func Traverse(
    starting : ArrayList<EdgeAtDepth>,
    maxDepth : Int64,
    actionAtEdge : (EdgeAtDepth, TraversalData) -> ArrayList<EdgeAtDepth>
) : Unit {
    PerformTraversal(
        TraversalData(
            starting,
            ArrayList<Edge>(),
            maxDepth,
            actionAtEdge
        )
    )
}
public func Traverse(
    f : InterfacedHypergraph,
    maxDepth : Int64,
    actionAtEdge : (EdgeAtDepth, TraversalData) -> ArrayList<EdgeAtDepth>
) : Unit {
    let startingList = ArrayList<EdgeAtDepth>()
    GetStartingEdges(f, 0, startingList)
    Traverse(
        startingList,
        maxDepth,
        actionAtEdge
    )
}