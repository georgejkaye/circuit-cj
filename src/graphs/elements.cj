package graphs 

from std import collection.{ArrayList,HashMap}

import syntax.*

public interface Ownable<T> {
    func GetOwner() : Option<T> 
    func SetOwner(t : T) : Unit
    func RemoveOwner() : Unit
}

public abstract class Element <: Identifiable & Ownable<Hypergraph> & ToString & Hashable {
    let atom : Atom
    var owner : Option<Hypergraph> = None
    public init(owner : Option<Hypergraph>) {
        this.atom = Atom(Option<Identifier>.None)
        this.owner = owner
    }
    public func GetId() : Int64 {
        this.atom.GetId()
    }
    public func GetGlobalId() : Int64 {
        this.atom.GetGlobalId()
    }
    public func GetOwner() {
        this.owner
    }
    public open func SetOwner(h : Hypergraph) {
        match (this.owner) {
            case None => this.owner = Some(h)
            case Some(o) => throw AlreadyOwnedException("SetOwner", this, o, h)
        }
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
    public init(width: Int64, owner: Option<Hypergraph>){
        super(owner)            
        this.width = width
    }
    public init(width: Int64) {
        this(width, Option<Hypergraph>.None)
    }
    public init() {
        this(1)
    }
    public func GetWidth() : Int64 {
        this.width
    }
    func GetInEdges() : ArrayList<(Edge, Int64)> {
        this.inEdges
    }
    func GetOutEdges() : ArrayList<(Edge, Int64)> {
        this.outEdges
    }
    func AddInEdge(e : Edge, i : Int64) : Unit {
        inEdges.add((e, i))
    }
    func AddOutEdge(e : Edge, i : Int64) : Unit {
        outEdges.add((e, i))
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

public func CheckLabelCompatibility(label : Label, inputs: Array<Int64>, outputs: Array<Int64>) : Unit{
    func CheckCompatibility(desired : Array<Int64>, actual : Array<Int64>) : Bool {
        if (desired.size() != actual.size()) {
            return false
        }
        for (i in 0..actual.size()) {
            if (desired[i] != actual[i]){
                return false
            }
        }
        return true
    }
    let inputCheck = CheckCompatibility(label.GetInputPorts(), inputs)
    let outputCheck = CheckCompatibility(label.GetOutputPorts(), outputs)

    if (!inputCheck || !outputCheck) {
        throw IncompatibleLabelException("CheckLabelCompatibility", label, inputs, outputs)
    }
}

public class Edge <: Element & Equatable<Edge> {
    let label : Label
    let sources : Array<Vertex>
    let targets : Array<Vertex>
    public init(label: Label, sources : Array<Vertex>, targets : Array<Int64>){
        super(Option<Hypergraph>.None)
        CheckLabelCompatibility(label, map({v : Vertex => v.GetWidth()}, sources), targets)
        this.label = label
        this.sources = sources
        this.targets = map({ i : Int64 => Vertex(i) }, targets)
        let graph = CombineGraphs(sources)
        graph.AddEdge(this)
    }
    public func GetLabel() : Label {
        this.label
    }
    public func ForEachSourceAndTarget(f : (Vertex) -> Unit) : Unit {
        func ForEachVertex(array : Array<Vertex>, f : (Vertex) -> Unit) : Unit {
            for (v in array) {
                    f(v)
            }
        }
        ForEachVertex(this.sources, f)
        ForEachVertex(this.targets, f)
    }
    public override func SetOwner(f : Hypergraph) : Unit {
        match(this.owner) {
            case Some(o) => super.SetOwner(f)
            case None => 
                this.owner = f
                ForEachSourceAndTarget({ v => v.SetOwner(f)} )
        }
    }
    public override func RemoveOwner() : Unit {
        this.owner = Option<Hypergraph>.None
        ForEachSourceAndTarget({ v => v.RemoveOwner() })
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
        "e${this.GetId()}"
    }
    public operator func ==(right: Edge) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Edge) : Bool {
        this.GetId() != right.GetId()
    }
}