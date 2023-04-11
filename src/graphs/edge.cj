/**
 * graphs/edge.cj
 *
 * Definition of (hyper)edges.
 *
 * @author George Kaye
 * @since 0.2
 */
package graphs
from std import collection.{ArrayList,HashMap}
import syntax.*
/**
 * Check that two arrays, for inputs and outputs, agree
 * with the input and outputs defined in a given specification
 *
 * @param spec The specification to check against
 * @param inputs The input array to check
 * @param outputs The output array to check
 */
func CheckSpecCompatibility<V, G>(
    spec : Specifiable,
    inputs: Array<Vertex<V, G>>,
    outputs: Array<Vertex<V, G>>
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    func CheckArrayCompatibility(
        desired : Array<Port>,
        actual : Array<Vertex<V, G>>
    ) : Unit {
        AssertElementsHaveParameters<Vertex<V, G>, Port, Int64>(
            actual,
            desired,
            { t => t.GetWidth() },
            { p => p.GetWidth() },
            Width
        )
    }
    CheckArrayCompatibility(spec.GetInputPorts(), inputs)
    CheckArrayCompatibility(spec.GetOutputPorts(), outputs)
}
/**
 * (Hyper)edges represent the components in circuits, whether
 * they are primitives such as logic gates or larger subcircuits.
 * They can have multiple sources and target vertices, and also
 * an optional subgraph representing the internal construction.
 */
