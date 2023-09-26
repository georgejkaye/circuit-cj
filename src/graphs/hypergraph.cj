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
/**
 * Types of ways a hypergraph can be malformed
 */
public enum WellformednessIssue<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
            case InputNotAssigned(i) =>
                "Input ${i} is unassigned"
            case OutputNotAssigned(i) =>
                "Output ${i} is unassigned"
            case InputNotInGraph(i, v) =>
                "Input ${i} (${v}) not in this graph"
            case OutputNotInGraph(i, v) =>
                "Output ${i} (${v}) not in this graph"
            case SourceNotAssigned(e, i) =>
                "Source ${i} of edge ${e} is unassigned"
            case TargetNotAssigned(e, i) =>
                "Target ${i} of edge ${e} is unassigned"
            case SourceNotInGraph(e, i, v) =>
                "Source ${i} of edge ${e} (${v}) is not in this graph"
            case TargetNotInGraph(e, i, v) =>
                "Target ${i} of edge ${e} (${v}) is not in this graph"
        }
    }
}
/**
 * Locations that a 'tentacle' (a connection between an edge/interface and a
 * vertex) can originate from.
 */
public enum TentacleOrigin<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
/**
 * A hypergraph contains a set of (hyper)edges and vertices.
 * These hypergraphs are not interfaced.
 */
