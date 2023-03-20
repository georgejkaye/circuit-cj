/**
 * graphs/hypergraph.cj
 *
 * @author George Kaye
 * @since 0.1
 */

package graphs


from std import collection.ArrayList
from std import collection.HashMap
from std import collection.HashSet

public enum WellformednessIssue<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    | InputNotAssigned(Int64)
    | OutputNotAssigned(Int64)
    | InputNotInGraph(Int64, InterfaceVertex<V, G>)
    | OutputNotInGraph(Int64, InterfaceVertex<V, G>)
    | SourceNotAssigned(Edge<V, G>, Int64)
    | TargetNotAssigned(Edge<V, G>, Int64)
    | SourceNotInGraph(Edge<V, G>, Int64, Vertex<V, G>)
    | TargetNotInGraph(Edge<V, G>, Int64, Vertex<V, G>)
}
extend WellformednessIssue<V, G> <: ToString {
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
public enum TentacleOrigin<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    | FROM_EDGE(EdgeConnection<V, G>)
    | FROM_VERTEX(Vertex<V, G>)
}
extend TentacleOrigin<V, G> <: HasWidth & ToString {
    public func GetWidth() : Int64 {
        match(this) {
            case FROM_EDGE(ec) => ec.GetWidth()
            case FROM_VERTEX(v) => v.GetWidth()
        }
    }
    public func toString() : String {
        match(this) {
            case FROM_EDGE(ec) => ec.toString()
            case FROM_VERTEX(v) => v.toString()
        }
    }
}
public struct SequentialData<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public let delayEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    public let valueEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    public let sequentialEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    public let feedbackConnections : HashSet<EdgeConnection<V, G>> = HashSet<EdgeConnection<V, G>>()
    public let combinationalEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    public func IsCombinational() : Bool {
        delayEdges.size == 0 &&
            valueEdges.size == 0 &&
            feedbackConnections.size == 0 &&
            sequentialEdges.size == 0
    }
}
func GetVerticesFromEdges<V, G>(es : HashSet<Edge<V, G>>) : HashSet<Vertex<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let vertices = HashSet<Vertex<V, G>>()
    func PutVertices(ts : Array<Vertex<V, G>>) : Unit {
        for(t in ts) {
            vertices.put(t.GetVertex())
        }
    }
    for(e in es) {
        PutVertices(e.GetSources())
        PutVertices(e.GetTargets())
    }
    vertices
}
/**
 * A hypergraph contains a set of (hyper)edges and vertices.
 * These hypergraphs are not interfaced.
 */
