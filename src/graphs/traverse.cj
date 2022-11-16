/**
 * graph/traverse.cj
 *
 * Graph traversal algorithm
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

public enum TraversalDirection {
    | LEFT_TO_RIGHT
    | RIGHT_TO_LEFT
    | BOTH_DIRECTIONS
}
public enum TraversalElement<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    | EDGE(Edge<V, G>)
    | VERTEX(Vertex<V, G>)
}
extend TraversalElement<V, G> <: Hashable & Equatable<TraversalElement<V, G>> {
    public func hashCode() : Int64 {
        match(this) {
            case EDGE(e) => e.GetId()
            case VERTEX(v) => v.GetId()
        }
    }
    public operator func ==(rhs : TraversalElement<V, G>) : Bool {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs : TraversalElement<V, G>) : Bool {
        !(this == rhs)
    }
}
/**
 * Data to keep track of while traversing a graph
 */
public struct TraversalData<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public TraversalData(
        // Elements that have been visited, and therefore not to visit again
        let visitedElements : HashSet<TraversalElement<V, G>>,
        // Maximum depth to explore
        let maxDepth : Int64,
        // The action to perform at each vertex
        let actionAtVertex : (Vertex<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>,
        // The action to perform at each edge
        let actionAtEdge : (Edge<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>
    ){}
}
func TraverseFromEdge<V, G>(
    e : Edge<V, G>,
    traversalData : TraversalData<V, G>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    Debug("Visiting edge ${e}")
    traversalData.visitedElements.put(EDGE(e))
    let nextElements = traversalData.actionAtEdge(e, traversalData)
    for(elem in nextElements) {
        if(!traversalData.visitedElements.contains(elem)) {
            TraverseFrom(elem, traversalData)
        }
    }
}
func TraverseFromVertex<V, G>(
    v : Vertex<V, G>,
    traversalData : TraversalData<V, G>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    Debug("Visiting vertex ${v}")
    traversalData.visitedElements.put(VERTEX(v))
    let nextElements = traversalData.actionAtVertex(v, traversalData)
    for(elem in nextElements) {
        if(!traversalData.visitedElements.contains(elem)) {
            TraverseFrom(elem, traversalData)
        }
    }
}
func TraverseFrom<V, G>(
    elem : TraversalElement<V, G>,
    traversalData : TraversalData<V, G>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    match(elem) {
        case VERTEX(v) => TraverseFromVertex(v, traversalData)
        case EDGE(e) => TraverseFromEdge(e, traversalData)
    }
}
func GetDefaultNextVertices<V, G>(
    direction : TraversalDirection,
    condition : (Vertex<V, G>) -> Bool
) : (Edge<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    { e : Edge<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        func AddValidNextElements(potential : Array<Tentacle<V, G>>) : Unit {
            for(t in potential) {
                let element = VERTEX(t.vertex)
                if(condition(t.vertex)){
                    nextElements.put(element)
                }
            }
        }
        match(direction) {
            case LEFT_TO_RIGHT =>
                AddValidNextElements(e.GetTargets())
            case RIGHT_TO_LEFT =>
                AddValidNextElements(e.GetSources())
            case BOTH_DIRECTIONS =>
                AddValidNextElements(e.GetSources())
                AddValidNextElements(e.GetTargets())
        }
        nextElements
    }
}
func GetDefaultNextEdges<V, G>(
    direction : TraversalDirection,
    condition : (Edge<V, G>) -> Bool
) : (Vertex<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    { v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        func AddEdgeIfNotVisited(ec : EdgeConnection<V, G>) : Unit {
            let element = EDGE(ec.edge)
            if(condition(ec.edge)){
                nextElements.put(element)
            }
        }
        func AddOutEdgesIfNotVisited(v : Vertex<V, G>) : Unit {
            for(ec in v.GetOutEdges()) {
                AddEdgeIfNotVisited(ec)
            }
        }
        func AddInEdgeIfNotVisited(v : Vertex<V, G>) : Unit {
            match(v.GetInEdge()) {
                case None => ()
                case Some(ec) => AddEdgeIfNotVisited(ec)
            }
        }
        match(direction) {
            case LEFT_TO_RIGHT =>
                AddOutEdgesIfNotVisited(v)
            case RIGHT_TO_LEFT =>
                AddInEdgeIfNotVisited(v)
            case BOTH_DIRECTIONS =>
                AddOutEdgesIfNotVisited(v)
                AddInEdgeIfNotVisited(v)
        }
        nextElements
    }
}
public func BeginTraversal<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>,
    actionAtEdge : (Edge<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let traversalData = TraversalData(
        HashSet<TraversalElement<V, G>>(),
        maxDepth,
        actionAtVertex,
        actionAtEdge
    )
    for(elem in elements) {
        TraverseFrom(elem, traversalData)
    }
}
public func BeginTraversal<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    traversalDirection : TraversalDirection,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>, TraversalData<V, G>) -> Unit,
    nextVertexCondition : (Vertex<V, G>) -> Bool,
    actionAtEdge : (Edge<V, G>, TraversalData<V, G>) -> Unit,
    nextEdgeCondition : (Edge<V, G>) -> Bool
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let defaultNextVertices = GetDefaultNextVertices<V, G>(traversalDirection, nextVertexCondition)
    let defaultNextEdges = GetDefaultNextEdges<V, G>(traversalDirection, nextEdgeCondition)
    let completeActionAtVertex = { v : Vertex<V, G>, data : TraversalData<V, G> =>
        actionAtVertex(v, data)
        defaultNextEdges(v, data)
    }
    let completeActionAtEdge = { e : Edge<V, G>, data : TraversalData<V, G> =>
        actionAtEdge(e, data)
        defaultNextVertices(e, data)
    }
    BeginTraversal(elements, maxDepth, completeActionAtVertex, completeActionAtEdge)
}
func ExtendFunctionArgumentsWithTraversalData<T, U, V, G>(
    f : (T) -> U
) : (T, TraversalData<V, G>) -> U
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    { t : T, data : TraversalData<V, G> => f(t)}
}
public func BeginTraversal<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    traversalDirection : TraversalDirection,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>) -> Unit,
    nextVertexCondition : (Vertex<V, G>) -> Bool,
    actionAtEdge : (Edge<V, G>) -> Unit,
    nextEdgeCondition : (Edge<V, G>) -> Bool
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    BeginTraversal(
        elements,
        traversalDirection,
        maxDepth,
        ExtendFunctionArgumentsWithTraversalData<Vertex<V, G>, Unit, V, G>(actionAtVertex),
        nextVertexCondition,
        ExtendFunctionArgumentsWithTraversalData<Edge<V, G>, Unit, V, G>(actionAtEdge),
        nextEdgeCondition
    )
}
public func TraverseAll<V, G>(
    f : InterfacedHypergraph<V, G>,
    traversalDirection : TraversalDirection,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>, TraversalData<V, G>) -> Unit,
    nextVertexCondition : (Vertex<V, G>) -> Bool,
    actionAtEdge : (Edge<V, G>, TraversalData<V, G>) -> Unit,
    nextEdgeCondition : (Edge<V, G>) -> Bool
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let startingElements = f.GetTraversalElements(traversalDirection)
    BeginTraversal(
        startingElements,
        traversalDirection,
        maxDepth,
        actionAtVertex,
        nextVertexCondition,
        actionAtEdge,
        nextEdgeCondition
    )
}
public func TraverseAll<V, G>(
    f : InterfacedHypergraph<V, G>,
    traversalDirection : TraversalDirection,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>) -> Unit,
    actionAtEdge : (Edge<V, G>) -> Unit
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    TraverseAll(
        f,
        traversalDirection,
        maxDepth,
        ExtendFunctionArgumentsWithTraversalData<Vertex<V, G>, Unit, V, G>(actionAtVertex),
        { v : Vertex<V, G> => true },
        ExtendFunctionArgumentsWithTraversalData<Edge<V, G>, Unit, V, G>(actionAtEdge),
        { e : Edge<V, G> => true }
    )
}