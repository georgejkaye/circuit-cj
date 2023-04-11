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
 * Strategies for traversing a graph
 */
public enum TraversalDirection {
    | LEFT_TO_RIGHT
    | RIGHT_TO_LEFT
    | BOTH_DIRECTIONS
}
/**
 * Types of element to traverse
 */
public enum TraversalElement<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    | EDGE(Edge<V, G>)
    | VERTEX(Vertex<V, G>)
}
extend TraversalElement<V, G>
    <: Hashable & Equatable<TraversalElement<V, G>> &
            ToString & GraphElement<V, G>
{
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
    public func GetGraph() : Hypergraph<V, G> {
        match(this) {
            case EDGE(e) => e.GetGraph()
            case VERTEX(v) => v.GetGraph()
        }
    }
}
/**
 * Data to keep track of while traversing a graph
 */
public struct TraversalData<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public TraversalData(
        public let frontier : HashSet<TraversalElement<V, G>>,
        // Elements that have been visited, and therefore not to visit again
        public let visitedElements : HashSet<TraversalElement<V, G>>,
        // The action to perform at each vertex, returning the elements to add
        // to the frontier  and the elements to remove from the frontier
        let actionAtVertex : (Vertex<V, G>, TraversalData<V, G>)
                                 -> HashSet<TraversalElement<V, G>>,
        // The action to perform at each edge, returning the elements to add to
        // the frontier
        let actionAtEdge : (Edge<V, G>, TraversalData<V, G>)
                                -> HashSet<TraversalElement<V, G>>
    ){}
}
/**
 * Get the default next vertices condition for a given direction and filter
 * condition: i.e. all vertices that satisfy the condition.
 *
 * @param direction
 * @param condition The filtering condition, takes the current edge and
                        potential vertex as arguments
 * @return The next vertices function for traversal
 */
