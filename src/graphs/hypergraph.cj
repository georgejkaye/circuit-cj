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
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
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
public struct SequentialData<V, G>
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
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
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let vertices = HashSet<Vertex<V, G>>()
    func PutVertices(ts : Array<Tentacle<V, G>>) : Unit {
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
public class Hypergraph<V, G> <: Identifiable & ToString & Equatable<Hypergraph<V, G>> & Hashable
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let id : Int64 = GetNextId()
    let name : String
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
    /*
     * Define hypergraph with set of vertices and set of edges
     *
     * @param vertices The set of vertices
     * @param edges The set of edges
     */
    public init (vertices : HashSet<Vertex<V, G>>, edges : HashSet<Edge<V, G>>){
        this.vertices = vertices
        this.edges = edges
        this.name = "h${this.id}"
        for (v in this.vertices) {
            v.SetOwner(this)
            this.AddVertexToHypergraphData(v)
        }
        for (e in this.edges) {
            e.SetOwner(this)
            this.AddEdgeToHypergraphData(e)
        }
    }
    /*
     * Define hypergraph with just a set of edges. The vertices
     * will be populated from the sources and targets of these edges
     *
     * @param edges The set of edges
     */
    public init (edges : HashSet<Edge<V, G>>){
        this(GetVerticesFromEdges(edges), edges)
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
        // We keep track of any tentacle that has been marked as a feedback loop
        for(i in 0..e.GetArity()) {
            let t = e.GetSource(i)
            if(t.feedback) {
                this.sequentialData.feedbackConnections.put(EdgeConnection(e, i, SOURCE))
            }
        }
    }
    public func GetLeftmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.leftmostTraversalElements
    }
    public func GetRightmostTraversalElements() : HashSet<TraversalElement<V, G>> {
        this.rightmostTraversalElements
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
        this.sequentialData.feedbackConnections.removeIf({ ec : EdgeConnection<V, G> => ec.GetEdge() == e})
        this.sequentialData.combinationalEdges.remove(e)
    }
    func RemoveVertexFromHypergraphData(v : Vertex<V, G>) : Unit {
        this.RemoveVertexFromLeftmostTraversalElements(v)
        this.RemoveVertexFromRightmostTraversalElements(v)
    }
    public func GetSequentialData() : SequentialData<V, G> {
        this.sequentialData
    }
    public func AddEdgeAndVertices(e : Edge<V, G>) : Unit {
        this.IncludeHypergraph(e.GetOwner())
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
    public func AddVertex(v : Vertex<V, G>) : Unit {
        this.vertices.put(v)
        v.SetOwner(this)
        this.AddVertexToHypergraphData(v)
    }
    public func RemoveVertex(v : Vertex<V, G>) : Unit {
        this.vertices.remove(v)
        this.RemoveVertexFromHypergraphData(v)
    }
    public func RemoveFeedbackConnection(ec : EdgeConnection<V, G>) : Unit {
        this.sequentialData.feedbackConnections.remove(ec)
    }
    func RemoveEdge(e : Edge<V, G>) {
        this.edges.remove(e)
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
            array : Array<Tentacle<V, G>>,
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
    public func ReplaceVertex(v : Vertex<V, G>, w : Vertex<V, G>) : Unit {
        this.vertices.remove(v)
        this.vertices.put(w)
    }
    public func IncludeHypergraph(f : Hypergraph<V, G>) : Unit {
        let newEdges = HashSet<Edge<V, G>>(f.GetEdges())
        let newVertices = HashSet<Vertex<V, G>>(f.GetVertices())
        for(e in newEdges) {
            this.AddEdge(e)
        }
        for(v in newVertices) {
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
                    array: Array<Tentacle<V, G>>
                ){
                    foldi_left(
                        { acc : String , cur : Tentacle<V, G>, i : Int64 =>
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
        let newVertices = HashSet<Vertex<V, G>>()
        let vertexMap = HashMap<Vertex<V, G>,Vertex<V, G>>()
        let newEdges = HashSet<Edge<V, G>>()
        let edgeMap = HashMap<Edge<V, G>, Edge<V, G>>()
        for (vertex in this.vertices) {
            let newVertex = Vertex<V, G>(vertex.GetWidth())
            newVertices.put(newVertex)
            vertexMap.put(vertex, newVertex)
        }
        for (edge in this.edges) {
            func CloneTentacles(vs : Array<Tentacle<V, G>>) : Array<Tentacle<V, G>> {
                map(
                    { t => Tentacle(unsafeGet(vertexMap, t.GetVertex()), t.feedback, t.delay) },
                    vs
                )
            }
            let newSources = CloneTentacles(edge.GetSources())
            let newTargets = CloneTentacles(edge.GetTargets())
            let newSubgraph = match(edge.GetSubgraph()){
                case None => None<InterfacedHypergraph<V, G>>
                case Some(g) => Some(g.Clone())
            }
            let newEdge = Edge(edge.GetLabel(), newSources, newTargets, newSubgraph, Hypergraph<V, G>())
            newEdges.put(newEdge)
            edgeMap.put(edge, newEdge)
        }
        (Hypergraph(newVertices, newEdges), vertexMap, edgeMap)
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
                    SliceTentacle(ec)
                case FROM_VERTEX(v) =>
                    let newVertex = Vertex<V, G>(v.GetWidth())
                    v.GetOwner().AddVertex(newVertex)
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
        let childInputs = map({ vs : (Vertex<V, G>, Vertex<V, G>) => vs[1] }, slicedInputs)
        let childOutputs = map({ vs : (Vertex<V, G>, Vertex<V, G>) => vs[0] }, slicedOutputs)
        let parentInputs = map({ vs : (Vertex<V, G>, Vertex<V, G>) => vs[0] },  slicedInputs)
        let parentOutputs = map({ vs : (Vertex<V, G>, Vertex<V, G>) => vs[1] }, slicedOutputs)
        let subgraph = Hypergraph<V, G>()
        let actionAtVertex = { v : Vertex<V, G> =>
            subgraph.AddVertex(v)
        }
        let actionAtEdge = { e : Edge<V, G> =>
            subgraph.AddEdge(e)
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
                actionAtVertex,
                { v, e => true },
                actionAtEdge,
                { e, v => true }
            )
        }
        TraverseGraphFromEnd(childInputs)
        TraverseGraphFromEnd(childOutputs)
        let interfacedSubgraph = InterfacedHypergraph(
            subgraph,
            map({ v => InterfaceVertex(v, "") }, childInputs),
            map({ v => InterfaceVertex(v, "") }, childOutputs),
            label
        )
        let newEdge = Edge<V, G>(
            label,
            parentInputs,
            parentOutputs,
            Some(interfacedSubgraph),
            Some(this)
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
                    map({ to => Port(to.GetWidth(), "") }, inputs),
                    map({ to => Port(to.GetWidth(), "") }, outputs)
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
public func EmptyGraph<V, G>() : Hypergraph<V, G>
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    Hypergraph(
        HashSet<Vertex<V, G>>(),
        HashSet<Edge<V, G>>()
    )
}