public class Hypergraph<V, G> <: Identifiable<Hypergraph<V, G>> & ToString
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let id : Int64 = GetNextId()
    let name : String = "hg${id}"
    let vertices : HashSet<Vertex<V, G>>
    let edges : HashSet<Edge<V, G>>
    // Edges with no sources and vertices with no in edge
    let leftmostTraversalElements : HashSet<TraversalElement<V, G>> =
        HashSet<TraversalElement<V, G>>()
    // Edges with no targets and vertices with no out edges
    let rightmostTraversalElements : HashSet<TraversalElement<V, G>> =
        HashSet<TraversalElement<V, G>>()
    // Edges representing delays
    let delayEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    // Edges representing signals or values
    let valueEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    // Edges represented disconnected values (these are combinational)
    let disconnectedEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    // Edges with sequential subgraphs
    let sequentialEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    // Edges with combinational subgraphs
    let combinationalEdges : HashSet<Edge<V, G>> = HashSet<Edge<V, G>>()
    // Connections designated as instant feedback
    let feedbackConnections : HashSet<EdgeConnection<V, G>>
    // The interfaced hypergraphs that depend on this hypergraph
    let interfacedOwners : HashSet<InterfacedHypergraph<V, G>> =
        HashSet<InterfacedHypergraph<V, G>>()
    public init (
        vertices : HashSet<Vertex<V, G>>,
        edges : HashSet<Edge<V, G>>,
        feedbacks!: Option<HashSet<EdgeConnection<V, G>>> = None
    ) {
        this.vertices = vertices
        this.edges = edges
        this.feedbackConnections = match(feedbacks) {
            case None => HashSet<EdgeConnection<V, G>>()
            case Some(ecs) => ecs
        }
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
    public func GetVertices() : HashSet<Vertex<V, G>> {
        this.vertices
    }
    public func ContainsVertex(v : Vertex<V, G>) : Bool {
        this.vertices.contains(v)
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
    /**
     * Create a new vertex of a given width and add it to this graph.
     *
     * @param width
     * @return The new vertex
     */
    public func AddNewVertex(width : Int64, name!: Option<String> = None) : Vertex<V, G> {
        Vertex(width, this)
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
        AssertEmpty(v.GetInterfacedInputs())
        AssertEmpty(v.GetInterfacedOutputs())
        this.vertices.remove(v)
        this.RemoveVertexFromHypergraphData(v)
    }
    func AddVertexToTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        v : Vertex<V, G>)
    : Unit {
        traversalElements.put(VERTEX(v))
    }
    public func AddVertexToTraversalElements(
        direction : TraversalDirection, v : Vertex<V, G>
    ) : Unit {
        match(direction) {
            case LEFT_TO_RIGHT =>
                this.AddVertexToLeftmostTraversalElements(v)
            case RIGHT_TO_LEFT =>
                this.AddVertexToRightmostTraversalElements(v)
            case BOTH_DIRECTIONS =>
                this.AddVertexToLeftmostTraversalElements(v)
                this.AddVertexToRightmostTraversalElements(v)
        }
    }
    public func AddVertexToLeftmostTraversalElements(v : Vertex<V, G>) : Unit {
        AddVertexToTraversalElements(leftmostTraversalElements, v)
    }
    public func AddVertexToRightmostTraversalElements(v : Vertex<V, G>) : Unit {
        AddVertexToTraversalElements(rightmostTraversalElements, v)
    }
    func AddVertexToHypergraphData(v : Vertex<V, G>) : Unit {
        if(v.GetOutEdges().size == 0) {
            rightmostTraversalElements.put(VERTEX(v))
        }
    }
    func RemoveVertexFromTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        v : Vertex<V, G>
    ) : Unit {
        traversalElements.remove(VERTEX(v))
    }
    public func RemoveVertexFromLeftmostTraversalElements(
        v : Vertex<V, G>
    ) : Unit {
        RemoveVertexFromTraversalElements(
            this.leftmostTraversalElements, v
        )
    }
    public func RemoveVertexFromRightmostTraversalElements(v : Vertex<V, G>) : Unit {
        RemoveVertexFromTraversalElements(
            this.rightmostTraversalElements, v
        )
    }
    public func RemoveVertexFromTraversalElements(
        direction : TraversalDirection, v : Vertex<V, G>
    ) : Unit {
        match(direction) {
            case LEFT_TO_RIGHT =>
                this.RemoveVertexFromLeftmostTraversalElements(v)
            case RIGHT_TO_LEFT =>
                this.RemoveVertexFromRightmostTraversalElements(v)
            case BOTH_DIRECTIONS =>
                this.RemoveVertexFromLeftmostTraversalElements(v)
                this.RemoveVertexFromRightmostTraversalElements(v)
        }
    }
    func RemoveVertexFromHypergraphData(v : Vertex<V, G>) : Unit {
        this.RemoveVertexFromLeftmostTraversalElements(v)
        this.RemoveVertexFromRightmostTraversalElements(v)
    }
    public func GetEdges() : HashSet<Edge<V, G>> {
        this.edges
    }
    public func ContainsEdge(e : Edge<V, G>) : Bool {
        this.edges.contains(e)
    }
    public func ContainsElement(elem : TraversalElement<V, G>) : Bool {
        match(elem) {
            case EDGE(e) => this.ContainsEdge(e)
            case VERTEX(v) => this.ContainsVertex(v)
        }
    }
    public func AddEdge(e : Edge<V, G>) : Unit {
        this.edges.put(e)
        e.SetOwner(this)
        AddEdgeToHypergraphData(e)
        for(v in e.GetSources()) {
            this.AddVertex(v)
        }
        for(v in e.GetTargets()) {
            this.AddVertex(v)
        }
    }
    public func AddEdges(es : Iterable<Edge<V, G>>) : Unit {
        for (e in es) {
            this.AddEdge(e)
        }
    }
    /**
     * Create a new edge and add it to this graph.
     *
     * @param label
     * @param sources
     * @param targets
     * @param subgraph
     * @return The new edge
     */
    public func AddNewEdge(
        label : Label<V, G>,
        sources : Array<Vertex<V, G>>,
        targets : Array<Vertex<V, G>>,
        subgraph : Option<InterfacedHypergraph<V, G>>
    ) : Edge<V, G> {
        Edge(label, sources, targets, subgraph, this)
    }
    func AddEdgeToTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>,
        e : Edge<V, G>
    ) : Unit {
        traversalElements.put(EDGE(e))
    }
    public func AddEdgeToLeftmostTraversalElements(
        e : Edge<V, G>
    ) : Unit {
        this.AddEdgeToTraversalElements(this.leftmostTraversalElements, e)
    }
    public func AddEdgeToRightmostTraversalElements(
        e : Edge<V, G>
    ) : Unit {
        this.AddEdgeToTraversalElements(this.rightmostTraversalElements, e)
    }
    public func AddEdgeToTraversalElements(
        direction : TraversalDirection, e : Edge<V, G>
    ) : Unit {
        match(direction) {
            case LEFT_TO_RIGHT =>
                this.AddEdgeToLeftmostTraversalElements(e)
            case RIGHT_TO_LEFT =>
                this.AddEdgeToRightmostTraversalElements(e)
            case BOTH_DIRECTIONS =>
                this.AddEdgeToLeftmostTraversalElements(e)
                this.AddEdgeToRightmostTraversalElements(e)
        }
    }
    func AddEdgeToHypergraphData(e : Edge<V, G>) : Unit {
        // We keep track of edges with no sources so that we can
        // start traversing the graph from there later
        if(e.GetArity() == 0) {
            this.AddEdgeToTraversalElements(leftmostTraversalElements, e)
        }
        if(e.GetCoarity() == 0) {
            this.AddEdgeToTraversalElements(rightmostTraversalElements, e)
        }
        // We keep track of delay and value edges since these represent
        // sequential components
        match(e.GetLabel()){
            case DELAY(_) => this.delayEdges.put(e)
            case VALUE(v) =>
                if(v == V.GetDisconnected()) {
                    this.disconnectedEdges.put(e)
                } else {
                    this.valueEdges.put(e)
                }
            case SIGNAL(s) =>
                if(s.IsAll(V.GetDisconnected())) {
                    this.disconnectedEdges.put(e)
                } else {
                    this.valueEdges.put(e)
                }
            case _ =>
                match(e.GetSubgraph()){
                    case Some(g) =>
                        if(g.IsCombinational()) {
                            this.combinationalEdges.put(e)
                        } else {
                            this.sequentialEdges.put(e)
                        }
                    case None => this.combinationalEdges.put(e)
                }
        }
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
    func RemoveEdgeFromTraversalElements(
        traversalElements : HashSet<TraversalElement<V, G>>, e : Edge<V, G>
    ) : Unit {
        traversalElements.remove(EDGE(e))
    }
    public func RemoveEdgeFromLeftmostTraversalElements(e : Edge<V, G>) : Unit {
        RemoveEdgeFromTraversalElements(leftmostTraversalElements, e)
    }
    public func RemoveEdgeFromRightmostTraversalElements(e : Edge<V, G>) : Unit {
        RemoveEdgeFromTraversalElements(rightmostTraversalElements, e)
    }
    func RemoveEdgeFromTraversalElements(
        direction : TraversalDirection, e : Edge<V, G>
    ) : Unit {
        match(direction) {
            case LEFT_TO_RIGHT =>
                this.RemoveEdgeFromLeftmostTraversalElements(e)
            case RIGHT_TO_LEFT =>
                this.RemoveEdgeFromRightmostTraversalElements(e)
            case BOTH_DIRECTIONS =>
                this.RemoveEdgeFromLeftmostTraversalElements(e)
                this.RemoveEdgeFromRightmostTraversalElements(e)
        }
    }
    func RemoveEdgeFromHypergraphData(e : Edge<V, G>) : Unit {
        this.RemoveEdgeFromLeftmostTraversalElements(e)
        this.RemoveEdgeFromRightmostTraversalElements(e)
        this.delayEdges.remove(e)
        this.valueEdges.remove(e)
        this.disconnectedEdges.remove(e)
        this.sequentialEdges.remove(e)
        this.feedbackConnections.removeIf(
            { ec : EdgeConnection<V, G> => ec.GetEdge() == e}
        )
        this.combinationalEdges.remove(e)
    }
    public func GetDelayEdges() : HashSet<Edge<V, G>> {
        this.delayEdges
    }
    public func GetValueEdges() : HashSet<Edge<V, G>> {
        this.valueEdges
    }
    public func GetDisconnectedEdges() : HashSet<Edge<V, G>> {
        this.disconnectedEdges
    }
    public func GetFeedbackConnections() : HashSet<EdgeConnection<V, G>> {
        this.feedbackConnections
    }
    public func GetSequentialEdges() : HashSet<Edge<V, G>> {
        this.sequentialEdges
    }
    public func GetLeftmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.leftmostTraversalElements
    }
    public func GetRightmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.rightmostTraversalElements
    }
    public func IsCombinational() : Bool {
        this.delayEdges.size == 0 &&
            this.valueEdges.size == 0 &&
            this.feedbackConnections.size == 0 &&
            this.sequentialEdges.size == 0
    }
    public func AddInterfacedOwner(f : InterfacedHypergraph<V, G>) : Unit {
        this.interfacedOwners.put(f)
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
    /**
     * Create a brand new hypergraph with the same connectivity as the
     * original but with new vertices and edges
     * @return A tuple (hypergraph, vertex map, edge map) where the two hashmaps
     * relate the original versions of vertices/edges with the new copies
     */
    public func Clone() : (
        Hypergraph<V, G>,
        HashMap<Vertex<V, G>, Vertex<V, G>>,
        HashMap<Edge<V, G>, Edge<V, G>>
    ) {
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
        for(ec in this.feedbackConnections) {
            let newEdge = unsafeGet(edgeMap, ec.GetEdge())
            newHypergraph.AddFeedback(newEdge, ec.GetIndex())
        }
        (newHypergraph, vertexMap, edgeMap)
    }
    public func AddFeedback(e : Edge<V, G>, i : Int64) : Unit {
        this.feedbackConnections.put(EdgeConnection(e, i, SOURCE))
    }
    public func AddFeedback(ec : EdgeConnection<V, G>) : Unit {
        this.feedbackConnections.put(ec)
    }
    public func AddFeedback(v : Vertex<V, G>) : Unit {
        for(ec in v.GetOutEdges()) {
            this.AddFeedback(ec)
        }
    }
    public func IsFeedback(ec : EdgeConnection<V, G>) : Bool {
        this.feedbackConnections.contains(ec)
    }
    public func IsFeedback(e : Edge<V, G>, i : Int64) : Bool {
        this.feedbackConnections.contains(
            EdgeConnection(e, i, SOURCE)
        )
    }
    public func RemoveFeedback(
        e : Edge<V, G>, i : Int64
    ) : Unit {
        this.RemoveFeedback(EdgeConnection(e, i, SOURCE))
    }
    public func RemoveFeedback(ec : EdgeConnection<V, G>) : Unit {
        this.feedbackConnections.remove(ec)
    }
    public func RemoveFeedback(
        ecs : HashSet<EdgeConnection<V, G>>
    ) : Unit {
        this.feedbackConnections.removeAll(ecs)
    }
    public func RemoveAllFeedback() : Unit {
        this.feedbackConnections.clear()
    }
    public func RemoveSubgraphElements(f : InterfacedHypergraph<V, G>) : Unit {
        for(v in f.GetVertices()){
            this.RemoveVertex(v)
        }
        for(e in f.GetEdges()){
            this.RemoveEdge(e)
        }
    }
    /**
     * Given arrays of input and output tentacle origins, create a new
     * edge containing the subgraph spanned by these inputs and outputs.
     *
     * @param inputs
     * @param outputs
     * @param label
     * @return (new subgraph, new edge)
     */
    public func CollapseSubgraph(
        inputs : Array<TentacleOrigin<V, G>>,
        outputs : Array<TentacleOrigin<V, G>>,
        label : Label<V, G>
    ) : (InterfacedHypergraph<V, G>, Edge<V, G>) {
        /**
         * Slice a vertex referred to by a particular tentacle origin based on
         * whether it is a source or target.
         *
         * @param to The tentacle origin
         * @param vt The vertex type
         * @return (left vertex, right vertex)
         */
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
        let childInputs = snds(slicedInputs)
        let childOutputs = fsts(slicedOutputs)
        let parentInputs = fsts(slicedInputs)
        let parentOutputs = snds(slicedOutputs)
        let subgraphVertices = HashSet<Vertex<V, G>>()
        let subgraphEdges = HashSet<Edge<V, G>>()
        let subgraphFeedbacks = HashSet<EdgeConnection<V, G>>()
        let actionAtVertex = { v : Vertex<V, G> => subgraphVertices.put(v); () }
        let actionAtEdge = { e : Edge<V, G> =>
            subgraphEdges.put(e)
            for(i in 0..e.GetArity()) {
                if(this.IsFeedback(e, i)) {
                    subgraphFeedbacks.put(EdgeConnection(e, i, SOURCE))
                }
            }
        }
        func TraverseGraphFromEnd(starting : Array<Vertex<V, G>>) : Unit {
            let startingSet = HashSet<TraversalElement<V, G>>()
            for(v in starting) {
                startingSet.put(VERTEX(v))
            }
            Traverse(
                startingSet, BOTH_DIRECTIONS,
                actionAtVertex: actionAtVertex, actionAtEdge: actionAtEdge
            )
        }
        TraverseGraphFromEnd(childInputs)
        TraverseGraphFromEnd(childOutputs)
        let newSubgraph = Hypergraph<V, G>(
            subgraphVertices, subgraphEdges, feedbacks: subgraphFeedbacks
        )
        let interfacedSubgraph = InterfacedHypergraph(
            newSubgraph, map({ v => InterfaceVertex(v) }, childInputs),
            map({ v => InterfaceVertex(v) }, childOutputs), label
        )
        let newEdge = this.AddNewEdge(
            label, parentInputs, parentOutputs, Some(interfacedSubgraph)
        )
        (interfacedSubgraph, newEdge)
    }
    /**
     * Given arrays of input and output tentacle origins, create a new
     * edge containing the subgraph spanned by these inputs and outputs,
     * labelled by a COMPOSITE label with a given string.
     *
     * @param inputs
     * @param outputs
     * @param name
     * @return (new subgraph, new edge)
     */
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
    /**
     * Merge another hypergraph into this one.
     *
     * @param f The other hypergraph
     */
    public func MergeHypergraphs(f : Hypergraph<V, G>) : Unit {
        if(this != f) {
            this.feedbackConnections.putAll(f.GetFeedbackConnections())
            for(e in HashSet(f.GetEdges())) {
                this.AddEdge(e)
            }
            for(v in HashSet(f.GetVertices())){
                this.AddVertex(v)
            }
        }
    }
    /**
     * Given another graph element, merge its owner into this one.
     *
     * @param b The other graph element
     */
    public func MergeHypergraphs(b : HasGraph<V, G>) : Unit {
        this.MergeHypergraphs(b.GetGraph())
    }
}
/**
 * Interface for elements belonging to a graph
 */