func GetDefaultNextVertices<V, G>(
    direction : TraversalDirection,
    condition : (Edge<V, G>, Vertex<V, G>) -> Bool
) : (Edge<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    { e : Edge<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        func AddValidNextElements(potential : Array<Vertex<V, G>>) : Unit {
            for(v in potential) {
                let element = VERTEX(v)
                if(condition(e, v)){
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
/**
 * Get the default next edges condition for a given direction and filter
 * condition: i.e. all edges that satisfy the condition.
 *
 * @param direction
 * @param condition The filtering condition, takes the current vertex and
                        potential edge as arguments
 * @return The next edges function for traversal
 */
func GetDefaultNextEdges<V, G>(
    direction : TraversalDirection,
    condition : (Vertex<V, G>, Edge<V, G>) -> Bool
) : (Vertex<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    { v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        func AddEdgeIfNotVisited(ec : EdgeConnection<V, G>) : Unit {
            let element = EDGE(ec.GetEdge())
            if(condition(v, ec.GetEdge())){
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
/**
 * Traverse a graph and perform an action at each vertex and edge
 *
 * @param elements The initial frontier
 * @param actionAtVertex a function that takes a vertex and the traversal data
                            and returns the next elements to explore and the
                            removed elements
 * @param actionAtVertex a function that takes an edge and the traversal data
                            and returns the next elements to explore and the
                            removed elements
 * @param revisit Whether to revisit elements if they reoccur in the frontier
 */
public func Traverse<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    actionAtVertex!:
        (Vertex<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>,
    actionAtEdge!:
        (Edge<V, G>, TraversalData<V, G>) -> HashSet<TraversalElement<V, G>>,
    revisit!: Bool = false
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let graph = AssertAllOwnedBySame<V, G, TraversalElement<V, G>>(elements)
    let frontier = HashSet<TraversalElement<V, G>>(elements)
    let traversalData = TraversalData(
        frontier, HashSet<TraversalElement<V, G>>(),
        actionAtVertex, actionAtEdge
    )
    while(traversalData.frontier.size != 0) {
        let currentElement = frontier.iterator().next().getOrThrow()
        frontier.remove(currentElement)
        // Check that this element is actually still in the graph
        // This might not be the case if an action removes elements
        if(currentElement.GetGraph() == graph){
            Debug("Visiting ${currentElement}")
            traversalData.visitedElements.put(currentElement)
            let elementsToAdd = match(currentElement) {
                case EDGE(e) => actionAtEdge(e, traversalData)
                case VERTEX(v) => actionAtVertex(v, traversalData)
            }
            Debug("The next elements are ${elementsToAdd}")
            for(elem in elementsToAdd) {
                if((revisit || !traversalData.visitedElements.contains(elem))) {
                    traversalData.frontier.put(elem)
                }
            }
            Debug("The frontier is ${frontier.size} long and is now ${frontier}")
        }
    }
}
/**
 * Traverse a graph, performing an action at each vertex and edge, and
 * determining the next elements at each element by a condition.
 *
 * @param elements The initial frontier
 * @param traversalDirection
 * @param actionAtVertex
 * @param actionAtEdge
 * @param nextEdgeCondition
 * @param nextVertexCondition
 */
public func Traverse<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    traversalDirection : TraversalDirection,
    actionAtVertex! :
        (Vertex<V, G>, TraversalData<V, G>) -> Unit = { v, td => () },
    actionAtEdge! :
        (Edge<V, G>, TraversalData<V, G>) -> Unit = { e, td => () },
    nextEdgeCondition! :
        (Vertex<V, G>, Edge<V, G>) -> Bool = { v, e => true },
    nextVertexCondition! :
        (Edge<V, G>, Vertex<V, G>) -> Bool = { e, v => true }
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let defaultNextVertices =
        GetDefaultNextVertices<V, G>(traversalDirection, nextVertexCondition)
    let defaultNextEdges =
        GetDefaultNextEdges<V, G>(traversalDirection, nextEdgeCondition)
    let completeActionAtVertex =
        { v : Vertex<V, G>, data : TraversalData<V, G> =>
            actionAtVertex(v, data)
            defaultNextEdges(v, data)
        }
    let completeActionAtEdge =
        { e : Edge<V, G>, data : TraversalData<V, G> =>
            actionAtEdge(e, data)
            defaultNextVertices(e, data)
        }
    Traverse(
        elements, actionAtVertex: completeActionAtVertex,
        actionAtEdge: completeActionAtEdge
    )
}
/**
 * Given a function, create a function that additionally takes a traversal data
 * struct as an argument but does nothing with it.
 *
 * @param f The function to extend
 * @return The function extended with traversal data
 */
func ExtendFunctionArgumentsWithTraversalData<T, U, V, G>(
    f : (T) -> U
) : (T, TraversalData<V, G>) -> U
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    { t : T, data : TraversalData<V, G> => f(t)}
}
/**
 * Traverse a graph, performing an action at each vertex and edge, and
 * determining the next elements at each element by a condition.
 *
 * @param elements The initial frontier
 * @param traversalDirection
 * @param actionAtVertex
 * @param actionAtEdge
 * @param nextEdgeCondition
 * @param nextVertexCondition
 */
public func Traverse<V, G>(
    elements : HashSet<TraversalElement<V, G>>,
    traversalDirection : TraversalDirection,
    actionAtVertex! : (Vertex<V, G>) -> Unit = { v => () },
    actionAtEdge! : (Edge<V, G>) -> Unit = { e => () },
    nextVertexCondition! : (Edge<V, G>, Vertex<V, G>) -> Bool = { e, v => true },
    nextEdgeCondition! : (Vertex<V, G>, Edge<V, G>) -> Bool = { v, e => true }
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G> {
    Traverse(
        elements,
        traversalDirection,
        actionAtVertex:
            ExtendFunctionArgumentsWithTraversalData(actionAtVertex),
        actionAtEdge: ExtendFunctionArgumentsWithTraversalData(actionAtEdge),
        nextVertexCondition: nextVertexCondition,
        nextEdgeCondition: nextEdgeCondition
    )
}
/**
 * Traverse a graph, performing an action at each vertex and edge, and
 * determining the next elements at each element by a condition.
 *
 * @param element The initial element
 * @param traversalDirection
 * @param actionAtVertex
 * @param actionAtEdge
 * @param nextEdgeCondition
 * @param nextVertexCondition
 */
public func Traverse<V, G>(
    element : TraversalElement<V, G>,
    traversalDirection : TraversalDirection,
    actionAtVertex! : (Vertex<V, G>) -> Unit = { v => () },
    actionAtEdge! : (Edge<V, G>) -> Unit = { e => () },
    nextVertexCondition!: (Edge<V, G>, Vertex<V, G>) -> Bool = { e, v => true },
    nextEdgeCondition!: (Vertex<V, G>, Edge<V, G>) -> Bool = { v, e => true }
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    Traverse<V, G>(
        HashSet([element]), traversalDirection, actionAtVertex: actionAtVertex,
        actionAtEdge: actionAtEdge, nextVertexCondition: nextVertexCondition,
        nextEdgeCondition: nextEdgeCondition
    )
}
/**
 * Traverse an entire hypergraph given a traversal direction, performing an
 * action at each vertex and edge, and computing the next element based on some
 * condition.
 *
 * @param f the hypergraph to traverse
 * @param traversalDirection
 * @param actionAtVertex
 * @param nextEdgeCondition
 * @param actionAtEdge
 * @param nextVertexCondition
 */
public func TraverseAll<V, G>(
    f : InterfacedHypergraph<V, G>,
    traversalDirection : TraversalDirection,
    actionAtVertex : (Vertex<V, G>, TraversalData<V, G>) -> Unit,
    nextEdgeCondition : (Vertex<V, G>, Edge<V, G>) -> Bool,
    actionAtEdge : (Edge<V, G>, TraversalData<V, G>) -> Unit,
    nextVertexCondition : (Edge<V, G>, Vertex<V, G>) -> Bool
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G> {
    let startingElements = f.GetTraversalElements(traversalDirection)
    Traverse<V, G>(
        startingElements, traversalDirection, actionAtVertex: actionAtVertex,
        actionAtEdge: actionAtEdge, nextVertexCondition: nextVertexCondition,
        nextEdgeCondition: nextEdgeCondition
    )
}
/**
 * Traverse an entire hypergraph given a traversal direction, performing an
 * action at each vertex and edge and visiting all accessible elements.
 *
 * @param f the hypergraph to traverse
 * @param traversalDirection
 * @param actionAtVertex
 * @param actionAtEdge
 */
public func TraverseAll<V, G>(
    f : InterfacedHypergraph<V, G>,
    traversalDirection : TraversalDirection,
    maxDepth : Int64,
    actionAtVertex : (Vertex<V, G>) -> Unit,
    actionAtEdge : (Edge<V, G>) -> Unit
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    TraverseAll<V, G>(
        f, traversalDirection,
        ExtendFunctionArgumentsWithTraversalData(actionAtVertex),
        { v : Vertex<V, G>, e : Edge<V, G> => true },
        ExtendFunctionArgumentsWithTraversalData(actionAtEdge),
        { e : Edge<V, G>, v : Vertex<V, G> => true }
    )
}