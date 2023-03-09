/**
 * graphs/edge.cj
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
 * @param T The type of elements in the input array, implements ToString, HasWidth
 * @param U The type of elements in the output array, implements ToString, HasWidth
 * @param spec The specification to check against
 * @param inputs The input array to check
 * @param outputs The output array to check
 */
func CheckSpecCompatibility<V, G>(
    spec : Specifiable<V>,
    inputs: Array<Tentacle<V, G>>,
    outputs: Array<Tentacle<V, G>>
) : Unit
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    func CheckArrayCompatibility(
        desired : Array<Port>,
        actual : Array<Tentacle<V, G>>
    ) : Unit {
        AssertArrayElementsHaveParameters<Tentacle<V, G>, Port, Int64>(
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
public interface HasTentacle<V, G> <: ContainsVertex<V, G>
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    func IsFeedback() : Bool
    func IsDelay() : Bool
}
public struct Tentacle<V, G>
    <: ToString & HasWidth & HasTentacle<V, G> & Ownable<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public Tentacle(
        public let vertex : Vertex<V, G>,
        public let feedback : Bool,
        public let delay : Bool
    ) {}
    public func toString() : String {
        let extraDetails = if(feedback && delay) {
            " (fb/d)"
        } else if(feedback) {
            " (fb)"
        } else if(delay) {
            " (d)"
        } else {
            ""
        }
        "${vertex}${extraDetails}"
    }
    public init(v : Vertex<V, G>) {
        this(v, false, false)
    }
    public func GetVertex() : Vertex<V, G> {
        this.vertex
    }
    public func GetWidth() : Int64 {
        this.vertex.GetWidth()
    }
    public func IsFeedback() : Bool {
        this.feedback
    }
    public func IsDelay() : Bool {
        this.delay
    }
    public func GetOwner() : Hypergraph<V, G> {
        this.GetVertex().GetOwner()
    }
}
public enum TentacleOrigin<V, G> where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G> {
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
 * (Hyper)edges represent the components in circuits, whether
 * they are primitives such as logic gates or larger subcircuits.
 * They can have multiple sources and target vertices, and also
 * an optional subgraph representing the internal construction.
 */
public class Edge<V, G>
    <: Specifiable<V> & Equatable<Edge<V, G>> & Identifiable &
        ToString & Hashable & Ownable<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let id : Int64 = GetNextId()
    let label : Label<V, G>
    let sources : Array<Tentacle<V, G>>
    let targets : Array<Tentacle<V, G>>
    let subgraph : Option<InterfacedHypergraph<V, G>>
    var owner : Hypergraph<V, G>
    public init(
        label: Label<V, G>,
        sources : Array<Tentacle<V, G>>,
        targets : Array<Tentacle<V, G>>,
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
    public init(
        label : Label<V, G>,
        sources : Array<Vertex<V, G>>,
        targets : Array<Vertex<V, G>>,
        subgraph : Option<InterfacedHypergraph<V, G>>,
        owner: Option<Hypergraph<V, G>>
    ){
        this(
            label,
            map(
                { v : Vertex<V, G> => Tentacle(v, false, label.IsDelay()) },
                sources
            ),
            map(
                { v : Vertex<V, G> => Tentacle(v, false, false) },
                targets
            ),
            subgraph,
            owner
        )
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
    func ForEachVertex(
        array : Array<Tentacle<V, G>>,
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
    public func ForEachSourceAndTarget(f : (Vertex<V, G>, Int64) -> Unit) : Unit {
        ForEachVertex(this.sources, f)
        ForEachVertex(this.targets, f)
    }
    public func GetOwner() : Hypergraph<V, G> {
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
    func SetVertex(
        i : Int64,
        newVertex : Vertex<V, G>,
        feedback : Bool,
        array : Array<Tentacle<V, G>>,
        vertexFn : (Vertex<V, G>, Vertex<V, G>) -> Unit
    ) : Unit {
            let tentacle = Tentacle(newVertex, feedback, false)
            let oldVertex = array[i].GetVertex()
            array[i] = tentacle
            vertexFn(oldVertex, newVertex)
            this.owner.AddVertex(newVertex)
    }
    public func SetSource(i : Int64, newVertex : Vertex<V, G>, feedback: Bool) : Unit {
        if(this.GetSourceVertex(i) != newVertex) {
            SetVertex(
                i,
                newVertex,
                feedback,
                this.sources,
                { oldVertex, newVertex =>
                    oldVertex.RemoveOutEdge(this, i)
                    newVertex.AddOutEdge(this, i)
                }
            )
        }
    }
    public func SetTarget(i : Int64, newVertex : Vertex<V, G>) : Unit {
        if(this.GetTargetVertex(i) != newVertex) {
            SetVertex(
                i,
                newVertex,
                false,
                this.targets,
                { oldVertex, newVertex =>
                    oldVertex.RemoveInEdge()
                    newVertex.SetInEdge(this, i)
                }
            )
        }
    }
    public func RemoveFeedback(i : Int64) : Unit {
        let t = this.GetSource(i)
        this.SetSource(i, t.vertex, false)
        // TODO move to hypbuilder
        this.owner.RemoveFeedbackConnection(EdgeConnection(this, i, SOURCE))
    }
    public func GetSource(i : Int64) : Tentacle<V, G> {
        this.sources[i]
    }
    public func GetSourceVertex(i : Int64) : Vertex<V, G> {
        this.GetSource(i).GetVertex()
    }
    public func GetSources() : Array<Tentacle<V, G>> {
        this.sources
    }
    public func GetArity() : Int64 {
        this.sources.size
    }
    public func GetTarget(i : Int64) : Tentacle<V, G> {
        this.targets[i]
    }
    public func GetTargetVertex(i : Int64) : Vertex<V, G> {
        this.GetTarget(i).GetVertex()
    }
    public func GetTargets() : Array<Tentacle<V, G>> {
        this.targets
    }
    public func GetCoarity() : Int64 {
        this.targets.size
    }
    public func BurstSubgraph() : (Array<Tentacle<V, G>>, Array<Tentacle<V, G>>) {
        match(this.GetSubgraph()){
            case None => (this.GetSources(), this.GetTargets())
            case Some(f) =>
                let mergeMap = HashMap<Vertex<V, G>, Vertex<V, G>>()
                this.GetOwner().RemoveEdge(this)
                for(v in f.GetInputs()) {
                    v.GetVertex().RemoveAsInput(f)
                }
                for(v in f.GetOutputs()) {
                    v.GetVertex().RemoveAsOutput(f)
                }
                this.GetOwner().IncludeHypergraph(f.GetGraph())
                func MergeInterfaces(
                    parentVertices : Array<Tentacle<V, G>>,
                    childVertices : Array<InterfaceVertex<V, G>>
                ) : Unit {
                    for(i in 0..parentVertices.size){
                        let parent = parentVertices[i]
                        let parentVertex = parentVertices[i].GetVertex()
                        let originalChildVertex = childVertices[i].GetVertex()
                        let actualChildVertex = match(mergeMap.get(originalChildVertex)){
                            case Some(v) => v
                            case None => originalChildVertex
                        }
                        parentVertex.MergeVertex(actualChildVertex, parent.feedback)
                        mergeMap.put(actualChildVertex, parentVertex)
                    }
                }
                for(t in this.GetSources()) {
                    t.GetVertex().RemoveOutEdge(this)
                }
                for(t in this.GetTargets()) {
                    t.GetVertex().RemoveInEdge(this)
                }
                MergeInterfaces(this.GetSources(), f.GetInputs())
                MergeInterfaces(this.GetTargets(), f.GetOutputs())
                func GetNewVertices(array : Array<Tentacle<V, G>>) : Array<Tentacle<V, G>> {
                    map(
                        { t =>
                            let oldVertex = t.GetVertex()
                            match(mergeMap.get(oldVertex)) {
                                case None => t
                                case Some(v) => Tentacle(v, t.feedback, false)
                            }
                        },
                        array
                    )
                }
                let newSources = GetNewVertices(this.GetSources())
                let newTargets = GetNewVertices(this.GetTargets())
                this.owner.IncludeHypergraph(f.GetGraph())
                (newSources, newTargets)
        }
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
    public func GetOutputPorts() : Array<Port> {
        this.label.GetOutputPorts()
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func NextEdgeLeft(i : Int64) : EdgeConnection<V, G> {
        this.GetSourceVertex(i).GetInEdge().getOrThrow()
    }
    public func NextEdgesRight(i : Int64) : HashSet<EdgeConnection<V, G>> {
        this.GetTargetVertex(i).GetOutEdges()
    }
    public func Clone(
        sources : Array<Tentacle<V, G>>,
        targets : Array<Tentacle<V, G>>,
        owner : Hypergraph<V, G>
    ) : Edge<V, G> {
        AssertArrayHasLength(sources, this.sources.size)
        AssertArrayHasLength(targets, this.targets.size)
        let clonedSubgraph = match(this.subgraph) {
            case None    => None<InterfacedHypergraph<V, G>>
            case Some(f) => Some(f.Clone())
        }
        Edge(
            this.GetLabel(),
            sources,
            targets,
            clonedSubgraph,
            owner
        )
    }
    public func Clone(
        owner : Hypergraph<V, G>
    ) : Edge<V, G> {
        this.Clone(
            map({ t => Tentacle(owner.AddNewVertex(t.GetWidth())) }, this.GetSources()),
            map({ t => Tentacle(owner.AddNewVertex(t.GetWidth())) }, this.GetTargets()),
            owner
        )
    }
}