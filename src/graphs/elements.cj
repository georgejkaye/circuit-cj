package graphs 

from std import collection.{ArrayList,HashMap}

import syntax.*

public interface Ownable<T> {
    func GetOwner() : Option<T> 
    func SetOwner(t : T) : Unit
    func RemoveOwner() : Unit
}

public abstract class Element <: Identifiable & Ownable<Hypergraph> & ToString & Hashable {
    let id : Identifiable
    var owner : Option<Hypergraph> = None
    public init() {
        this.id = Identifier()
    }
    public func GetId() : Int64 {
        this.id.GetId()
    }
    public func GetOwner() {
        this.owner
    }
    public open func SetOwner(h : Hypergraph) {
        this.owner = Some(h)
    }
    public open func RemoveOwner() {
        this.owner = Option<Hypergraph>.None
    }
    public func RemoveAndSetOwner(f : Hypergraph) {
        RemoveOwner()
        SetOwner(f)
    }
    public func hashCode() : Int64 {
        this.GetId()
    }
}

public class Vertex <: Element & Equatable<Vertex> {
    let width : Int64
    var inEdges : ArrayList<(Edge , Int64)> = ArrayList()
    var outEdges : ArrayList<(Edge , Int64)> = ArrayList()
    var feedback : Int64 = 0
    public init(width: Int64){         
        this.width = width    
        this.owner = Some(Hypergraph(HashSet<Vertex>([this]), HashSet<Edge>()))
    }
    public init() {
        this(1)
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetInEdges() : ArrayList<(Edge, Int64)> {
        this.inEdges
    }
    public func GetOutEdges() : ArrayList<(Edge, Int64)> {
        this.outEdges
    }
    public func AddInEdge(e : Edge, i : Int64) : Unit {
        inEdges.add((e, i))
    }
    public func AddAllInEdges(es : ArrayList<(Edge, Int64)>) {
        inEdges.addAll(es)
    }
    public func AddOutEdge(e : Edge, i : Int64) : Unit {
        outEdges.add((e, i))
    }
    public func AddAllOutEdges(es : ArrayList<(Edge, Int64)>) {
        outEdges.addAll(es)
    }
    func RemoveAllInEdge(edge : Edge) : Unit {
        inEdges.removeIf({e => e[0] == edge})
    }
    func RemoveAllOutEdge(edge : Edge) : Unit {
        outEdges.removeIf({e => e[0] == edge})
    }
    func RemoveAllEdge(edge : Edge) : Unit {
        RemoveAllInEdge(edge)
        RemoveAllOutEdge(edge)
    }
    func RemoveInEdge(edge : Edge, i : Int64) : Unit {
        inEdges.removeIf({e => e == (edge, i)})
    }
    func RemoveOutEdge(edge : Edge, i : Int64) : Unit {
        outEdges.removeIf({e => e == (edge, i)})
    }
    func IncrementFeedback() : Unit {
        this.feedback++
    }
    func DecrementFeedback() : Unit {
        this.feedback--
    }
    public func toString() : String {
        "v${this.GetId()}"
    }
    public operator func ==(right: Vertex) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Vertex) : Bool {
        this.GetId() != right.GetId()
    }
}

public interface ContainsVertex {
    func GetVertex() : Vertex
}

extend Int64 <: ContainsVertex {
    public func GetVertex() : Vertex {
        Vertex(this)
    }
}

extend Port <: ContainsVertex {
    public func GetVertex() : Vertex {
        Vertex(this.width)
    }
}

func CheckLabelCompatibility<T>(
    spec : Specifiable,
    inputs: Array<T>,
    outputs: Array<T>,
    fn : (Port, T) -> Bool
) : Unit where T <: ToString {
    func CheckCompatibility(desired : Array<Port>, actual : Array<T>) : Bool {
        if (desired.size() != actual.size()) {
            return false
        }
        for (i in 0..actual.size()) {
            if (!fn(desired[i], actual[i])){
                return false
            }
        }
        return true
    }
    let inputCheck = CheckCompatibility(spec.GetInputPorts(), inputs)
    let outputCheck = CheckCompatibility(spec.GetOutputPorts(), outputs)

    if (!inputCheck || !outputCheck) {
        throw IncompatibleLabelException("CheckLabelCompatibility", spec, inputs, outputs)
    }
}
public func CheckLabelCompatibility(spec : Specifiable, inputs: Array<Vertex>, outputs: Array<Vertex>) : Unit {
    CheckLabelCompatibility(
        spec,
        inputs,
        outputs,
        { p : Port, v : Vertex => p.width == v.GetWidth() }
    )
}
public func CheckLabelCompatibility(spec : Specifiable, inputs: Array<Int64>, outputs: Array<Int64>) : Unit {
    CheckLabelCompatibility(
        spec,
        inputs,
        outputs,
        { p : Port, i : Int64 => p.width == i }
    )
}

public class Edge <: Element & Specifiable & Equatable<Edge> {
    public Edge(
        let label: Label,
        let sources : Array<Vertex>,
        let targets : Array<Vertex>,
        let subgraph : Option<InterfacedHypergraph>
    ){
        CheckLabelCompatibility(
            label,
            map({v : Vertex => v.GetWidth()}, sources),
            map({v : Vertex => v.GetWidth() }, targets)
        )
        let graph = CombineGraphs(sources)
        graph.AddEdge(this)
        ForEachSource({ v : Vertex, i : Int64 => v.AddOutEdge(this, i)})
        ForEachTarget({ v : Vertex, i : Int64 => v.AddInEdge(this, i)})
    }
    public func GetLabel() : Label {
        this.label
    }
    public func GetSubgraph() : Option<InterfacedHypergraph> {
        this.subgraph
    }
    func ForEachVertex(array : Array<Vertex>, f : (Vertex, Int64) -> Unit) : Unit {
        for (i in 0..array.size()) {
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
    public override func SetOwner(f : Hypergraph) : Unit {
        match(this.owner) {
            case Some(o) => super.SetOwner(f)
            case None => 
                this.owner = f
                ForEachSourceAndTarget({ v, i => v.SetOwner(f)} )
        }
    }
    public override func RemoveOwner() : Unit {
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
            {v => v.AddInEdge(this, i)}
        )
    }
    public func GetSource(i : Int64) : Vertex {
        this.sources[i]
    }
    public func GetSources() : Array<Vertex> {
        this.sources
    }
    public func GetSourcePorts() : Int64 {
        this.sources.size()
    }
    public func GetTarget(i : Int64) : Vertex {
        this.targets[i]
    }
    public func GetTargets() : Array<Vertex> {
        this.targets
    }
    public func GetTargetPorts() : Int64 {
        this.targets.size()
    }
    public func toString() : String {
        this.GetName()
    }
    public func GetName() : String {
        "e${this.GetId()}"
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
}