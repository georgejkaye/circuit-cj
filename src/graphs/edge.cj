/**
 * graphs/edge.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

from std import collection.{ArrayList,HashMap}

import syntax.*
import assertions.*

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
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    func CheckArrayCompatibility(
        desired : Array<Port<V>>,
        actual : Array<Tentacle<V, G>>
    ) : Unit {
        AssertArrayElementsHaveParameters<Tentacle<V, G>, Port<V>, Int64>(
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
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    func IsFeedback() : Bool
    func IsDelay() : Bool
}
public struct Tentacle<V, G> <: ToString & HasWidth & HasTentacle<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
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
}
/**
 * (Hyper)edges represent the components in circuits, whether
 * they are primitives such as logic gates or larger subcircuits.
 * They can have multiple sources and target vertices, and also
 * an optional subgraph representing the internal construction.
 */
public class Edge<V, G> <: Specifiable<V> & Equatable<Edge<V, G>> & Identifiable & ToString & Hashable
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let id : Int64 = GetNextId()
    public Edge(
        let label: Label<V, G>,
        let sources : Array<Tentacle<V, G>>,
        let targets : Array<Tentacle<V, G>>,
        let subgraph : Option<InterfacedHypergraph<V, G>>,
        var owner : Hypergraph<V, G>
    ){
        // Vertices cannot be the targets of multiple edges
        AssertTargetsUnassigned(targets)
        // Check the ports of the label agree
        CheckSpecCompatibility(label, sources, targets)
        // All sources and targets need to belong to the same graph
        ForEachSource({ v, i =>
            v.AddOutEdge(this, i)
            this.owner.IncludeHypergraph(v.GetOwner())
        })
        ForEachTarget({ v, i =>
            v.SetInEdge(this, i)
            this.owner.IncludeHypergraph(v.GetOwner())
        })
        // As does does this edge itself
        this.owner.AddEdge(this)
    }
    public init(
        label : Label<V, G>,
        sources : Array<Tentacle<V, G>>,
        targets : Array<Tentacle<V, G>>,
        subgraph : Option<InterfacedHypergraph<V, G>>
    ){
        this(
            label,
            sources,
            targets,
            subgraph,
            Hypergraph()
        )
    }
    public init(
        label : Label<V, G>,
        sources : Array<Vertex<V, G>>,
        targets : Array<Vertex<V, G>>,
        subgraph : Option<InterfacedHypergraph<V, G>>,
        owner : Option<Hypergraph<V, G>>
    ){
        this(
            label,
            map({ v : Vertex<V, G> => Tentacle(v, false, label.IsDelay()) }, sources),
            map({ v : Vertex<V, G> => Tentacle(v, false, false) }, targets),
            subgraph,
            match(owner) {
                case None => Hypergraph<V, G>()
                case Some(f) => f
            }
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
            this.owner.RemoveEdge(this, false)
            this.owner = f
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
            this.owner.IncludeHypergraph(newVertex.GetOwner())
    }
    public func SetSource(i : Int64, newVertex : Vertex<V, G>, feedback: Bool) : Unit {
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
    public func SetTarget(i : Int64, newVertex : Vertex<V, G>) : Unit {
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
    public func RemoveFeedback(i : Int64) : Unit {
        let t = this.GetSource(i)
        this.SetSource(i, t.vertex, false)
        // TODO move to hypbuilder
        this.owner.RemoveFeedbackConnection(EdgeConnection(this, i, SOURCE))
    }
    public func GetSource(i : Int64) : Tentacle<V, G> {
        this.sources[i]
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
    public func GetTargets() : Array<Tentacle<V, G>> {
        this.targets
    }
    public func GetCoarity() : Int64 {
        this.targets.size
    }
    public func BurstSubgraph() : Unit {
        match(this.GetSubgraph()){
            case None => ()
            case Some(f) =>
                func MergeInterfaces(
                    parentVertices : Array<Tentacle<V, G>>,
                    childVertices : Array<InterfaceVertex<V, G>>
                ) : Unit {
                    for (i in 0..parentVertices.size) {
                        let parent = parentVertices[i]
                        let child = childVertices[i]
                        MergeVertices(parent.GetVertex(), child.GetVertex(), false)
                    }
                }
                this.owner.RemoveEdgeWithoutVertices(this)
                MergeInterfaces(this.GetSources(), f.GetInputs())
                MergeInterfaces(this.GetTargets(), f.GetOutputs())
                this.owner.IncludeHypergraph(f.GetGraph())
        }
    }
    public func toString() : String {
        "e${this.GetId()} (${label.GetName()})"
    }
    public operator func ==(right: Edge<V, G>) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Edge<V, G>) : Bool {
        this.GetId() != right.GetId()
    }
    public func GetInputPorts() : Array<Port<V>> {
        this.label.GetInputPorts()
    }
    public func GetOutputPorts() : Array<Port<V>> {
        this.label.GetOutputPorts()
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func SetFreshSource(i : Int64) : Vertex<V, G> {
        let vertex = Vertex<V, G>(this.GetSource(i).GetWidth())
        this.SetSource(i, vertex, this.GetSource(i).feedback)
        vertex
    }
    public func SetFreshTarget(i : Int64) : Vertex<V, G> {
        let vertex = Vertex<V, G>(this.GetTarget(i).GetWidth())
        this.SetTarget(i, vertex)
        vertex
    }
    public func NextEdgeLeft(i : Int64) : Edge<V, G> {
        this.GetSource(i).vertex.GetInEdge().getOrThrow().edge
    }
}