public class Edge<V, G>
    <: Specifiable & Identifiable<Edge<V, G>> &
        ToString & GraphElement<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let id : Int64 = GetNextId()
    let label : Label<V, G>
    let sources : Array<Vertex<V, G>>
    let targets : Array<Vertex<V, G>>
    let subgraph : Option<InterfacedHypergraph<V, G>>
    var owner : Hypergraph<V, G>
    public init(
        label: Label<V, G>,
        sources : Array<Vertex<V, G>>,
        targets : Array<Vertex<V, G>>,
        subgraph : Option<InterfacedHypergraph<V, G>>,
        owner : Option<Hypergraph<V, G>>
    ){
        // Vertices cannot be the targets of multiple edges
        AssertTargetsUnassigned(targets)
        // Check the ports of the label agree
        CheckSpecCompatibility(label, sources, targets)
        this.label = label
        this.sources = sources
        this.targets = targets
        this.subgraph = subgraph
        // Merge all the hypergraphs of the vertices into one
        // If we specified an owner for this edge as a constructor argument,
        // this is the 'base' owner the vertices are all merged into; otherwise
        // we use the result of the merge
        let sourceOwner = MergeHypergraphs(sources, initial: owner)
        let targetOwner = MergeHypergraphs(targets, initial: sourceOwner)
        this.owner = match(targetOwner) {
            case Some(f) => f
            case None => Hypergraph<V, G>()
        }
        // Add this edge as an out edge to the sources
        ForEachSource({ v, i =>
            v.AddOutEdge(this, i)
        })
        // Add this edge as an in edge to the sources
        ForEachTarget({ v, i =>
            v.SetInEdge(this, i)
        })
        // Add this edge to its new owner
        this.owner.AddEdge(this)
    }
    public func toString() : String {
        "e${this.GetId()} (${label.GetName()})"
    }
    public func toLongString() : String {
        "e${this.GetId()} (${label.GetName()}) ~ ${sources} ~ ${targets}"
    }
    public operator func ==(right: Edge<V, G>) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Edge<V, G>) : Bool {
        this.GetId() != right.GetId()
    }
    public func GetInputPorts() : Array<Port> {
        this.label.GetInputPorts()
    }
    public func GetArity() : Int64 {
        this.sources.size
    }
    public func GetOutputPorts() : Array<Port> {
        this.label.GetOutputPorts()
    }
    public func GetCoarity() : Int64 {
        this.targets.size
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetId() : Int64 {
        this.id
    }
    public func GetLabel() : Label<V, G> {
        this.label
    }
    public func GetSubgraph() : Option<InterfacedHypergraph<V, G>> {
        this.subgraph
    }
    public func HasSubgraph() : Bool {
        match(this.subgraph) {
            case None => false
            case Some(_) => true
        }
    }
    func ForEachVertex(
        array : Array<Vertex<V, G>>,
        f : (Vertex<V, G>, Int64) -> Unit
    ) : Unit {
        for (i in 0..array.size) {
            f(array[i].GetVertex(), i)
        }
    }
    public func ForEachSource(f : (Vertex<V, G>, Int64) -> Unit) : Unit {
        ForEachVertex(this.sources, f)
    }
    public func ForEachTarget(f : (Vertex<V, G>, Int64) -> Unit) : Unit {
        ForEachVertex(this.targets, f)
    }
    public func GetGraph() : Hypergraph<V, G> {
        this.owner
    }
    public func SetOwner(f : Hypergraph<V, G>) : Unit {
        if(this.owner != f){
            let oldOwner = this.owner
            this.owner = f
            oldOwner.RemoveEdge(this)
            // Need to move the sources and targets from the old owner to the
            // new owner: removing the edge from the graph also removes it
            // from the vertices' tentacles
            for(i in 0..this.GetArity()) {
                let v = this.GetSource(i).GetVertex()
                v.SetOwner(f)
                v.AddOutEdge(this, i)
            }
            for(i in 0..this.GetCoarity()) {
                let v = this.GetTarget(i).GetVertex()
                v.SetOwner(f)
                v.SetInEdge(this, i)
            }
        }
    }
    /**
     * Generic function for setting a vertex as the ith source or target.
     *
     * @param i
     * @param newVertex
     * @param array The array of sources or targets
     * @param vertexFn The function to apply to the old and new vertex
     */
    func SetVertex(
        i : Int64,
        newVertex : Vertex<V, G>,
        array : Array<Vertex<V, G>>,
        vertexFn : (Vertex<V, G>, Vertex<V, G>) -> Unit
    ) : Unit {
            let oldVertex = array[i]
            array[i] = newVertex
            vertexFn(oldVertex, newVertex)
            this.owner.AddVertex(newVertex)
    }
    /**
     * Set the ith source vertex.
     *
     * @param i
     * @param newVertex
     */
    public func SetSource(i : Int64, newVertex : Vertex<V, G>) : Unit {
        if(this.GetSource(i) != newVertex) {
            SetVertex(
                i, newVertex, this.sources,
                { oldVertex, newVertex =>
                    oldVertex.RemoveOutEdge(this, i)
                    newVertex.AddOutEdge(this, i)
                }
            )
        }
    }
    /**
     * Set the ith target vertex.
     *
     * @param i
     * @param newVertex
     */
    public func SetTarget(i : Int64, newVertex : Vertex<V, G>) : Unit {
        if(this.GetTarget(i) != newVertex) {
            SetVertex(
                i, newVertex, this.targets,
                { oldVertex, newVertex =>
                    oldVertex.RemoveInEdge()
                    newVertex.SetInEdge(this, i)
                }
            )
        }
    }
    public func GetSource(i : Int64) : Vertex<V, G> {
        this.sources[i]
    }
    public func GetSources() : Array<Vertex<V, G>> {
        this.sources
    }
    public func GetTarget(i : Int64) : Vertex<V, G> {
        this.targets[i]
    }
    public func GetTargets() : Array<Vertex<V, G>> {
        this.targets
    }
    /**
     * If this is an edge containing a subgraph, 'burst' the edge so that
     * the subgraph becomes part of the main graph and this edge is discarded.
     *
     * @return A pair of arrays showing the tentacles corresponding to the
     *           inputs and outputs of the graph respectively
     */
    public func BurstSubgraph() : (
        Array<Vertex<V, G>>, Array<Vertex<V, G>>
    ) {
        match(this.GetSubgraph()){
            // If there is no subgraph, we don't need to do anything
            case None => (this.GetSources(), this.GetTargets())
            // If there is a subgraph, we will burst it
            case Some(f) =>
                // This edge will not belong to the parent graph any more
                this.GetGraph().RemoveEdge(this)
                // Some of the targets may be merged by the interfaces so we
                // need to keep track of any merges that happen
                let mergeMap = HashMap<Vertex<V, G>, Vertex<V, G>>()
                // Remove each input from the inputs of the child graph
                for(v in f.GetInputs()) {
                    v.GetVertex().RemoveAsInput(f)
                }
                // Remove each input from the outputs of the child graph
                for(v in f.GetOutputs()) {
                    v.GetVertex().RemoveAsOutput(f)
                }
                // Add the elements of the subgraph to the parent graph
                this.GetGraph().MergeHypergraphs(f.GetGraph())
                /**
                 * Merge the interface vertices of a child graph with the
                 * sources or targets of a parent edge
                 *
                 * @param parentVertices The sources or targets of the edge
                 * @param childVertices The interface of the child graph
                 */
                func MergeInterfaces(
                    parentVertices : Array<Vertex<V, G>>,
                    childVertices : Array<InterfaceVertex<V, G>>
                ) : Unit {
                    for(i in 0..parentVertices.size){
                        let parent = parentVertices[i]
                        let parentVertex = parentVertices[i].GetVertex()
                        let originalChildVertex = childVertices[i].GetVertex()
                        let actualChildVertex =
                            match(mergeMap.get(originalChildVertex)){
                                case Some(v) => v
                                case None => originalChildVertex
                            }
                        let feedback =
                            this.GetGraph().IsFeedback(this, i)
                        parentVertex.MergeVertex(actualChildVertex, feedback)
                        mergeMap.put(actualChildVertex, parentVertex)
                    }
                }
                MergeInterfaces(this.GetSources(), f.GetInputs())
                MergeInterfaces(this.GetTargets(), f.GetOutputs())
                /**
                 * For an array of tentacles, get an array of the tentacles
                 * mapped by the merge map
                 *
                 * @param array The array of tentacles
                 */
                func GetNewVertices(
                    array : Array<Vertex<V, G>>
                ) : Array<Vertex<V, G>> {
                    map(
                        { oldVertex =>
                            match(mergeMap.get(oldVertex)) {
                                case None => oldVertex
                                case Some(v) => v
                            }
                        },
                        array
                    )
                }
                let newSources = GetNewVertices(this.GetSources())
                let newTargets = GetNewVertices(this.GetTargets())
                this.owner.MergeHypergraphs(f.GetGraph())
                (newSources, newTargets)
        }
    }
    /**
     * Get the edge that can be accessed from traversing across one vertex from
     * the ith source of this edge. Throws a NoneException if there is no such
     * edge.
     *
     * @param i
     * @return The edge connection accessible from the targets
     */
    public func NextEdgeLeft(i : Int64) : EdgeConnection<V, G> {
        this.GetSource(i).GetInEdge().getOrThrow()
    }
    /**
     * Get the edges that can be accessed from traversing across one vertex from
     * the ith target of this edge.
     *
     * @param i
     * @return The set of edge connections accessible from the targets
     */
    public func NextEdgesRight(i : Int64) : HashSet<EdgeConnection<V, G>> {
        this.GetTarget(i).GetOutEdges()
    }
    /**
     * Create a new edge belonging to a specified graph with the same properties
     * as this one, with given sources and targets.
     *
     * @param sources The sources the cloned edge will have
     * @param targets The targets the cloned edge will have
     * @param owne The owner of the cloned edge
     */
    public func Clone(
        sources : Array<Vertex<V, G>>,
        targets : Array<Vertex<V, G>>,
        owner : Hypergraph<V, G>
    ) : Edge<V, G> {
        AssertHasLength(sources, this.sources.size)
        AssertHasLength(targets, this.targets.size)
        let clonedSubgraph = match(this.subgraph) {
            case None    => None<InterfacedHypergraph<V, G>>
            case Some(f) => Some(f.Clone())
        }
        Edge(this.GetLabel(), sources, targets, clonedSubgraph, owner)
    }
    /**
     * Create a new edge belonging to a specified graph with the same properties
     * as this one, with new sources and targets
     *
     * @param owner The owner of the cloned edge
     * @return The new edge
     */
    public func Clone(
        owner : Hypergraph<V, G>
    ) : Edge<V, G> {
        this.Clone(
            map({ t => owner.AddNewVertex(t.GetWidth()) }, this.GetSources()),
            map({ t => owner.AddNewVertex(t.GetWidth()) }, this.GetTargets()),
            owner
        )
    }
}