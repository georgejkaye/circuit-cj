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
public struct EdgeAtDepth<V, G> <: Equatable<EdgeAtDepth<V, G>> & ToString
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public EdgeAtDepth(
        public let edge : Edge<V, G>,
        public let depth : Int64
    ){}
    public operator func ==(rhs : EdgeAtDepth<V, G>) : Bool {
        this.edge == rhs.edge
    }
    public operator func !=(rhs : EdgeAtDepth<V, G>) : Bool {
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
func GetStartingEdges<V, G>(
    f : InterfacedHypergraph<V, G>,
    currentDepth : Int64,
    nexts : ArrayList<EdgeAtDepth<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    for(e in f.GetStartingEdges()){
        AddEdge(e, nexts, currentDepth)
    }
}
public func GetUniqueNextEdges<V, G>(
    ed : EdgeAtDepth<V, G>,
    nexts : ArrayList<EdgeAtDepth<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    for(v in ed.edge.GetTargets()){
        for(e in v.GetVertex().GetOutEdges()){
            let edd = EdgeAtDepth(e.edge, ed.depth)
            if(!nexts.contains(edd)){
                nexts.append(edd)
            }
        }
    }
}
public func GetUniqueNextEdges<V, G>(
    e : Edge<V, G>,
    nexts : ArrayList<Edge<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
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
func AddEdge<V, G>(
    e : Edge<V, G>,
    nexts : ArrayList<EdgeAtDepth<V, G>>,
    currentDepth : Int64
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
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
func AddEdgeConnection<V, G>(
    ec : EdgeConnection<V, G>,
    nexts : ArrayList<EdgeAtDepth<V, G>>,
    currentDepth : Int64
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
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
public func TraverseAll<V, G>(
    f : InterfacedHypergraph<V, G>,
    edgeAction : (Edge<V, G>, Int64) -> Unit,
    maxDepth : Int64
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let actionAtEdge = { ed : EdgeAtDepth<V, G>, data : TraversalData<V, G> =>
        let edge = ed.edge
        let depth = ed.depth
        // Perform user specified edge action
        edgeAction(ed.edge, ed.depth)
        // Compute next edges
        let nexts = ArrayList<EdgeAtDepth<V, G>>()
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
public struct TraversalData<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public TraversalData(
        // Edges to explore next
        let frontier : ArrayList<EdgeAtDepth<V, G>>,
        // Edges that have been visited, and therefore not to visit again
        let visitedEdges : ArrayList<Edge<V, G>>,
        // Maximum depth to explore
        let maxDepth : Int64,
        // The action to perform at each edge
        let actionAtEdge : (EdgeAtDepth<V, G>, TraversalData<V, G>) -> ArrayList<EdgeAtDepth<V, G>>
    ){}
}
/**
 * Generic actions to perform when visiting an edge
 *
 * @param ed The edge to visit and its depth
 * @param data The traversal data
 */
func VisitEdge<V, G>(ed : EdgeAtDepth<V, G>, data : TraversalData<V, G>) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
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
func PerformTraversal<V, G>(
    data : TraversalData<V, G>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    while(data.frontier.size != 0){
        let currentEdge = data.frontier.remove(0)
        VisitEdge(currentEdge, data)
    }
}
public func Traverse<V, G>(
    starting : ArrayList<EdgeAtDepth<V, G>>,
    maxDepth : Int64,
    actionAtEdge : (EdgeAtDepth<V, G>, TraversalData<V, G>) -> ArrayList<EdgeAtDepth<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    PerformTraversal(
        TraversalData(
            starting,
            ArrayList<Edge<V, G>>(),
            maxDepth,
            actionAtEdge
        )
    )
}
public func Traverse<V, G>(
    f : InterfacedHypergraph<V, G>,
    maxDepth : Int64,
    actionAtEdge : (EdgeAtDepth<V, G>, TraversalData<V, G>) -> ArrayList<EdgeAtDepth<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let startingList = ArrayList<EdgeAtDepth<V, G>>()
    GetStartingEdges(f, 0, startingList)
    Traverse(
        startingList,
        maxDepth,
        actionAtEdge
    )
}