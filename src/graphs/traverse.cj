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
extend TraversalElement<V, G> <: Hashable & Equatable<TraversalElement<V, G>> & ToString {
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
    public func toString() : String {
        match(this) {
            case EDGE(e) => "Edge ${e}"
            case VERTEX(v) => "Vertex ${v}"
        }
    }
}
/**
 * Data to keep track of while traversing a graph
 */
public struct TraversalData<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public TraversalData(
        public let frontier : ArrayList<TraversalElement<V, G>>,
        // Elements that have been visited, and therefore not to visit again
        public let visitedElements : HashSet<TraversalElement<V, G>>,
        // Maximum depth to explore
        let maxDepth : Int64,
        // The action to perform at each vertex, returning the elements to add to the frontier
        // and the elements to remove from the frontier
        let actionAtVertex : (Vertex<V, G>, TraversalData<V, G>)
                                -> (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>),
        // The action to perform at each edge, returning the elements to add to the frontier
        // and the elements to remove from the frontier
        let actionAtEdge : (Edge<V, G>, TraversalData<V, G>)
                                -> (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    ){}
}
func GetDefaultNextVertices<V, G>(
    direction : TraversalDirection,
    condition : (Vertex<V, G>) -> Bool
) : (Edge<V, G>, TraversalData<V, G>) -> (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
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
        (nextElements, HashSet<TraversalElement<V, G>>())
    }
}
func GetDefaultNextEdges<V, G>(
    direction : TraversalDirection,
    condition : (Edge<V, G>) -> Bool
) : (Vertex<V, G>, TraversalData<V, G>) -> (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    { v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        func AddEdgeIfNotVisited(ec : EdgeConnection<V, G>) : Unit {
            let element = EDGE(ec.GetEdge())
            if(condition(ec.GetEdge())){
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
        (nextElements, HashSet<TraversalElement<V, G>>())
    }
}
public func Traverse<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>, TraversalData<V, G>)
                            -> (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>),
    actionAtEdge : (Edge<V, G>, TraversalData<V, G>)
                            -> (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>),
    revisit!: Bool = false
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    let frontier = ArrayList<TraversalElement<V, G>>()
    frontier.appendAll(elements)
    let traversalData = TraversalData(
        frontier,
        HashSet<TraversalElement<V, G>>(),
        maxDepth,
        actionAtVertex,
        actionAtEdge
    )
    while(traversalData.frontier.size != 0) {
        let currentElement = frontier.remove(0)
        Debug("Visiting ${currentElement}")
        traversalData.visitedElements.put(currentElement)
        let (elementsToAdd, elementsToRemove) = match(currentElement) {
            case EDGE(e) => actionAtEdge(e, traversalData)
            case VERTEX(v) => actionAtVertex(v, traversalData)
        }
        for(elem in elementsToAdd) {
            if(!elementsToRemove.contains(elem) && (revisit || !traversalData.visitedElements.contains(elem))) {
                traversalData.frontier.append(elem)
            }
        }
        traversalData.frontier.removeIf({ elem => elementsToRemove.contains(elem) })
    }
}
public func Traverse<V, G>(
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
    Traverse(elements, maxDepth, completeActionAtVertex, completeActionAtEdge)
}
func ExtendFunctionArgumentsWithTraversalData<T, U, V, G>(
    f : (T) -> U
) : (T, TraversalData<V, G>) -> U
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    { t : T, data : TraversalData<V, G> => f(t)}
}
public func Traverse<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    traversalDirection : TraversalDirection,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>) -> Unit,
    nextVertexCondition : (Vertex<V, G>) -> Bool,
    actionAtEdge : (Edge<V, G>) -> Unit,
    nextEdgeCondition : (Edge<V, G>) -> Bool
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    Traverse(
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
    Traverse(
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