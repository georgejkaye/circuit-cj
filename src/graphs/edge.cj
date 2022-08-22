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
func CheckSpecCompatibility<T,U>(
    spec : Specifiable,
    inputs: Array<T>,
    outputs: Array<U>
) : Unit where T <: ToString, U <: ToString, T <: HasWidth, U <: HasWidth {
    func CheckArrayCompatibility<T>(
        desired : Array<Port>,
        actual : Array<T>
    ) : Unit where T <: HasWidth, T <: ToString {
        AssertArrayElementsHaveParameters<T, Port, Int64>(
            actual,
            desired,
            { t : T => t.GetWidth() },
            { p : Port => p.GetWidth() },
            Width
        )
    }
    CheckArrayCompatibility<T>(spec.GetInputPorts(), inputs)
    CheckArrayCompatibility<U>(spec.GetOutputPorts(), outputs)
}

/**
 * (Hyper)edges represent the components in circuits, whether
 * they are primitives such as logic gates or larger subcircuits.
 * They can have multiple sources and target vertices, and also
 * an optional subgraph representing the internal construction.
 */
public class Edge <: Specifiable & Equatable<Edge> & Ownable<Hypergraph> & Identifiable & ToString & Hashable {
    let id : Int64 = GetNextId()
    var owner : Option<Hypergraph> = None
    public Edge(
        let label: Label,
        let sources : Array<Vertex>,
        let targets : Array<Vertex>,
        let subgraph : Option<InterfacedHypergraph>
    ){
        // Vertices cannot be the targets of multiple edges
        AssertTargetsUnassigned(targets)
        // Check the ports of the label agree
        CheckSpecCompatibility<Vertex, Vertex>(label, sources, targets)
        let graph = CombineGraphs<Vertex>(sources)
        graph.AddEdge(this)
        ForEachSource({ v : Vertex, i : Int64 => v.AddOutEdge(this, i)})
        ForEachTarget({ v : Vertex, i : Int64 => v.SetInEdge(this, i)})
    }
    public func GetId() : Int64 {
        this.id
    }
    public func GetLabel() : Label {
        this.label
    }
    public func GetSubgraph() : Option<InterfacedHypergraph> {
        this.subgraph
    }
    func ForEachVertex(array : Array<Vertex>, f : (Vertex, Int64) -> Unit) : Unit {
        for (i in 0..array.size) {
            f(array[i], i)
        }
    }
    public func ForEachSource(f : (Vertex, Int64) -> Unit) : Unit {
        ForEachVertex(this.sources, f)
    }
    public func ForEachTarget(f : (Vertex, Int64) -> Unit) : Unit {
        ForEachVertex(this.targets, f)
    }
    public func ForEachSourceAndTarget(f : (Vertex, Int64) -> Unit) : Unit {
        ForEachVertex(this.sources, f)
        ForEachVertex(this.targets, f)
    }
    public func GetOwner() : Option<Hypergraph> {
        this.owner
    }
    public func SetOwner(f : Hypergraph) : Unit {
        this.owner = f
        ForEachSourceAndTarget({ v, i => v.SetOwner(f)} )
    }
    public func RemoveOwner() : Unit {
        this.owner = Option<Hypergraph>.None
        ForEachSourceAndTarget({ v, i => v.RemoveOwner() })
    }
    func SetVertex(
        i : Int64,
        newVertex : Vertex,
        array : Array<Vertex>,
        vertexFn : (Vertex) -> Unit
    ) : Unit {
            array[i] = newVertex
            vertexFn(newVertex)
    }
    public func SetSource(i : Int64, newVertex : Vertex) : Unit {
        SetVertex(
            i,
            newVertex,
            this.sources,
            { v => v.AddOutEdge(this, i) }
        )
    }
    public func SetTarget(i : Int64, newVertex : Vertex) : Unit {
        SetVertex(
            i,
            newVertex,
            this.targets,
            {v => v.SetInEdge(this, i)}
        )
    }
    public func GetSource(i : Int64) : Vertex {
        this.sources[i]
    }
    public func GetSources() : Array<Vertex> {
        this.sources
    }
    public func GetNoSources() : Int64 {
        this.sources.size
    }
    public func GetTarget(i : Int64) : Vertex {
        this.targets[i]
    }
    public func GetTargets() : Array<Vertex> {
        this.targets
    }
    public func GetNoTargets() : Int64 {
        this.targets.size
    }
    public func BurstSubgraph() : Unit {
        let owner = AssertOwned(this)
        match(this.GetSubgraph()){
            case None => ()
            case Some(f) =>
                owner.RemoveEdge(this)
                func MergeInterfaces(
                    parentVertices : Array<Vertex>,
                    childVertices : Array<InterfaceVertex>
                ) : Unit {
                    for (i in 0..parentVertices.size) {
                        MergeVertices(parentVertices[i], childVertices[i].GetVertex())
                    }
                }
                MergeInterfaces(this.GetSources(), f.GetInputVertices())
                MergeInterfaces(this.GetTargets(), f.GetOutputVertices())
                owner.AddEdges(f.GetEdges())
    }
}
    public func toString() : String {
        "e${this.GetId()} (${label.GetName()})"
    }
    public operator func ==(right: Edge) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Edge) : Bool {
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
}