public interface HasGraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    /**
     * @return The graph that owns this element
     */
    func GetGraph() : Hypergraph<V, G>
}
/**
 * Given two graph elements, merge the latter's owner into the former.
 *
 * @param a
 * @param b
 * @return The owner of both elements after the merge
 */
public func MergeHypergraphs<V, G, T, U>(a : T, b : U) : Hypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
            T <: HasGraph<V, G>, U <: HasGraph<V, G>
{
    let primary = a.GetGraph()
    primary.MergeHypergraphs(b)
    primary
}
/**
 * Given an array of graph elements, merge their owners into one graph.
 *
 * @param elems
 * @param initial An optional base hypergraph to merge everything into. If not
                    provided the first element in the array will be used.
 * @return The owner of all the elements, or None if the array is empty.
 */
public func MergeHypergraphs<V, G, T>(
    elems : Array<T>,
    initial!: Option<Hypergraph<V, G>> = None
) : Option<Hypergraph<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: HasGraph<V, G>
{
    if(elems.size == 0) {
        initial
    } else if(elems.size == 1) {
        let actualInitial = match(initial) {
            case Some(f) =>
                f.MergeHypergraphs(elems[0])
                f
            case None    =>
                elems[0].GetGraph()
        }
        Some(actualInitial)
    } else {
        let (actualInitial, startIndex) = match(initial) {
            case Some(f) => (f, 0)
            case None    => (elems[0].GetGraph(), 1)
        }
        Some(
            fold_left<T, Hypergraph<V, G>>(
                { acc, cur =>
                    acc.MergeHypergraphs(cur)
                    acc
                },
                actualInitial,
                elems,
                start: startIndex,
            )
        )
    }
}