public class Hypergraph<V, G> <: Identifiable<Hypergraph<V, G>> & ToString & Hashable
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let id : Int64 = GetNextId()
    let name : String = "hg${id}"
    let vertices : HashSet<Vertex<V, G>>
    let edges : HashSet<Edge<V, G>>
    // Edges with no sources and vertices with no in edge
    let leftmostTraversalElements : HashSet<TraversalElement<V, G>> = HashSet<TraversalElement<V, G>>()
    // Edges with no targets and vertices with no out edges
    let rightmostTraversalElements : HashSet<TraversalElement<V, G>> = HashSet<TraversalElement<V, G>>()
    // Sequential components in this graph
    let sequentialData : SequentialData<V, G> = SequentialData<V, G>()
    // The interfaced hypergraphs that depend on this hypergraph
    let interfacedOwners : HashSet<InterfacedHypergraph<V, G>> = HashSet<InterfacedHypergraph<V, G>>()
    public init (
        vertices : HashSet<Vertex<V, G>>,
        edges : HashSet<Edge<V, G>>
    ) {
        this.vertices = vertices
        this.edges = edges
        for(e in edges) {
            e.SetOwner(this)
            this.AddEdgeToHypergraphData(e)
        }
        for(v in vertices) {
            v.SetOwner(this)
            this.AddVertexToHypergraphData(v)
        }
    }
    /**
     * Define an empty hypergraph
     */
    public init () {
        this(HashSet<Vertex<V, G>>(), HashSet<Edge<V, G>>())
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetEdges() : HashSet<Edge<V, G>> {
        this.edges
    }
    func AddEdgeToTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        direction : TraversalDirection,
        e : Edge<V, G>
    ) : Unit {
        traversalElements.put(EDGE(e))
        for(owner in this.interfacedOwners) {
            owner.AddEdgeToTraversalElements(direction, e)
        }
    }
    func AddVertexToHypergraphData(v : Vertex<V, G>) : Unit {
        if(v.GetOutEdges().size == 0) {
            rightmostTraversalElements.put(VERTEX(v))
        }
    }
    func AddEdgeToHypergraphData(e : Edge<V, G>) : Unit {
        // We keep track of edges with no sources so that we can
        // start traversing the graph from there later
        if(e.GetArity() == 0) {
            this.AddEdgeToTraversalElements(leftmostTraversalElements, LEFT_TO_RIGHT, e)
        }
        if(e.GetCoarity() == 0) {
            this.AddEdgeToTraversalElements(rightmostTraversalElements, RIGHT_TO_LEFT, e)
        }
        // We keep track of delay and value edges since these represent
        // sequential components
        match(e.GetLabel()){
            case DELAY(_) => this.sequentialData.delayEdges.put(e)
            case VALUE(_) => this.sequentialData.valueEdges.put(e)
            case SIGNAL(_) => this.sequentialData.valueEdges.put(e)
            case _ =>
                match(e.GetSubgraph()){
                    case Some(g) =>
                        if(g.IsCombinational()) {
                            this.sequentialData.combinationalEdges.put(e)
                        } else {
                            this.sequentialData.sequentialEdges.put(e)
                        }
                    case None => this.sequentialData.combinationalEdges.put(e)
                }
        }
    }
    public func GetLeftmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.leftmostTraversalElements
    }
    public func GetRightmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.rightmostTraversalElements
    }
    public func AddNewVertex(width : Int64) : Vertex<V, G> {
        Vertex(width, this)
    }
    public func AddNewEdge(
        label : Label<V, G>,
        sources : Array<Vertex<V, G>>,
        targets : Array<Vertex<V, G>>,
        subgraph : Option<InterfacedHypergraph<V, G>>
    ) : Edge<V, G> {
        Edge(label, sources, targets, subgraph, this)
    }
    func AddVertexToTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        direction : TraversalDirection,
        v : Vertex<V, G>)
    : Unit {
        traversalElements.put(VERTEX(v))
        for(owner in this.interfacedOwners) {
            owner.AddVertexToTraversalElements(direction, v)
        }
    }
    public func AddVertexToLeftmostTraversalElements(v : Vertex<V, G>) : Unit {
        AddVertexToTraversalElements(
            leftmostTraversalElements,
            LEFT_TO_RIGHT,
            v
        )
    }
    public func AddVertexToRightmostTraversalElements(v : Vertex<V, G>) : Unit {
        AddVertexToTraversalElements(
            rightmostTraversalElements,
            RIGHT_TO_LEFT,
            v
        )
    }
    func RemoveVertexFromTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        direction : TraversalDirection,
        v : Vertex<V, G>
    ) : Unit {
        traversalElements.remove(VERTEX(v))
        for(owner in this.interfacedOwners) {
            owner.RemoveVertexFromTraversalElements(direction, v)
        }
    }
    public func RemoveVertexFromLeftmostTraversalElements(v : Vertex<V, G>) : Unit {
        RemoveVertexFromTraversalElements(this.leftmostTraversalElements, LEFT_TO_RIGHT, v)
    }
    public func RemoveVertexFromRightmostTraversalElements(v : Vertex<V, G>) : Unit {
        RemoveVertexFromTraversalElements(this.rightmostTraversalElements, RIGHT_TO_LEFT, v)
    }
    func RemoveEdgeFromTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        direction : TraversalDirection,
        e : Edge<V, G>
    ) : Unit {
        traversalElements.remove(EDGE(e))
        for(owner in this.interfacedOwners) {
            owner.RemoveEdgeFromTraversalElements(direction, e)
        }
    }
    public func RemoveEdgeFromLeftmostTraversalElements(e : Edge<V, G>) : Unit {
        RemoveEdgeFromTraversalElements(leftmostTraversalElements, LEFT_TO_RIGHT, e)
    }
    public func RemoveEdgeFromRightmostTraversalElements(e : Edge<V, G>) : Unit {
        RemoveEdgeFromTraversalElements(rightmostTraversalElements, RIGHT_TO_LEFT, e)
    }
    func RemoveEdgeFromHypergraphData(e : Edge<V, G>) : Unit {
        this.RemoveEdgeFromLeftmostTraversalElements(e)
        this.RemoveEdgeFromRightmostTraversalElements(e)
        this.sequentialData.delayEdges.remove(e)
        this.sequentialData.valueEdges.remove(e)
        this.sequentialData.sequentialEdges.remove(e)
        this.sequentialData.feedbackConnections.removeIf(
            { ec : EdgeConnection<V, G> => ec.GetEdge() == e}
        )
        this.sequentialData.combinationalEdges.remove(e)
    }
    func RemoveVertexFromHypergraphData(v : Vertex<V, G>) : Unit {
        this.RemoveVertexFromLeftmostTraversalElements(v)
        this.RemoveVertexFromRightmostTraversalElements(v)
    }
    public func GetSequentialData() : SequentialData<V, G> {
        this.sequentialData
    }
    public func IsFeedbackTentacle(e : Edge<V, G>, i : Int64) : Bool {
        this.sequentialData.feedbackConnections.contains(
            EdgeConnection(e, i, SOURCE)
        )
    }
    public func AddEdgeAndVertices(e : Edge<V, G>) : Unit {
        this.IncludeHypergraph(e.GetGraph())
    }
    public func AddEdge(e : Edge<V, G>) : Unit {
        this.edges.put(e)
        e.SetOwner(this)
        AddEdgeToHypergraphData(e)
        for(t in e.GetSources()) {
            this.AddVertex(t.GetVertex())
        }
        for(t in e.GetTargets()) {
            this.AddVertex(t.GetVertex())
        }
    }
    public func AddEdges(es : Iterable<Edge<V, G>>) : Unit {
        for (e in es) {
            this.AddEdge(e)
        }
    }
    public func GetVertices() : HashSet<Vertex<V, G>> {
        this.vertices
    }
    public func AddElement(elem : GraphElement<V, G>) : Unit {
        match(elem) {
            case e : Edge<V, G> => this.AddEdge(e)
            case v : Vertex<V, G> => this.AddVertex(v)
            case _ => throw IllegalArgumentException()
        }
    }
    public func AddVertex(v : Vertex<V, G>) : Unit {
        v.SetOwner(this)
        this.vertices.put(v)
        this.AddVertexToHypergraphData(v)
    }
    public func AddVertices(vs : Collection<Vertex<V, G>>) : Unit {
        for(v in vs) {
            this.AddVertex(v)
        }
    }
    public func RemoveVertex(v : Vertex<V, G>) : Unit {
        match(v.GetInEdge()) {
            case None => ()
            case Some(ec) =>
                AssertNotOwnedBy(ec.GetEdge(), this)
        }
        for(ec in v.GetOutEdges()) {
            AssertNotOwnedBy(ec.GetEdge(), this)
        }
        AssertEmpty(v.GetInterfacedInputs(), InEdge)
        AssertEmpty(v.GetInterfacedOutputs(), OutEdges)
        this.vertices.remove(v)
        this.RemoveVertexFromHypergraphData(v)
    }
    /**
     * Remove an edge from the hypergraph.
     * Does not remove its sources and targets, but does remove the edge from
     * their out-edges and in-edges respectively.
     *
     * @param e The edge
     */
    func RemoveEdge(e : Edge<V, G>) {
        this.edges.remove(e)
        for(t in e.GetSources()) {
            t.GetVertex().RemoveOutEdge(e)
        }
        for(t in e.GetTargets()) {
            t.GetVertex().RemoveInEdge(e)
        }
        RemoveEdgeFromHypergraphData(e)
    }
    public func AddInterfacedOwner(f : InterfacedHypergraph<V, G>) : Unit {
        this.interfacedOwners.put(f)
    }
    public func IsCombinational() : Bool {
        this.sequentialData.IsCombinational()
    }
    public func IsWellFormed() : Bool {
        let issues = this.WellFormednessCheck()
        issues.size == 0
    }
    public func WellFormednessCheck() : ArrayList<WellformednessIssue<V, G>> {
        let issues = ArrayList<WellformednessIssue<V, G>>()
        func EdgeVertexCheck(
            e : Edge<V, G>,
            array : Array<Vertex<V, G>>,
            notPresent : (Edge<V, G>, Int64, Vertex<V, G>) -> WellformednessIssue<V, G>
        ){
            for (i in 0..array.size) {
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
    public func IncludeHypergraph(f : Hypergraph<V, G>) : Unit {
        for(e in HashSet(f.GetEdges())) {
            this.AddEdge(e)
        }
        for(v in HashSet(f.GetVertices())) {
            this.AddVertex(v)
        }
    }
    public func toString() : String {
        this.GetName()
    }
    public func toLongString() : String {
        let vertexString = this.vertices.toString()
        let edgeStrings = HashSet<String>()
        for(e in this.edges) {
            edgeStrings.put("(${e.toLongString()})")
        }
        let edgeString = edgeStrings.toString()
        let sourceTargetString = fold_left(
            { acc : String , e : Edge<V, G> =>
                func EdgeVertexString (
                    name : String,
                    array: Array<Vertex<V, G>>
                ){
                    foldi_left(
                        { acc : String , i : Int64, cur : Vertex<V, G> =>
                            let portText = "${cur}"
                            let newAcc = if (acc == "") {
                                ""
                            } else {
                                "${acc}  "
                            }
                            "${newAcc}${name}(${e},${i}) = ${portText}"},
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
    public operator func ==(right: Hypergraph<V, G>) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Hypergraph<V, G>) : Bool {
        this.GetId() != right.GetId()
    }
    /**
     * Create a brand new hypergraph with the same connectivity as the
     * original but with new vertices and edges
     * @return A tuple (hypergraph, vertex map, edge map) where the two hashmaps
     * relate the original versions of vertices/edges with the new copies
     */
    public func Clone() : (Hypergraph<V, G>, HashMap<Vertex<V, G>, Vertex<V, G>>, HashMap<Edge<V, G>, Edge<V, G>>) {
        Debug("Cloning ${this}")
        let newHypergraph = Hypergraph<V, G>()
        let newVertices = HashSet<Vertex<V, G>>()
        let vertexMap = HashMap<Vertex<V, G>,Vertex<V, G>>()
        let newEdges = HashSet<Edge<V, G>>()
        let edgeMap = HashMap<Edge<V, G>, Edge<V, G>>()
        for (vertex in this.vertices) {
            let newVertex = Vertex<V, G>(vertex.GetWidth(), newHypergraph)
            newVertices.put(newVertex)
            vertexMap.put(vertex, newVertex)
        }
        for (edge in this.edges) {
            func CloneTentacles(
                vs : Array<Vertex<V, G>>
            ) : Array<Vertex<V, G>> {
                map({ t => unsafeGet(vertexMap, t.GetVertex()) }, vs)
            }
            let newSources = CloneTentacles(edge.GetSources())
            let newTargets = CloneTentacles(edge.GetTargets())
            let newEdge = edge.Clone(newSources, newTargets, newHypergraph)
            newEdges.put(newEdge)
            edgeMap.put(edge, newEdge)
        }
        for(ec in this.sequentialData.feedbackConnections) {
            let newEdge = unsafeGet(edgeMap, ec.GetEdge())
            newHypergraph.AddFeedbackConnection(newEdge, ec.GetIndex())
        }
        println("The feedback connections are ${newHypergraph.GetSequentialData().feedbackConnections}")
        (newHypergraph, vertexMap, edgeMap)
    }
    public func AddFeedbackConnection(e : Edge<V, G>, i : Int64) : Unit {
        this.sequentialData.feedbackConnections.put(
            EdgeConnection(e, i, SOURCE)
        )
        println("Feedback connections of ${this} are now ${sequentialData.feedbackConnections}")
    }
    public func AddFeedbackConnection(ec : EdgeConnection<V, G>) : Unit {
        this.sequentialData.feedbackConnections.put(ec)
    }
    public func IsFeedbackConnection(ec : EdgeConnection<V, G>) : Bool {
        this.sequentialData.feedbackConnections.contains(ec)
    }
    public func IsFeedbackConnection(e : Edge<V, G>, i : Int64) : Bool {
        this.sequentialData.feedbackConnections.contains(
            EdgeConnection(e, i, SOURCE)
        )
    }
    public func RemoveSubgraphElements(f : InterfacedHypergraph<V, G>) : Unit {
        for(v in f.GetVertices()){
            this.RemoveVertex(v)
        }
        for(e in f.GetEdges()){
            this.RemoveEdge(e)
        }
    }
    public func CollapseSubgraph(
        inputs : Array<TentacleOrigin<V, G>>,
        outputs : Array<TentacleOrigin<V, G>>,
        label : Label<V, G>
    ) : (InterfacedHypergraph<V, G>, Edge<V, G>) {
        func SliceInterfaceVertex(
            to : TentacleOrigin<V, G>,
            vt : VertexType
        ) : (Vertex<V, G>, Vertex<V, G>) {
            match(to) {
                case FROM_EDGE(ec) =>
                    ec.SliceTentacle()
                case FROM_VERTEX(v) =>
                    let newVertex = this.AddNewVertex(v.GetWidth())
                    match(vt) {
                        case SOURCE =>
                            let inputs = HashSet(v.GetInterfacedInputs())
                            for(ie in inputs) {
                                ie.graph.ReplaceInput(ie.index, newVertex)
                            }
                            (newVertex, v)
                        case TARGET =>
                            let outputs = HashSet(v.GetInterfacedOutputs())
                            for(ie in outputs) {
                                ie.graph.ReplaceOutput(ie.index, newVertex)
                            }
                            (v, newVertex)
                    }

            }
        }
        let slicedInputs = map(
            { to : TentacleOrigin<V, G> => SliceInterfaceVertex(to, SOURCE) },
            inputs
        )
        let slicedOutputs = map(
            { to : TentacleOrigin<V, G> => SliceInterfaceVertex(to, TARGET) },
            outputs
        )
        let childInputs = map(
            { vs : (Vertex<V, G>, Vertex<V, G>) => vs[1] }, slicedInputs
        )
        let childOutputs = map(
            { vs : (Vertex<V, G>, Vertex<V, G>) => vs[0] }, slicedOutputs
        )
        let parentInputs = map(
            { vs : (Vertex<V, G>, Vertex<V, G>) => vs[0] }, slicedInputs
        )
        let parentOutputs = map(
            { vs : (Vertex<V, G>, Vertex<V, G>) => vs[1] }, slicedOutputs
        )
                let subgraphVertices = HashSet<Vertex<V, G>>()
        let subgraphEdges = HashSet<Edge<V, G>>()
        let actionAtVertex = { v : Vertex<V, G> =>
            subgraphVertices.put(v)
            ()
        }
        let actionAtEdge = { e : Edge<V, G> =>
            subgraphEdges.put(e)
            ()
        }
        func TraverseGraphFromEnd(starting : Array<Vertex<V, G>>) : Unit {
            let startingSet = HashSet<TraversalElement<V, G>>()
            for(v in starting) {
                startingSet.put(VERTEX(v))
            }
            Traverse(
                startingSet,
                BOTH_DIRECTIONS,
                0,
                actionAtVertex: actionAtVertex,
                actionAtEdge: actionAtEdge
            )
        }
        TraverseGraphFromEnd(childInputs)
        TraverseGraphFromEnd(childOutputs)
        let newSubgraph = Hypergraph<V, G>(subgraphVertices, subgraphEdges)
        let interfacedSubgraph = InterfacedHypergraph(
            newSubgraph,
            map({ v => InterfaceVertex(v) }, childInputs),
            map({ v => InterfaceVertex(v) }, childOutputs),
            label
        )
        let newEdge = this.AddNewEdge(
            label,
            parentInputs,
            parentOutputs,
            Some(interfacedSubgraph)
        )
        (interfacedSubgraph, newEdge)
    }
    public func CollapseSubgraph(
        inputs : Array<TentacleOrigin<V, G>>,
        outputs : Array<TentacleOrigin<V, G>>,
        name : String
    ) : (InterfacedHypergraph<V, G>, Edge<V, G>) {
        this.CollapseSubgraph(
            inputs,
            outputs,
            COMPOSITE(
                Specification(
                    name,
                    map({ to => Port(to.GetWidth()) }, inputs),
                    map({ to => Port(to.GetWidth()) }, outputs)
                )
            )
        )
    }
    public func ContainsElement(elem : TraversalElement<V, G>) : Bool {
        match(elem) {
            case EDGE(e) => this.edges.contains(e)
            case VERTEX(v) => this.vertices.contains(v)
        }
    }
}
public interface GraphElement<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    func GetGraph() : Hypergraph<V, G>
}
public interface CircuitBuilder<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    func InitCircuit() : Hypergraph<V, G>
}

extend Signature<V, G> <: CircuitBuilder<V, G> {
    public func InitCircuit() : Hypergraph<V, G> {
        Hypergraph<V, G>()
    }
}
public func MergeHypergraphs<V, G>(
    primary : Hypergraph<V, G>, b : GraphElement<V, G>
) : Hypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let secondary = b.GetGraph()
    if(primary != secondary) {
        for(e in HashSet<Edge<V, G>>(secondary.GetEdges())) {
            primary.AddEdge(e)
        }
        for(v in HashSet<Vertex<V, G>>(secondary.GetVertices())){
            primary.AddVertex(v)
        }
    }
    primary
}
public func MergeHypergraphs<V, G, T, U>(a : T, b : U) : Hypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: GraphElement<V, G>,
        U <: GraphElement<V, G>
{
    MergeHypergraphs(a.GetGraph(), b)
}
public func MergeHypergraphs<V, G, T>(
    elems : Array<T>,
    initial!: Option<Hypergraph<V, G>> = None
) : Option<Hypergraph<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: GraphElement<V, G>
{
    if(elems.size == 0) {
        initial
    } else if(elems.size == 1) {
        let actualInitial = match(initial) {
            case Some(f) => MergeHypergraphs(f, elems[0])
            case None    => elems[0].GetGraph()
        }
        Some(actualInitial)
    } else {
        let (actualInitial, startIndex) = match(initial) {
            case Some(f) => (f, 0)
            case None    => (elems[0].GetGraph(), 1)
        }
        Some(
            fold_left<T, Hypergraph<V, G>>(
                { acc, cur => MergeHypergraphs<V, G>(acc, cur) },
                actualInitial,
                elems,
                start: startIndex,
            )
        )
    }
}